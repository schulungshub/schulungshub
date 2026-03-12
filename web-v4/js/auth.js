/* ================================================================
   SchulungsHub v4 – Auth & Session (Server Version)
   Server manages sessions via HttpOnly cookies.
   Depends on: api-client.js, js/state.js (S, findUser)
   ================================================================ */
const Auth = (() => {

  /** Check server session, populate S.user */
  async function restoreSession() {
    try {
      const me = await Api.me();
      S.features = me.features || {};
      S.user = findUser(me.id);
      if (!S.user) {
        // User from /me not in loaded users list — use API response directly
        S.user = { id: me.id, username: me.username, display_name: me.display_name, role: me.role, dept_id: me.dept_id };
      }
    } catch {
      S.user = null;
    }
  }

  /* ── Shift-change auto-logout ── */
  const SHIFT_TIMES = [6, 14, 22];
  let _sessionStart = Date.now();

  function getShiftCountdown() {
    const login = new Date(_sessionStart);
    const now = new Date();

    for (let dayOffset = 0; dayOffset <= 1; dayOffset++) {
      for (const sh of SHIFT_TIMES) {
        const boundary = new Date(login);
        boundary.setDate(boundary.getDate() + dayOffset);
        boundary.setHours(sh, 0, 0, 0);
        if (boundary <= login) continue;
        if (boundary < now && !(boundary.getHours() === now.getHours() && now.getMinutes() <= 1)) continue;

        const minsBeforeBoundary = (boundary - login) / 60000;
        if (minsBeforeBoundary <= 30) continue;

        const diff = Math.max(0, boundary - Date.now());
        const hours = Math.floor(diff / 3600000);
        const mins = Math.floor((diff % 3600000) / 60000);
        return { hours, mins, nextShift: sh };
      }
    }
    return { hours: 0, mins: 0, nextShift: SHIFT_TIMES[0] };
  }

  function updateSessionTimer() {
    const el = $("#session-timer");
    if (!el || !S.user) return;
    const { hours, mins, nextShift } = getShiftCountdown();
    const pad = n => String(n).padStart(2, "0");
    el.textContent = `⏱ ${pad(hours)}:${pad(mins)}`;
    el.title = `Auto-Logout um ${pad(nextShift)}:00`;
    el.classList.toggle("timer-warn", hours === 0 && mins <= 10);
  }

  function setupShiftLogout() {
    _sessionStart = Date.now();
    updateSessionTimer();
    setInterval(() => {
      if (!S.user) return;
      updateSessionTimer();

      const { hours, mins } = getShiftCountdown();
      if (hours === 0 && mins === 0) {
        notify("Schichtwechsel – automatisch abgemeldet.", "warning");
        handleLogout();
      }
    }, 30000);
  }

  function redirectToLogin() {
    window.location.href = "login.html";
  }

  async function handleLogout() {
    try { await Api.logout(); } catch { /* ignore */ }
    S.user = null;
    redirectToLogin();
  }

  return {
    restoreSession, setupShiftLogout, redirectToLogin, handleLogout,
    getShiftCountdown, updateSessionTimer,
  };
})();

/* Global shortcuts */
const restoreSession = Auth.restoreSession;
const setupShiftLogout = Auth.setupShiftLogout;
const redirectToLogin = Auth.redirectToLogin;
const handleLogout = Auth.handleLogout;
