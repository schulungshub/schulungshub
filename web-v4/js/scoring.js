/* ================================================================
   SchulungsHub v4 – Scoring / Evaluations
   Bewertungen speichern, UI-Updates
   Depends on: js/utils.js ($, esc, nowIso, formatDate),
               js/state.js (S, canVerify, userName),
               js/eval.js (machineProgress, phaseProgress, overallProgress)
   ================================================================ */
const Scoring = (() => {
  const _saving = new Set();

  function saveEvaluation(goalId, score, errorRate, comment, action) {
    if (!canVerify() || !S.selectedTraineeId) return;
    if (_saving.has(goalId)) return;
    _saving.add(goalId);

    const fields = document.querySelector(`.goal-fields[data-goal-detail="${goalId}"]`);
    if (errorRate === undefined && fields) errorRate = parseFloat(fields.querySelector(".goal-error-rate")?.value) || 0;
    if (comment === undefined && fields) comment = fields.querySelector(".goal-comment")?.value || "";
    if (action === undefined && fields) action = fields.querySelector(".goal-action")?.value || "";

    const now = nowIso();
    Api.createEvaluation({
      trainee_id: S.selectedTraineeId, goal_id: goalId, score,
      error_rate: errorRate || 0, comment: (comment || "").trim(), action: (action || "").trim(),
    }).catch(e => notify("Bewertung fehlgeschlagen: " + e.message, "danger"))
      .finally(() => _saving.delete(goalId));

    const entry = { trainee_id: S.selectedTraineeId, goal_id: goalId, score, error_rate: errorRate || 0,
      comment: (comment || "").trim(), action: (action || "").trim(), evaluated_by: S.user.id, evaluated_at: now };
    S.evalMap[goalId] = entry;
    S.db.evaluations = (S.db.evaluations || []).concat([entry]);
    updateGoalCardUi(goalId);
  }

  function updateGoalCardUi(goalId) {
    const row = document.querySelector(`.goal-row[data-goal-id="${goalId}"]`);
    if (!row) return;
    const ev = S.evalMap[goalId];
    const score = ev ? (ev.score || 0) : 0;
    const isNio = ev && ev.score === 0 && ev.evaluated_at;
    row.dataset.score = score;
    row.querySelectorAll(".rating-pill-seg").forEach(seg => {
      const val = parseInt(seg.dataset.val, 10);
      if (val === 0) {
        seg.classList.toggle("filled", !!isNio);
      } else {
        seg.classList.toggle("filled", score >= val);
      }
    });
    const meta = row.querySelector(".goal-row-meta");
    if (meta && ev) meta.innerHTML = `${esc(userName(ev.evaluated_by))} · ${formatDate(ev.evaluated_at)}`;

    row.classList.toggle("has-data", !!(ev && (ev.comment || ev.action || ev.error_rate)));

    updateProgressUi(goalId);
  }

  function updateProgressUi(goalId) {
    const goal = S.db.learning_goals.find(g => g.id === goalId);
    if (!goal) return;
    const pid = goal.phase;
    const mid = goal.machine_id;

    const machineEl = document.querySelector(`.machine-group[data-machine="${mid}"][data-phase="${pid}"]`);
    if (machineEl) {
      const mpct = Math.round(machineProgress(pid, mid));
      const bar = machineEl.querySelector(".machine-mini-bar-fill");
      const label = machineEl.querySelector(".machine-mini-pct");
      if (bar) bar.style.width = mpct + "%";
      if (label) label.textContent = mpct + "%";
    }

    const phaseSec = document.getElementById("sec-phase-" + pid);
    if (phaseSec) {
      const ppct = Math.round(phaseProgress(pid));
      const bar = phaseSec.querySelector(".phase-header-bar-fill");
      const label = phaseSec.querySelector(".phase-header-pct");
      if (bar) bar.style.width = ppct + "%";
      if (label) label.textContent = ppct + "%";
    }

    const navLink = document.querySelector(`.nav-link[data-phase="${pid}"] .mono-label`);
    if (navLink) navLink.textContent = Math.round(phaseProgress(pid)) + "%";

    const dashPhase = document.querySelector(`.phase-bar-wrap[data-phase="${pid}"]`);
    if (dashPhase) {
      const ppct = Math.round(phaseProgress(pid));
      const bar = dashPhase.querySelector(".phase-bar-fill");
      const label = dashPhase.querySelector(".phase-bar-pct");
      if (bar) bar.style.width = ppct + "%";
      if (label) label.textContent = ppct + "%";
    }
    const kpi = document.getElementById("kpi-overall");
    if (kpi) kpi.textContent = overallProgress().toFixed(1) + "%";

    // Live-update ETA + dashboard KPIs
    const kpiEta = document.getElementById("kpi-eta");
    if (kpiEta) {
      const eta = computeEta();
      kpiEta.textContent = eta && eta.date.getFullYear() - new Date().getFullYear() < 15 ? formatDateKW(eta.date) : "-";
    }
    const kpiDone = document.getElementById("kpi-done");
    if (kpiDone) {
      const goals = S.db.learning_goals;
      const done = goals.filter(g => (S.evalMap[g.id]?.score || 0) >= 100).length;
      const inProg = goals.filter(g => { const s = S.evalMap[g.id]?.score || 0; return s > 0 && s < 100; }).length;
      kpiDone.textContent = done;
      const kpiInprog = document.getElementById("kpi-inprog");
      if (kpiInprog) kpiInprog.textContent = inProg;
    }

  }

  return { saveEvaluation, updateGoalCardUi, updateProgressUi };
})();

/* Global shortcuts */
const saveEvaluation = Scoring.saveEvaluation;
const updateGoalCardUi = Scoring.updateGoalCardUi;
const updateProgressUi = Scoring.updateProgressUi;
