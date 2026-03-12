package api

import (
	"database/sql"
	"encoding/json"
	"net/http"
)

type ExportAPI struct {
	DB *sql.DB
}

// GET /api/export
func (a *ExportAPI) Export(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	data := map[string]any{}

	// Helper to query table rows
	queryTable := func(name, query string, args ...any) {
		rows, err := a.DB.Query(query, args...)
		if err != nil {
			return
		}
		defer rows.Close()

		cols, _ := rows.Columns()
		var result []map[string]any
		for rows.Next() {
			values := make([]any, len(cols))
			ptrs := make([]any, len(cols))
			for i := range values {
				ptrs[i] = &values[i]
			}
			rows.Scan(ptrs...)
			row := map[string]any{}
			for i, col := range cols {
				v := values[i]
				if b, ok := v.([]byte); ok {
					row[col] = string(b)
				} else {
					row[col] = v
				}
			}
			result = append(result, row)
		}
		if result == nil {
			result = []map[string]any{}
		}
		data[name] = result
	}

	deptID := sess.DeptID
	queryTable("meta", "SELECT `key`, value FROM meta WHERE dept_id = ?", deptID)
	queryTable("users", "SELECT id, username, display_name, initials, role, active, rfid_hash, created_at, created_by, must_change_password, theme, age, birthdate, language_level, has_training, measure_start, motorik_level FROM users WHERE dept_id = ?", deptID)
	queryTable("machines", "SELECT id, label, position FROM machines WHERE dept_id = ?", deptID)
	queryTable("content_sections", "SELECT id, title, position, content_md, parent_id, updated_at FROM content_sections WHERE dept_id = ?", deptID)
	queryTable("learning_goals", "SELECT id, machine_id, phase, title, weight, position FROM learning_goals WHERE dept_id = ?", deptID)
	queryTable("evaluations", "SELECT id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at FROM evaluations WHERE dept_id = ?", deptID)
	queryTable("trainee_meta", "SELECT trainee_id, feedback, conclusion, next_steps FROM trainee_meta WHERE dept_id = ?", deptID)
	queryTable("attendance", "SELECT id, trainee_id, machine_id, date, hours FROM attendance WHERE dept_id = ?", deptID)
	queryTable("exam_questions", "SELECT id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at FROM exam_questions WHERE dept_id = ?", deptID)
	queryTable("exam_results", "SELECT id, trainee_id, score, total, passed, answers, started_at, finished_at FROM exam_results WHERE dept_id = ?", deptID)

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", "attachment; filename=schulungshub-export.json")
	json.NewEncoder(w).Encode(data)
}

