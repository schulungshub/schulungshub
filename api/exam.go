package api

import (
	"database/sql"
	"net/http"
	"strconv"
	"strings"
	"time"
)

type ExamAPI struct {
	DB *sql.DB
}

// GET /api/exam/questions
func (a *ExamAPI) QuestionsList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	rows, err := a.DB.Query(
		`SELECT q.id, q.section_id, q.machine_id, q.phase, q.type, q.question, q.options,
		        q.explanation, q.question_image, q.difficulty, q.created_by, q.created_at,
		        cs.title AS section_title
		 FROM exam_questions q
		 LEFT JOIN content_sections cs ON q.section_id = cs.id
		 WHERE q.dept_id = ? ORDER BY q.created_at DESC`, sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var questions []map[string]any
	for rows.Next() {
		var id, qType, question, options string
		var sectionID, machineID, phase, explanation, questionImage, sectionTitle sql.NullString
		var difficulty int
		var createdBy sql.NullInt64
		var createdAt sql.NullTime
		if err := rows.Scan(&id, &sectionID, &machineID, &phase, &qType, &question, &options,
			&explanation, &questionImage, &difficulty, &createdBy, &createdAt, &sectionTitle); err != nil {
			internalError(w, err)
			return
		}
		q := map[string]any{
			"id": id, "type": qType, "question": question, "options": options,
			"difficulty": difficulty, "section_id": nil, "machine_id": nil,
			"phase": "", "explanation": "", "question_image": "", "section_title": "",
			"created_by": nil, "created_at": "",
		}
		if sectionID.Valid { q["section_id"] = sectionID.String }
		if machineID.Valid { q["machine_id"] = machineID.String }
		if phase.Valid { q["phase"] = phase.String }
		if explanation.Valid { q["explanation"] = explanation.String }
		if questionImage.Valid { q["question_image"] = questionImage.String }
		if sectionTitle.Valid { q["section_title"] = sectionTitle.String }
		if createdBy.Valid { q["created_by"] = createdBy.Int64 }
		if createdAt.Valid { q["created_at"] = createdAt.Time.Format(tsFormat) }
		questions = append(questions, q)
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if questions == nil { questions = []map[string]any{} }
	writeJSON(w, questions)
}

// POST /api/exam/questions
func (a *ExamAPI) QuestionsCreate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		ID            string  `json:"id"`
		SectionID     *string `json:"section_id"`
		MachineID     *string `json:"machine_id"`
		Phase         string  `json:"phase"`
		Type          string  `json:"type"`
		Question      string  `json:"question"`
		Options       string  `json:"options"`
		Explanation   string  `json:"explanation"`
		QuestionImage string  `json:"question_image"`
		Difficulty    int     `json:"difficulty"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	_, err := a.DB.Exec(
		`INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question,
		                              options, explanation, question_image, difficulty, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		req.ID, sess.DeptID, req.SectionID, req.MachineID, req.Phase, req.Type, req.Question,
		req.Options, req.Explanation, req.QuestionImage, req.Difficulty, sess.UserID,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusCreated)
}

// PUT /api/exam/questions/:id
func (a *ExamAPI) QuestionsUpdate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/exam/questions/")
	var req map[string]any
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	allowed := map[string]bool{
		"type": true, "question": true, "options": true, "section_id": true,
		"machine_id": true, "phase": true, "difficulty": true, "explanation": true,
		"question_image": true,
	}
	var sets []string
	var args []any
	for k, v := range req {
		if !allowed[k] { continue }
		sets = append(sets, k+" = ?")
		args = append(args, v)
	}
	if len(sets) == 0 {
		http.Error(w, "no fields", http.StatusBadRequest)
		return
	}
	args = append(args, id, sess.DeptID)
	a.DB.Exec("UPDATE exam_questions SET "+strings.Join(sets, ", ")+" WHERE id = ? AND dept_id = ?", args...)
	w.WriteHeader(http.StatusNoContent)
}

// DELETE /api/exam/questions/:id
func (a *ExamAPI) QuestionsDelete(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/exam/questions/")
	a.DB.Exec("DELETE FROM exam_questions WHERE id = ? AND dept_id = ?", id, sess.DeptID)
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/exam/results?trainee_id=N
func (a *ExamAPI) ResultsList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	traineeID := r.URL.Query().Get("trainee_id")
	if sess.Role == "trainee" { traineeID = strconv.Itoa(sess.UserID) }

	query := `SELECT id, trainee_id, score, total, passed, answers, started_at, finished_at
	          FROM exam_results WHERE dept_id = ?`
	args := []any{sess.DeptID}
	if traineeID != "" {
		query += " AND trainee_id = ?"
		args = append(args, traineeID)
	}
	query += " ORDER BY finished_at ASC"

	rows, err := a.DB.Query(query, args...)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var results []map[string]any
	for rows.Next() {
		var id, traineeId, score, total int
		var passed bool
		var answers sql.NullString
		var startedAt, finishedAt sql.NullTime
		if err := rows.Scan(&id, &traineeId, &score, &total, &passed, &answers, &startedAt, &finishedAt); err != nil {
			internalError(w, err)
			return
		}
		res := map[string]any{
			"id": id, "trainee_id": traineeId, "score": score, "total": total,
			"passed": passed, "answers": "", "started_at": "", "finished_at": "",
		}
		if answers.Valid { res["answers"] = answers.String }
		if startedAt.Valid { res["started_at"] = startedAt.Time.Format(tsFormat) }
		if finishedAt.Valid { res["finished_at"] = finishedAt.Time.Format(tsFormat) }
		results = append(results, res)
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if results == nil { results = []map[string]any{} }
	writeJSON(w, results)
}

// POST /api/exam/results
func (a *ExamAPI) ResultsCreate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	var req struct {
		TraineeID int    `json:"trainee_id"`
		Score     int    `json:"score"`
		Total     int    `json:"total"`
		Passed    bool   `json:"passed"`
		Answers   string `json:"answers"`
		StartedAt string `json:"started_at"`
		FinishedAt string `json:"finished_at"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	// Trainee can only submit own results
	if sess.Role == "trainee" { req.TraineeID = sess.UserID }

	// Normalize ISO 8601 timestamps to MySQL format
	parseDatetime := func(s string) string {
		for _, layout := range []string{time.RFC3339, time.RFC3339Nano} {
			if t, err := time.Parse(layout, s); err == nil {
				return t.UTC().Format(tsFormat)
			}
		}
		return s
	}

	result, err := a.DB.Exec(
		`INSERT INTO exam_results (dept_id, trainee_id, score, total, passed, answers, started_at, finished_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		sess.DeptID, req.TraineeID, req.Score, req.Total, req.Passed, req.Answers,
		parseDatetime(req.StartedAt), parseDatetime(req.FinishedAt),
	)
	if err != nil {
		internalError(w, err)
		return
	}
	id, _ := result.LastInsertId()
	writeJSON(w, map[string]int64{"id": id})
}

// DELETE /api/exam/results/:id
func (a *ExamAPI) ResultsDelete(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/exam/results/")
	a.DB.Exec("DELETE FROM exam_results WHERE id = ? AND dept_id = ?", id, sess.DeptID)
	w.WriteHeader(http.StatusNoContent)
}

func (a *ExamAPI) QuestionsCount(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	var count int
	a.DB.QueryRow("SELECT COUNT(*) FROM exam_questions WHERE dept_id = ?", sess.DeptID).Scan(&count)
	writeJSON(w, map[string]int{"count": count})
}

// Route dispatches exam sub-routes
func (a *ExamAPI) Route(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/exam/")

	switch {
	case path == "questions" && r.Method == http.MethodGet:
		a.QuestionsList(w, r)
	case path == "questions" && r.Method == http.MethodPost:
		a.QuestionsCreate(w, r)
	case path == "questions/count" && r.Method == http.MethodGet:
		a.QuestionsCount(w, r)
	case strings.HasPrefix(path, "questions/") && r.Method == http.MethodPut:
		a.QuestionsUpdate(w, r)
	case strings.HasPrefix(path, "questions/") && r.Method == http.MethodDelete:
		a.QuestionsDelete(w, r)
	case path == "results" && r.Method == http.MethodPost:
		a.ResultsCreate(w, r)
	case strings.HasPrefix(path, "results") && r.Method == http.MethodGet:
		a.ResultsList(w, r)
	case strings.HasPrefix(path, "results/") && r.Method == http.MethodDelete:
		a.ResultsDelete(w, r)
	default:
		http.Error(w, "not found", http.StatusNotFound)
	}
}

