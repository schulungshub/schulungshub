/* ================================================================
   SchulungsHub v4 – State & Data Access (Server Version)
   S-Objekt, reloadState() via API, User-Queries, Rollen-Checks
   Depends on: api-client.js
   ================================================================ */
const State = (() => {
  const DEFAULT_PHASES = [
    { id: "P1", label: "P1 · Grundlagen" },
    { id: "P2", label: "P2 · Fortgeschritten" },
    { id: "P3", label: "P3 · Experte" },
    { id: "P4", label: "P4 · Spezialist" },
    { id: "Mes", label: "MES" },
  ];

  function getPhases() {
    try {
      const raw = S.db?.meta?.phase_order;
      if (raw) {
        const arr = typeof raw === "string" ? JSON.parse(raw) : raw;
        if (Array.isArray(arr) && arr.length) return arr;
      }
    } catch { /* fallback */ }
    return DEFAULT_PHASES;
  }

  async function reloadState() {
    const data = await Api.loadAll();

    // Build content tree from flat list
    const allSections = data.content_sections || [];
    function buildTree(parentId) {
      return allSections
        .filter(s => (s.parent_id || null) === parentId)
        .map(s => {
          const { parent_id, ...rest } = s;
          const kids = buildTree(String(s.id));
          if (kids.length) rest.children = kids;
          return rest;
        });
    }
    const content_sections = buildTree(null);

    // Normalize users
    const users = (data.users || []).map(u => ({
      ...u, active: u.active !== false && u.active !== 0,
      must_change_password: !!u.must_change_password,
      has_training: !!u.has_training,
      motorik_level: u.motorik_level != null ? u.motorik_level : 2,
    }));

    // Meta object
    const meta = data.meta || {};
    meta.schema_version = parseInt(meta.schema_version) || 3;

    S.db = {
      meta,
      users,
      machines: data.machines || [],
      content_sections,
      learning_goals: data.learning_goals || [],
      evaluations: data.evaluations || [],
      attendance: data.attendance || [],
      trainee_meta: {},
      section_confirmations: [],
    };
  }

  /** Load trainee-specific data (meta + confirmations) */
  async function loadTraineeData(traineeId) {
    if (!traineeId) return;
    const [meta, confirmations] = await Promise.all([
      Api.loadTraineeMeta(traineeId),
      Api.loadConfirmations(traineeId),
    ]);
    S.db.trainee_meta[traineeId] = meta;
    S.db.section_confirmations = confirmations || [];
  }

  function buildConfirmMap(traineeId) {
    if (!traineeId) return {};
    const rows = (S.db?.section_confirmations || []).filter(r => r.trainee_id === traineeId);
    const map = {};
    rows.forEach(r => { map[r.section_id] = r; });
    return map;
  }

  function allUsers() { return (S.db?.users || []).filter(u => u.active !== false); }
  function allTrainees() { return allUsers().filter(u => u.role === "trainee").sort((a, b) => a.display_name.localeCompare(b.display_name, "de")); }
  function findUser(id) { return allUsers().find(u => u.id === id) || null; }
  function userName(id) { const u = findUser(id); return u ? u.display_name : "?"; }
  function canVerify() { return S.user && (S.user.role === "admin" || S.user.role === "trainer"); }
  function canAdmin() { return S.user && S.user.role === "admin"; }
  function canEdit() { return canAdmin(); }
  function machineLabel(id) { const m = (S.db?.machines || []).find(m => m.id === id); return m ? m.label : id; }

  return { DEFAULT_PHASES, getPhases, reloadState, loadTraineeData, buildConfirmMap, allUsers, allTrainees, findUser, userName, canVerify, canAdmin, canEdit, machineLabel };
})();

/* Global state object */
const S = {
  db: null,
  user: null,
  features: {},
  trainees: [],
  selectedTraineeId: null,
  evalMap: {},
  confirmMap: {},
  prefs: { theme: "light", font: "M" },
  loginMode: "password",
  editingSection: null,
  sortMode: false,
  fieldTimers: {},
};

/** feat('feature_evaluations') → true unless explicitly set to false */
function feat(name) { return S.features[name] !== false; }

/* Global shortcuts */
const reloadState = State.reloadState;
const loadTraineeData = State.loadTraineeData;
const allUsers = State.allUsers;
const allTrainees = State.allTrainees;
const findUser = State.findUser;
const userName = State.userName;
const canVerify = State.canVerify;
const canAdmin = State.canAdmin;
const canEdit = State.canEdit;
const machineLabel = State.machineLabel;
const getPhases = State.getPhases;
const DEFAULT_PHASES = State.DEFAULT_PHASES;
const buildConfirmMap = State.buildConfirmMap;
