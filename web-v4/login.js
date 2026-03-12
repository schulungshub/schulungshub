/* ================================================================
   SchulungsHub v4 – Login Page Logic (Server Version)
   Uses REST API instead of local sql.js database.
   Depends on: js/utils.js, api-client.js
   ================================================================ */

/* ── State ── */
let users = [];
let currentDept = null; // { id, name, slug }

/* ── Populate User Select ── */
function populateSelect(userList) {
  const sel = $("#login-user");
  // Keep first option, remove rest
  while (sel.options.length > 1) sel.remove(1);
  userList.forEach(u => {
    const opt = document.createElement("option");
    opt.value = u.username;
    opt.textContent = u.display_name;
    sel.appendChild(opt);
  });
}

/* ── Login Success ── */
function onLoginSuccess() {
  window.location.href = "index.html";
}

/* ── Form Submit ── */
async function handleSubmit(e) {
  e.preventDefault();
  const err = $("#login-error");
  const btn = $("#login-btn");
  err.textContent = "";

  const uname = ($("#login-user")?.value || "").trim();
  const pass = $("#login-pass")?.value || "";

  if (!uname) { err.textContent = "Bitte Benutzer auswählen."; return; }
  if (!pass) { err.textContent = "Bitte Passwort eingeben."; return; }
  if (!currentDept) { err.textContent = "Keine Abteilung gewählt."; return; }

  btn.classList.add("loading");
  btn.textContent = "Prüfe...";

  try {
    await Api.login(uname, pass, currentDept.slug);
    onLoginSuccess();
  } catch {
    err.textContent = "Ungültiges Passwort.";
  } finally {
    btn.classList.remove("loading");
    btn.textContent = "Einloggen";
  }
}

/* ── RFID ── */
let rfidTimer = null;

function startRfidListener() {
  const inp = $("#rfid-input");
  if (!inp) return;
  setInterval(() => {
    if (document.activeElement !== inp && document.activeElement?.tagName !== "SELECT" && document.activeElement?.type !== "password") {
      inp.focus();
    }
  }, 500);
}

function handleRfidInput() {
  clearTimeout(rfidTimer);
  rfidTimer = setTimeout(async () => {
    const inp = $("#rfid-input");
    const tag = (inp?.value || "").trim();
    inp.value = "";
    if (!tag || tag.length < 4) return;
    if (!currentDept) return;

    const err = $("#login-error");
    if (err) err.textContent = "";

    try {
      await Api.loginRfid(tag, currentDept.slug);
      onLoginSuccess();
    } catch {
      if (err) err.textContent = "RFID-Tag nicht erkannt.";
    }
  }, 300);
}

/* ── Theme ── */
function initTheme() {
  const saved = localStorage.getItem("schulungsHub.loginTheme") || "light";
  document.documentElement.setAttribute("data-theme", saved);
  updateThemeIcon(saved);
}

function toggleTheme() {
  const current = document.documentElement.getAttribute("data-theme");
  const next = current === "dark" ? "light" : "dark";
  document.documentElement.setAttribute("data-theme", next);
  localStorage.setItem("schulungsHub.loginTheme", next);
  updateThemeIcon(next);
}

function updateThemeIcon(theme) {
  const icon = $("#theme-icon");
  if (icon) icon.innerHTML = theme === "dark" ? "&#9790;" : "&#9788;";
}

/* ── Password Toggle ── */
function bindPwToggles() {
  document.querySelectorAll(".pw-toggle").forEach(btn => {
    btn.addEventListener("click", () => {
      const inp = document.getElementById(btn.dataset.target);
      if (!inp) return;
      const show = inp.type === "password";
      inp.type = show ? "text" : "password";
      btn.classList.toggle("visible", show);
      btn.innerHTML = show ? "&#9675;" : "&#9673;";
    });
  });
}

/* ── Department Selector ── */
async function loadDepartments() {
  try {
    const depts = await Api.departments();
    if (depts.length === 1) {
      currentDept = depts[0];
      const sel = $("#dept-select");
      if (sel) {
        sel.innerHTML = `<option>${depts[0].name}</option>`;
        sel.disabled = true;
        sel.closest(".form-group").classList.remove("hidden");
      }
    } else if (depts.length > 1) {
      const sel = $("#dept-select");
      if (sel) {
        sel.closest(".form-group")?.classList.remove("hidden");
        depts.forEach(d => {
          const opt = document.createElement("option");
          opt.value = d.slug;
          opt.textContent = d.name;
          sel.appendChild(opt);
        });
        sel.addEventListener("change", async () => {
          currentDept = depts.find(d => d.slug === sel.value) || null;
          if (currentDept) await loadLoginUsers();
        });
        currentDept = depts[0];
        sel.value = depts[0].slug;
      }
    }
    if (currentDept) await loadLoginUsers();
  } catch {
    const err = $("#login-error");
    if (err) err.textContent = "Server nicht erreichbar.";
  }
}

async function loadLoginUsers() {
  if (!currentDept) return;
  try {
    users = await Api.loginUsers(currentDept.slug);
    populateSelect(users);
  } catch {
    users = [];
  }
}

/* ── Boot ── */
async function boot() {
  initTheme();
  $("#theme-btn")?.addEventListener("click", toggleTheme);

  // Check if already logged in
  try {
    await Api.me();
    window.location.href = "index.html";
    return;
  } catch { /* not logged in, show login form */ }

  await loadDepartments();

  $("#login-form")?.addEventListener("submit", handleSubmit);
  bindPwToggles();
  const rfid = $("#rfid-input");
  if (rfid) rfid.addEventListener("input", handleRfidInput);
  startRfidListener();
}

boot();
