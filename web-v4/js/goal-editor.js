/* ================================================================
   SchulungsHub v4 – Lernziel-Editor
   CRUD für learning_goals (Admin/Trainer)
   Depends on: js/utils.js, js/state.js, api-client.js
   ================================================================ */
const GoalEditor = (() => {

  async function open() {
    if (!canVerify()) return;
    let ov = $("#goal-editor-overlay");
    if (ov) ov.remove();

    ov = document.createElement("div");
    ov.id = "goal-editor-overlay";
    ov.className = "exam-overlay";

    const goals = [...(S.db.learning_goals || [])].sort((a, b) =>
      (a.phase || "").localeCompare(b.phase || "") || (a.machine_id || "").localeCompare(b.machine_id || "") || (a.position || 0) - (b.position || 0)
    );
    const machines = S.db.machines;
    const phases = getPhases();

    // Group goals by phase
    const grouped = {};
    phases.forEach(p => { grouped[p.id] = goals.filter(g => g.phase === p.id); });

    let listHtml = "";
    phases.forEach(p => {
      const pGoals = grouped[p.id] || [];
      if (pGoals.length === 0 && !canAdmin()) return;
      listHtml += `<div class="ge-phase-group">
        <div class="ge-phase-label">${esc(p.label)} <span class="ge-phase-count">(${pGoals.length})</span></div>`;
      pGoals.forEach(g => {
        const mLabel = machineLabel(g.machine_id);
        listHtml += `<div class="ge-item" data-id="${esc(g.id)}">
          <div class="ge-item-main">
            <span class="search-badge badge-goal">${esc(mLabel)}</span>
            <span class="ge-item-title">${esc(g.title)}</span>
          </div>
          <div class="ge-item-actions">
            <button class="ge-edit" data-id="${esc(g.id)}" title="Bearbeiten">✎</button>
            <button class="ge-del" data-id="${esc(g.id)}" title="Löschen">&times;</button>
          </div>
        </div>`;
      });
      listHtml += `</div>`;
    });

    // Machine options
    const machineOpts = machines.map(m => `<option value="${esc(m.id)}">${esc(m.label)}</option>`).join("");
    const phaseOpts = phases.map(p => `<option value="${esc(p.id)}">${esc(p.label)}</option>`).join("");

    ov.innerHTML = `
      <div class="exam-card ge-card">
        <div class="exam-topbar">
          <span class="exam-progress-label" style="font-weight:700">Lernziele verwalten (${goals.length})</span>
          <button class="exam-close-btn" id="ge-close">&times;</button>
        </div>

        <div class="ge-form">
          <h3 id="ge-form-title">Neues Lernziel</h3>
          <input type="hidden" id="ge-edit-id" value="">
          <div class="ge-form-row">
            <select id="ge-phase" class="ge-select">${phaseOpts}</select>
            <select id="ge-machine" class="ge-select">${machineOpts}</select>
          </div>
          <input type="text" id="ge-title" class="ge-input" placeholder="Lernziel-Bezeichnung" autocomplete="off">
          <div class="ge-form-row">
            <input type="number" id="ge-position" class="ge-input-sm" placeholder="Position" min="0" value="0">
            <input type="number" id="ge-weight" class="ge-input-sm" placeholder="Gewichtung" min="0" step="0.1" value="1">
            <button class="btn-primary btn-sm" id="ge-save">Speichern</button>
            <button class="btn-secondary btn-sm hidden" id="ge-cancel">Abbrechen</button>
          </div>
        </div>

        <div class="ge-list">${listHtml || '<p style="opacity:0.4;padding:12px">Noch keine Lernziele.</p>'}</div>
      </div>`;

    document.body.appendChild(ov);

    // ── Save / Create ──
    ov.querySelector("#ge-save").addEventListener("click", async () => {
      const editId = ov.querySelector("#ge-edit-id").value;
      const phase = ov.querySelector("#ge-phase").value;
      const machineId = ov.querySelector("#ge-machine").value;
      const title = ov.querySelector("#ge-title").value.trim();
      const position = parseInt(ov.querySelector("#ge-position").value) || 0;
      const weight = parseFloat(ov.querySelector("#ge-weight").value) || 1;

      if (!title) { notify("Bezeichnung eingeben.", "warning"); return; }

      try {
        if (editId) {
          await Api.updateGoal(editId, { phase, machine_id: machineId, title, position, weight });
        } else {
          const newId = `${phase}_${machineId}_${Date.now()}`;
          await Api.createGoal({ id: newId, phase, machine_id: machineId, title, position, weight });
        }
        await reloadState();
        open();
      } catch (e) {
        notify("Fehler: " + e.message, "danger");
      }
    });

    // ── Cancel edit ──
    ov.querySelector("#ge-cancel").addEventListener("click", () => {
      resetForm(ov);
    });

    // ── Edit click ──
    ov.querySelectorAll(".ge-edit").forEach(btn => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        const g = goals.find(g => g.id === btn.dataset.id);
        if (!g) return;
        ov.querySelector("#ge-edit-id").value = g.id;
        ov.querySelector("#ge-phase").value = g.phase;
        ov.querySelector("#ge-machine").value = g.machine_id;
        ov.querySelector("#ge-title").value = g.title;
        ov.querySelector("#ge-position").value = g.position || 0;
        ov.querySelector("#ge-weight").value = g.weight || 1;
        ov.querySelector("#ge-form-title").textContent = "Lernziel bearbeiten";
        ov.querySelector("#ge-cancel").classList.remove("hidden");
        // Highlight
        ov.querySelectorAll(".ge-item").forEach(el => el.classList.toggle("editing", el.dataset.id === g.id));
        ov.querySelector(".ge-form").scrollIntoView({ behavior: "smooth", block: "start" });
      });
    });

    // ── Delete click ──
    ov.querySelectorAll(".ge-del").forEach(btn => {
      btn.addEventListener("click", async (e) => {
        e.stopPropagation();
        const g = goals.find(g => g.id === btn.dataset.id);
        if (!g) return;
        if (!confirm(`Lernziel "${g.title}" löschen?`)) return;
        try {
          await Api.deleteGoal(btn.dataset.id);
          await reloadState();
          open();
        } catch (e) {
          notify("Fehler: " + e.message, "danger");
        }
      });
    });

    // ── Close ──
    ov.querySelector("#ge-close").addEventListener("click", async () => {
      ov.remove();
      await reloadState();
      renderSidebar();
      renderPage();
    });

    // ESC
    function onKey(e) {
      if (e.key === "Escape") { ov.remove(); reloadState().then(() => { renderSidebar(); renderPage(); }); document.removeEventListener("keydown", onKey); }
    }
    document.addEventListener("keydown", onKey);
  }

  function resetForm(ov) {
    ov.querySelector("#ge-edit-id").value = "";
    ov.querySelector("#ge-title").value = "";
    ov.querySelector("#ge-position").value = "0";
    ov.querySelector("#ge-weight").value = "1";
    ov.querySelector("#ge-form-title").textContent = "Neues Lernziel";
    ov.querySelector("#ge-cancel").classList.add("hidden");
    ov.querySelectorAll(".ge-item").forEach(el => el.classList.remove("editing"));
  }

  return { open };
})();

/* Global shortcut */
const openGoalEditor = GoalEditor.open;
