/* ================================================================
   SchulungsHub v4 – Section Confirmations
   Quittierungssystem: Trainer "gezeigt" + Trainee "empfangen"
   Depends on: js/utils.js, js/state.js, api-client.js
   ================================================================ */
const Confirm = (() => {

  /* ── Build confirm row HTML for a section ── */

  function buildConfirmRow(sectionId) {
    const tid = S.selectedTraineeId || (S.user?.role === "trainee" ? S.user?.id : null);
    if (!tid) return "";

    const c = S.confirmMap?.[sectionId] || {};

    let trainerHtml = "";
    let traineeHtml = "";

    // Trainer side
    if (canVerify() && S.selectedTraineeId) {
      if (c.trainer_confirmed_at) {
        trainerHtml = `<span class="confirm-chip confirm-done" title="${esc(userName(c.trainer_id))}">&#10003; Freigegeben &middot; ${esc(userName(c.trainer_id))} &middot; ${formatDateShort(c.trainer_confirmed_at)}</span>`;
      } else {
        trainerHtml = `<button class="confirm-btn confirm-trainer-btn" data-confirm-section="${sectionId}" data-confirm-side="trainer">&#10003; Freigeben</button>`;
      }
    } else if (c.trainer_confirmed_at) {
      trainerHtml = `<span class="confirm-chip confirm-done">&#10003; Freigegeben &middot; ${formatDateShort(c.trainer_confirmed_at)}</span>`;
    }

    // Trainee side
    if (S.user?.role === "trainee") {
      if (c.trainee_confirmed_at) {
        traineeHtml = `<span class="confirm-chip confirm-done">&#10003; Empfangen &middot; ${formatDateShort(c.trainee_confirmed_at)}</span>`;
      } else {
        traineeHtml = `<button class="confirm-btn confirm-trainee-btn" data-confirm-section="${sectionId}" data-confirm-side="trainee">Empfangen best&auml;tigen</button>`;
      }
    } else if (c.trainee_confirmed_at) {
      traineeHtml = `<span class="confirm-chip confirm-done">&#10003; Empfangen &middot; ${formatDateShort(c.trainee_confirmed_at)}</span>`;
    }

    if (!trainerHtml && !traineeHtml) return "";

    return `<div class="sec-confirm-row" data-section-id="${sectionId}">${trainerHtml}${traineeHtml ? `<span class="confirm-sep">|</span>${traineeHtml}` : ""}</div>`;
  }

  /* ── Perform confirmation ── */

  async function confirmSection(sectionId, side) {
    const tid = S.selectedTraineeId || (S.user?.role === "trainee" ? S.user?.id : null);
    if (!tid) return;

    const now = nowIso();
    const action = side === "trainer" ? "trainer_confirm" : "trainee_confirm";

    Api.setConfirmation({ section_id: sectionId, trainee_id: tid, action })
      .catch(e => notify("Fehler: " + e.message, "danger"));

    if (!S.confirmMap[sectionId]) S.confirmMap[sectionId] = { section_id: sectionId, trainee_id: tid };
    if (side === "trainer" && canVerify()) {
      S.confirmMap[sectionId].trainer_id = S.user.id;
      S.confirmMap[sectionId].trainer_confirmed_at = now;
    } else if (side === "trainee") {
      S.confirmMap[sectionId].trainee_confirmed_at = now;
    }

    updateConfirmUi(sectionId);
  }

  /* ── Update single confirm row in-place ── */

  function updateConfirmUi(sectionId) {
    const row = document.querySelector(`.sec-confirm-row[data-section-id="${sectionId}"]`);
    const newHtml = buildConfirmRow(sectionId);
    if (!newHtml) { if (row) row.remove(); return; }
    if (row) {
      row.outerHTML = newHtml;
    } else {
      // Append to section if it wasn't there yet
      const sec = document.getElementById(`sec-${sectionId}`);
      if (sec) sec.insertAdjacentHTML("beforeend", newHtml);
    }
  }

  /* ── Document-level event delegation ── */

  function init() {
    document.addEventListener("click", (e) => {
      const btn = e.target.closest("[data-confirm-section]");
      if (!btn) return;
      confirmSection(btn.dataset.confirmSection, btn.dataset.confirmSide);
    });
  }

  return { init, buildConfirmRow, confirmSection, updateConfirmUi };
})();

/* Global shortcuts */
const buildConfirmRow = Confirm.buildConfirmRow;
const confirmSection = Confirm.confirmSection;
