/* ================================================================
   SchulungsHub v4 – API Client
   Replaces db-engine.js: all data via REST API (Go server + MySQL)
   Every read = API call, every write = API call. No local cache.
   ================================================================ */
const Api = (() => {

  async function request(method, path, body) {
    const opts = { method, credentials: "include", headers: {} };
    if (body !== undefined) {
      opts.headers["Content-Type"] = "application/json";
      opts.body = JSON.stringify(body);
    }
    const res = await fetch(path, opts);
    if (res.status === 401) {
      if (!location.pathname.endsWith("login.html")) {
        location.href = "login.html";
      }
      throw new Error("Nicht angemeldet");
    }
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || res.statusText);
    }
    if (res.status === 204) return null;
    const ct = res.headers.get("content-type") || "";
    if (ct.includes("application/json")) return res.json();
    return null;
  }

  const get  = (path) => request("GET", path);
  const post = (path, body) => request("POST", path, body);
  const put  = (path, body) => request("PUT", path, body);
  const del  = (path) => request("DELETE", path);

  /* ── Auth ── */

  function login(username, password, dept) {
    return post("/api/auth/login", { username, password, dept });
  }

  function loginRfid(rfidHash, dept) {
    return post("/api/auth/rfid-login", { rfid_hash: rfidHash, dept });
  }

  function logout() {
    return post("/api/auth/logout", {});
  }

  function me() {
    return get("/api/auth/me");
  }

  /** Public: list departments */
  function departments() {
    return get("/api/auth/departments");
  }

  /** Public: list user display names for login dropdown */
  function loginUsers(deptId) {
    return get("/api/auth/login-users?dept=" + deptId);
  }

  /* ── Data loading (replaces reloadState) ── */

  function loadMeta()       { return get("/api/meta"); }
  function loadUsers()      { return get("/api/users"); }
  function loadMachines()   { return get("/api/machines"); }
  function loadContent()    { return get("/api/content"); }
  function loadGoals()      { return get("/api/goals"); }

  function loadEvaluations(traineeId) {
    const q = traineeId ? "?trainee_id=" + traineeId : "";
    return get("/api/evaluations" + q);
  }

  function loadAttendance(traineeId) {
    const q = traineeId ? "?trainee_id=" + traineeId : "";
    return get("/api/attendance" + q);
  }

  function loadTraineeMeta(traineeId) {
    return get("/api/trainee-meta/" + traineeId);
  }

  /** Load all data needed for S.db in parallel */
  async function loadAll() {
    const evalMode = typeof feat === "function" ? feat("feature_evaluations") : true;
    const [meta, users, machines, content, goals, evaluations, attendance] = await Promise.all([
      loadMeta(), loadUsers(), loadMachines(), loadContent(),
      evalMode ? loadGoals() : Promise.resolve([]),
      evalMode ? loadEvaluations() : Promise.resolve([]),
      evalMode ? loadAttendance() : Promise.resolve([]),
    ]);
    return { meta, users, machines, content_sections: content, learning_goals: goals, evaluations, attendance };
  }

  /* ── Users ── */

  function createUser(data) { return post("/api/users", data); }

  function updateUser(id, data) { return put("/api/users/" + id, data); }

  function deleteUser(id) { return del("/api/users/" + id); }

  function changePassword(userId, password, mustChange) {
    return put("/api/users/" + userId + "/password", { password, must_change_password: mustChange });
  }

  function changeRfid(userId, rfidHash) {
    return put("/api/users/" + userId + "/rfid", { rfid_hash: rfidHash });
  }

  function changeTheme(userId, theme) {
    return put("/api/users/" + userId + "/theme", { theme });
  }

  /* ── Content ── */

  function createContent(data) { return post("/api/content", data); }

  function updateContent(id, data) { return put("/api/content/" + id, data); }

  function deleteContent(id) { return del("/api/content/" + id); }

  function reorderContent(items) { return put("/api/content/reorder", items); }

  /* ── Goals ── */

  function createGoal(data) { return post("/api/goals", data); }

  function updateGoal(id, data) { return put("/api/goals/" + id, data); }

  function deleteGoal(id) { return del("/api/goals/" + id); }

  function reorderGoals(items) { return put("/api/goals/reorder", items); }

  /* ── Evaluations ── */

  function createEvaluation(data) { return post("/api/evaluations", data); }

  /* ── Attendance ── */

  function createAttendance(data) { return post("/api/attendance", data); }

  function deleteAttendance(id) { return del("/api/attendance/" + id); }

  /* ── Trainee Meta ── */

  function setTraineeMeta(traineeId, data) { return put("/api/trainee-meta/" + traineeId, data); }

  /* ── Section Confirmations ── */

  function loadConfirmations(traineeId) {
    return get("/api/confirmations?trainee_id=" + traineeId);
  }

  function setConfirmation(data) { return post("/api/confirmations", data); }

  /* ── Meta ── */

  function setMeta(key, value) { return put("/api/meta/" + key, { value }); }

  /* ── Search ── */

  function search(q) { return get("/api/search?q=" + encodeURIComponent(q)); }

  /* ── Exam ── */

  function loadExamQuestions()      { return get("/api/exam/questions"); }
  function loadExamQuestionsCount() { return get("/api/exam/questions/count"); }
  function createExamQuestion(data) { return post("/api/exam/questions", data); }
  function updateExamQuestion(id, data) { return put("/api/exam/questions/" + id, data); }
  function deleteExamQuestion(id)   { return del("/api/exam/questions/" + id); }

  function loadExamResults(traineeId) {
    const q = traineeId ? "?trainee_id=" + traineeId : "";
    return get("/api/exam/results" + q);
  }
  function createExamResult(data)   { return post("/api/exam/results", data); }
  function deleteExamResult(id)     { return del("/api/exam/results/" + id); }

  /* ── Export / Import ── */

  function exportAll() { return get("/api/export"); }
  function importAll(data) { return post("/api/import", data); }

  /* ── Version ── */

  function version() { return get("/api/version"); }

  return {
    // Generic
    get, post, put, del,
    // Auth
    login, loginRfid, logout, me, departments, loginUsers,
    // Data loading
    loadAll, loadMeta, loadUsers, loadMachines, loadContent, loadGoals,
    loadEvaluations, loadAttendance, loadTraineeMeta, loadConfirmations,
    // Users
    createUser, updateUser, deleteUser, changePassword, changeRfid, changeTheme,
    // Content
    createContent, updateContent, deleteContent, reorderContent,
    // Goals
    createGoal, updateGoal, deleteGoal, reorderGoals,
    // Evaluations
    createEvaluation,
    // Attendance
    createAttendance, deleteAttendance,
    // Trainee Meta
    setTraineeMeta,
    // Confirmations
    setConfirmation,
    // Meta
    setMeta,
    // Search
    search,
    // Exam
    loadExamQuestions, loadExamQuestionsCount, createExamQuestion, updateExamQuestion, deleteExamQuestion,
    loadExamResults, createExamResult, deleteExamResult,
    // Export/Import
    exportAll, importAll,
    // Version
    version,
  };
})();
