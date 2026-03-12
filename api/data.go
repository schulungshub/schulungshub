package api

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-sql-driver/mysql"
	"schulungshub/auth"
)

type DataAPI struct {
	DB *sql.DB
}

// GET /api/machines
func (a *DataAPI) Machines(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	rows, err := a.DB.Query(
		"SELECT id, label, position FROM machines WHERE dept_id = ? ORDER BY position", sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var machines []map[string]any
	for rows.Next() {
		var id, label string
		var pos int
		if err := rows.Scan(&id, &label, &pos); err != nil {
			internalError(w, err)
			return
		}
		machines = append(machines, map[string]any{"id": id, "label": label, "position": pos})
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if machines == nil { machines = []map[string]any{} }
	writeJSON(w, machines)
}

// GET /api/meta
func (a *DataAPI) MetaList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	rows, err := a.DB.Query("SELECT `key`, value FROM meta WHERE dept_id = ?", sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	meta := map[string]string{}
	for rows.Next() {
		var k, v string
		if err := rows.Scan(&k, &v); err != nil {
			internalError(w, err)
			return
		}
		meta[k] = v
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	writeJSON(w, meta)
}

// PUT /api/meta/:key
func (a *DataAPI) MetaSet(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	key := strings.TrimPrefix(r.URL.Path, "/api/meta/")
	var req struct {
		Value string `json:"value"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	_, err := a.DB.Exec(
		"INSERT INTO meta (dept_id, `key`, value) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = ?",
		sess.DeptID, key, req.Value, req.Value,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/content
func (a *DataAPI) ContentList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	rows, err := a.DB.Query(
		`SELECT id, title, position, content_md, parent_id, updated_at
		 FROM content_sections WHERE dept_id = ? ORDER BY position`, sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var sections []map[string]any
	for rows.Next() {
		var id, title string
		var pos int
		var contentMd, parentID sql.NullString
		var updatedAt sql.NullTime
		if err := rows.Scan(&id, &title, &pos, &contentMd, &parentID, &updatedAt); err != nil {
			internalError(w, err)
			return
		}
		s := map[string]any{
			"id": id, "title": title, "position": pos,
			"content_md": contentMd.String, "parent_id": nil,
		}
		if parentID.Valid { s["parent_id"] = parentID.String }
		if updatedAt.Valid { s["updated_at"] = updatedAt.Time.Format(tsFormat) }
		sections = append(sections, s)
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if sections == nil { sections = []map[string]any{} }
	writeJSON(w, sections)
}

// PUT /api/content/:id
func (a *DataAPI) ContentUpdate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/content/")
	if strings.Contains(id, "/") {
		// Handle /api/content/reorder
		if strings.HasSuffix(r.URL.Path, "/reorder") {
			a.contentReorder(w, r, sess)
			return
		}
		http.Error(w, "not found", http.StatusNotFound)
		return
	}

	var req struct {
		Title     *string `json:"title"`
		ContentMd *string `json:"content_md"`
		Position  *int    `json:"position"`
		ParentID  *string `json:"parent_id"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	var sets []string
	var args []any
	if req.Title != nil { sets = append(sets, "title = ?"); args = append(args, *req.Title) }
	if req.ContentMd != nil { sets = append(sets, "content_md = ?"); args = append(args, *req.ContentMd) }
	if req.Position != nil { sets = append(sets, "position = ?"); args = append(args, *req.Position) }
	if req.ParentID != nil { sets = append(sets, "parent_id = ?"); args = append(args, *req.ParentID) }

	if len(sets) == 0 {
		http.Error(w, "no fields", http.StatusBadRequest)
		return
	}

	args = append(args, id, sess.DeptID)
	_, err := a.DB.Exec(
		"UPDATE content_sections SET "+strings.Join(sets, ", ")+", updated_at = NOW() WHERE id = ? AND dept_id = ?",
		args...,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// POST /api/content
func (a *DataAPI) ContentCreate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		ID        string  `json:"id"`
		Title     string  `json:"title"`
		Position  int     `json:"position"`
		ContentMd string  `json:"content_md"`
		ParentID  *string `json:"parent_id"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	_, err := a.DB.Exec(
		`INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id)
		 VALUES (?, ?, ?, ?, ?, ?)`,
		req.ID, sess.DeptID, req.Title, req.Position, req.ContentMd, req.ParentID,
	)
	if err != nil {
		var mysqlErr *mysql.MySQLError
		if errors.As(err, &mysqlErr) && mysqlErr.Number == 1062 {
			http.Error(w, "id already exists", http.StatusConflict)
			return
		}
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusCreated)
}

// DELETE /api/content/:id
func (a *DataAPI) ContentDelete(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/content/")
	_, err := a.DB.Exec("DELETE FROM content_sections WHERE id = ? AND dept_id = ?", id, sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *DataAPI) contentReorder(w http.ResponseWriter, r *http.Request, sess *auth.Session) {
	var req []struct {
		ID       string `json:"id"`
		Position int    `json:"position"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	tx, err := a.DB.Begin()
	if err != nil {
		http.Error(w, "transaction error", http.StatusInternalServerError)
		return
	}
	for _, item := range req {
		if _, err := tx.Exec("UPDATE content_sections SET position = ? WHERE id = ? AND dept_id = ?",
			item.Position, item.ID, sess.DeptID); err != nil {
			tx.Rollback()
			internalError(w, err)
			return
		}
	}
	if err := tx.Commit(); err != nil {
		tx.Rollback()
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/goals
func (a *DataAPI) GoalsList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	rows, err := a.DB.Query(
		`SELECT id, machine_id, phase, title, weight, position
		 FROM learning_goals WHERE dept_id = ? ORDER BY position`, sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var goals []map[string]any
	for rows.Next() {
		var id, title string
		var machineID, phase sql.NullString
		var weight float64
		var pos int
		if err := rows.Scan(&id, &machineID, &phase, &title, &weight, &pos); err != nil {
			internalError(w, err)
			return
		}
		g := map[string]any{
			"id": id, "title": title, "weight": weight, "position": pos,
			"machine_id": nil, "phase": "",
		}
		if machineID.Valid { g["machine_id"] = machineID.String }
		if phase.Valid { g["phase"] = phase.String }
		goals = append(goals, g)
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if goals == nil { goals = []map[string]any{} }
	writeJSON(w, goals)
}

// PUT /api/goals/:id
func (a *DataAPI) GoalsUpdate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/goals/")
	if id == "reorder" {
		a.goalsReorder(w, r, sess)
		return
	}

	var req map[string]any
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	allowed := map[string]bool{"phase": true, "machine_id": true, "position": true, "title": true, "weight": true}
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
	if _, err := a.DB.Exec("UPDATE learning_goals SET "+strings.Join(sets, ", ")+" WHERE id = ? AND dept_id = ?", args...); err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *DataAPI) goalsReorder(w http.ResponseWriter, r *http.Request, sess *auth.Session) {
	var req []struct {
		ID       string `json:"id"`
		Position int    `json:"position"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	tx, err := a.DB.Begin()
	if err != nil {
		http.Error(w, "transaction error", http.StatusInternalServerError)
		return
	}
	for _, item := range req {
		if _, err := tx.Exec("UPDATE learning_goals SET position = ? WHERE id = ? AND dept_id = ?",
			item.Position, item.ID, sess.DeptID); err != nil {
			tx.Rollback()
			internalError(w, err)
			return
		}
	}
	if err := tx.Commit(); err != nil {
		tx.Rollback()
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// POST /api/goals
func (a *DataAPI) GoalsCreate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		ID        string  `json:"id"`
		MachineID *string `json:"machine_id"`
		Phase     string  `json:"phase"`
		Title     string  `json:"title"`
		Weight    float64 `json:"weight"`
		Position  int     `json:"position"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	_, err := a.DB.Exec(
		`INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		req.ID, sess.DeptID, req.MachineID, req.Phase, req.Title, req.Weight, req.Position,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusCreated)
}

// DELETE /api/goals/:id
func (a *DataAPI) GoalsDelete(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/goals/")
	a.DB.Exec("DELETE FROM evaluations WHERE goal_id = ? AND dept_id = ?", id, sess.DeptID)
	a.DB.Exec("DELETE FROM learning_goals WHERE id = ? AND dept_id = ?", id, sess.DeptID)
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/evaluations?trainee_id=N
func (a *DataAPI) EvaluationsList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	traineeID := r.URL.Query().Get("trainee_id")

	// Trainee can only see own evaluations
	if sess.Role == "trainee" {
		traineeID = strconv.Itoa(sess.UserID)
	}

	query := `SELECT id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at
	          FROM evaluations WHERE dept_id = ?`
	args := []any{sess.DeptID}
	if traineeID != "" {
		query += " AND trainee_id = ?"
		args = append(args, traineeID)
	}
	query += " ORDER BY evaluated_at ASC"

	rows, err := a.DB.Query(query, args...)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var evals []map[string]any
	for rows.Next() {
		var id, traineeId, score, evaluatedBy int
		var goalId string
		var errorRate sql.NullFloat64
		var comment, action sql.NullString
		var evaluatedAt sql.NullTime
		if err := rows.Scan(&id, &traineeId, &goalId, &score, &errorRate, &comment, &action, &evaluatedBy, &evaluatedAt); err != nil {
			internalError(w, err)
			return
		}
		e := map[string]any{
			"id": id, "trainee_id": traineeId, "goal_id": goalId, "score": score,
			"evaluated_by": evaluatedBy, "error_rate": nil, "comment": "", "action": "",
		}
		if errorRate.Valid { e["error_rate"] = errorRate.Float64 }
		if comment.Valid { e["comment"] = comment.String }
		if action.Valid { e["action"] = action.String }
		if evaluatedAt.Valid { e["evaluated_at"] = evaluatedAt.Time.Format(tsFormat) }
		evals = append(evals, e)
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if evals == nil { evals = []map[string]any{} }
	writeJSON(w, evals)
}

// POST /api/evaluations
func (a *DataAPI) EvaluationsCreate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role == "trainee" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		TraineeID int     `json:"trainee_id"`
		GoalID    string  `json:"goal_id"`
		Score     int     `json:"score"`
		ErrorRate *float64 `json:"error_rate"`
		Comment   string  `json:"comment"`
		Action    string  `json:"action"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	result, err := a.DB.Exec(
		`INSERT INTO evaluations (dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		sess.DeptID, req.TraineeID, req.GoalID, req.Score, req.ErrorRate, req.Comment, req.Action, sess.UserID,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	id, _ := result.LastInsertId()
	writeJSON(w, map[string]int64{"id": id})
}

// GET /api/attendance?trainee_id=N
func (a *DataAPI) AttendanceList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	traineeID := r.URL.Query().Get("trainee_id")
	if sess.Role == "trainee" { traineeID = strconv.Itoa(sess.UserID) }

	query := "SELECT id, trainee_id, machine_id, date, hours FROM attendance WHERE dept_id = ?"
	args := []any{sess.DeptID}
	if traineeID != "" {
		query += " AND trainee_id = ?"
		args = append(args, traineeID)
	}

	rows, err := a.DB.Query(query, args...)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var id, traineeId int
		var machineID sql.NullString
		var date time.Time
		var hours float64
		if err := rows.Scan(&id, &traineeId, &machineID, &date, &hours); err != nil {
			internalError(w, err)
			return
		}
		entry := map[string]any{"id": id, "trainee_id": traineeId, "date": date.Format("2006-01-02"), "hours": hours, "machine_id": nil}
		if machineID.Valid { entry["machine_id"] = machineID.String }
		list = append(list, entry)
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if list == nil { list = []map[string]any{} }
	writeJSON(w, list)
}

// POST /api/attendance
func (a *DataAPI) AttendanceCreate(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role == "trainee" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		TraineeID int     `json:"trainee_id"`
		MachineID *string `json:"machine_id"`
		Date      string  `json:"date"`
		Hours     float64 `json:"hours"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	result, err := a.DB.Exec(
		"INSERT INTO attendance (dept_id, trainee_id, machine_id, date, hours) VALUES (?, ?, ?, ?, ?)",
		sess.DeptID, req.TraineeID, req.MachineID, req.Date, req.Hours,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	id, _ := result.LastInsertId()
	writeJSON(w, map[string]int64{"id": id})
}

// DELETE /api/attendance/:id
func (a *DataAPI) AttendanceDelete(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role == "trainee" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/attendance/")
	a.DB.Exec("DELETE FROM attendance WHERE id = ? AND dept_id = ?", id, sess.DeptID)
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/trainee-meta/:id
func (a *DataAPI) TraineeMetaGet(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	id := strings.TrimPrefix(r.URL.Path, "/api/trainee-meta/")

	var feedback, conclusion, nextSteps sql.NullString
	err := a.DB.QueryRow(
		"SELECT feedback, conclusion, next_steps FROM trainee_meta WHERE trainee_id = ? AND dept_id = ?",
		id, sess.DeptID,
	).Scan(&feedback, &conclusion, &nextSteps)

	result := map[string]string{"feedback": "", "conclusion": "", "next_steps": ""}
	if err == nil {
		if feedback.Valid { result["feedback"] = feedback.String }
		if conclusion.Valid { result["conclusion"] = conclusion.String }
		if nextSteps.Valid { result["next_steps"] = nextSteps.String }
	}
	writeJSON(w, result)
}

// PUT /api/trainee-meta/:id
func (a *DataAPI) TraineeMetaSet(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role == "trainee" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/api/trainee-meta/")
	var req struct {
		Feedback   string `json:"feedback"`
		Conclusion string `json:"conclusion"`
		NextSteps  string `json:"next_steps"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	_, err := a.DB.Exec(
		`INSERT INTO trainee_meta (trainee_id, dept_id, feedback, conclusion, next_steps)
		 VALUES (?, ?, ?, ?, ?)
		 ON DUPLICATE KEY UPDATE feedback = ?, conclusion = ?, next_steps = ?`,
		id, sess.DeptID, req.Feedback, req.Conclusion, req.NextSteps,
		req.Feedback, req.Conclusion, req.NextSteps,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/search?q=...
func (a *DataAPI) Search(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	q := "%" + r.URL.Query().Get("q") + "%"

	rows, err := a.DB.Query(
		`(SELECT 'content' AS type, id, title, SUBSTRING(content_md, 1, 200) AS snippet
		  FROM content_sections WHERE dept_id = ? AND (title LIKE ? OR content_md LIKE ?))
		 UNION ALL
		 (SELECT 'goal' AS type, id, title, '' AS snippet
		  FROM learning_goals WHERE dept_id = ? AND title LIKE ?)
		 UNION ALL
		 (SELECT 'machine' AS type, id, label AS title, '' AS snippet
		  FROM machines WHERE dept_id = ? AND label LIKE ?)
		 LIMIT 20`,
		sess.DeptID, q, q, sess.DeptID, q, sess.DeptID, q,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var results []map[string]string
	for rows.Next() {
		var typ, id, title, snippet string
		if err := rows.Scan(&typ, &id, &title, &snippet); err != nil {
			internalError(w, err)
			return
		}
		results = append(results, map[string]string{
			"type": typ, "id": id, "title": title, "snippet": snippet,
		})
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if results == nil { results = []map[string]string{} }
	writeJSON(w, results)
}

// GET /api/confirmations?trainee_id=N
func (a *DataAPI) ConfirmationsList(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	traineeID := r.URL.Query().Get("trainee_id")
	if sess.Role == "trainee" {
		traineeID = strconv.Itoa(sess.UserID)
	}

	query := `SELECT section_id, trainee_id, trainer_id, trainer_confirmed_at, trainee_confirmed_at
	          FROM section_confirmations WHERE dept_id = ?`
	args := []any{sess.DeptID}
	if traineeID != "" {
		query += " AND trainee_id = ?"
		args = append(args, traineeID)
	}

	rows, err := a.DB.Query(query, args...)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var sectionID string
		var traineeId int
		var trainerID sql.NullInt64
		var trainerConfAt, traineeConfAt sql.NullTime
		if err := rows.Scan(&sectionID, &traineeId, &trainerID, &trainerConfAt, &traineeConfAt); err != nil {
			internalError(w, err)
			return
		}
		c := map[string]any{
			"section_id": sectionID, "trainee_id": traineeId,
			"trainer_id": nil, "trainer_confirmed_at": "", "trainee_confirmed_at": "",
		}
		if trainerID.Valid {
			c["trainer_id"] = trainerID.Int64
		}
		if trainerConfAt.Valid {
			c["trainer_confirmed_at"] = trainerConfAt.Time.Format(tsFormat)
		}
		if traineeConfAt.Valid {
			c["trainee_confirmed_at"] = traineeConfAt.Time.Format(tsFormat)
		}
		list = append(list, c)
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if list == nil {
		list = []map[string]any{}
	}
	writeJSON(w, list)
}

// POST /api/confirmations
func (a *DataAPI) ConfirmationsSet(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	var req struct {
		SectionID  string `json:"section_id"`
		TraineeID  int    `json:"trainee_id"`
		Action     string `json:"action"` // "trainer_confirm" or "trainee_confirm"
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	// Ensure row exists
	a.DB.Exec(
		`INSERT IGNORE INTO section_confirmations (section_id, trainee_id, dept_id) VALUES (?, ?, ?)`,
		req.SectionID, req.TraineeID, sess.DeptID,
	)

	switch req.Action {
	case "trainer_confirm":
		if sess.Role == "trainee" {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		a.DB.Exec(
			`UPDATE section_confirmations SET trainer_id = ?, trainer_confirmed_at = NOW()
			 WHERE section_id = ? AND trainee_id = ? AND dept_id = ?`,
			sess.UserID, req.SectionID, req.TraineeID, sess.DeptID,
		)
	case "trainee_confirm":
		if sess.UserID != req.TraineeID {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		a.DB.Exec(
			`UPDATE section_confirmations SET trainee_confirmed_at = NOW()
			 WHERE section_id = ? AND trainee_id = ? AND dept_id = ?`,
			req.SectionID, req.TraineeID, sess.DeptID,
		)
	default:
		http.Error(w, "invalid action", http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
