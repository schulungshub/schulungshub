/* ================================================================
   SchulungsHub v4 – Gefahrensymbole Overlay
   Katalog aller Sicherheitszeichen, gruppiert nach Kategorie
   Depends on: js/utils.js ($)
   ================================================================ */
const Symbols = (() => {
  const CATEGORIES = [
    {
      id: "verbote",
      label: "Verbotszeichen",
      color: "#dc2626",
      path: "img/symbole/verbote",
      items: [
        { file: "rauchen.avif", title: "Rauchen verboten" },
        { file: "feuer.avif", title: "Feuer, offenes Licht und Rauchen verboten" },
        { file: "herzschrittmacher.avif", title: "Kein Zutritt f\u00fcr Personen mit Herzschrittmacher" },
        { file: "mobilfunk.avif", title: "Mobilfunk verboten" },
        { file: "unbefugte.avif", title: "Zutritt f\u00fcr Unbefugte verboten" },
        { file: "essen.avif", title: "Essen und Trinken verboten" },
        { file: "flurf\u00f6rderzeuge.avif", title: "F\u00fcr Flurf\u00f6rderzeuge verboten" },
      ]
    },
    {
      id: "warnzeichen",
      label: "Warnzeichen",
      color: "#f59e0b",
      path: "img/symbole/warnzeichen",
      items: [
        { file: "Gefahrenstelle.avif", title: "Allgemeine Gefahrenstelle" },
        { file: "elektrische_spannung.avif", title: "Warnung vor elektrischer Spannung" },
        { file: "feuergef\u00e4hrlich.avif", title: "Warnung vor feuergef\u00e4hrlichen Stoffen" },
        { file: "brandf\u00f6rdernd.avif", title: "Warnung vor brandf\u00f6rdernden Stoffen" },
        { file: "giftigestoffe.avif", title: "Warnung vor giftigen Stoffen" },
        { file: "einzugsgefahr.avif", title: "Warnung vor Einzugsgefahr" },
        { file: "handverletzungen.avif", title: "Warnung vor Handverletzungen" },
        { file: "flurf\u00f6rderzeug.avif", title: "Warnung vor Flurf\u00f6rderzeugen" },
        { file: "reizend.avif", title: "Warnung vor gesundheitssch\u00e4dlichen oder reizenden Stoffen" },
        { file: "optische_strahlung.avif", title: "Warnung vor optischer Strahlung (UV)" },
        { file: "hei\u00dfe_oberflaeche.avif", title: "Warnung vor hei\u00dfer Oberfl\u00e4che" },
      ]
    },
    {
      id: "gefahrensymbole",
      label: "GHS-Gefahrensymbole",
      color: "#ef4444",
      path: "img/symbole/gefahrensymbole",
      items: [
        { file: "explosiv.gif", title: "Explosiv (GHS01)" },
        { file: "entz\u00fcndlich.gif", title: "Entz\u00fcndlich (GHS02)" },
        { file: "oxidierend.gif", title: "Oxidierend (GHS03)" },
        { file: "gase.gif", title: "Gase unter Druck (GHS04)" },
        { file: "aetzend.gif", title: "\u00c4tzend (GHS05)" },
        { file: "sehr_gifitg.gif", title: "Sehr giftig (GHS06)" },
        { file: "cmr_obere.gif", title: "Gesundheitsgefahr (GHS08)" },
        { file: "cmr_untere.gif", title: "Reizend / Gesundheitssch\u00e4dlich (GHS07)" },
        { file: "umwelt_gefaehrlichgif.gif", title: "Umweltgef\u00e4hrlich (GHS09)" },
      ]
    },
    {
      id: "gebot",
      label: "Gebotszeichen",
      color: "#2563eb",
      path: "img/symbole/gebot",
      items: []
    },
    {
      id: "rettung",
      label: "Rettungszeichen",
      color: "#16a34a",
      path: "img/symbole/rettung",
      items: [
        { file: "erste_hilfe.avif", title: "Erste Hilfe" },
        { file: "aed.avif", title: "Automatisierter Externer Defibrillator (AED)" },
        { file: "augensp\u00fchlung.avif", title: "Augensp\u00fcleinrichtung" },
        { file: "notdusche.avif", title: "Notdusche" },
        { file: "notausgang.avif", title: "Notausgang" },
        { file: "sammelstelle.avif", title: "Sammelstelle" },
        { file: "richtung.avif", title: "Richtungsangabe Rettungsweg" },
        { file: "richtung_unten.avif", title: "Richtungsangabe Rettungsweg (unten)" },
      ]
    },
    {
      id: "brandschutz",
      label: "Brandschutzzeichen",
      color: "#dc2626",
      path: "img/symbole/brandschutz",
      items: [
        { file: "feuerloescher.avif", title: "Feuerl\u00f6scher" },
        { file: "schlauch_hydrant.avif", title: "L\u00f6schschlauch / Hydrant" },
        { file: "Brandmelder_manuell.avif", title: "Brandmelder (manuell)" },
        { file: "leiter.avif", title: "Feuerleiter" },
        { file: "richtung.avif", title: "Richtungsangabe Brandschutz" },
        { file: "richtung-runter.avif", title: "Richtungsangabe Brandschutz (unten)" },
      ]
    },
  ];

  let overlay;

  function init() {
    overlay = $("#symbols-overlay");
    if (!overlay) return;

    $("#symbols-overlay-backdrop").addEventListener("click", close);
    $("#symbols-overlay-close").addEventListener("click", close);
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && overlay.classList.contains("active")) close();
    });
  }

  function open() {
    if (!overlay) return;
    const content = $("#symbols-overlay-content");
    if (!content.innerHTML) content.innerHTML = buildHtml();
    overlay.classList.add("active");
    document.body.style.overflow = "hidden";
  }

  function close() {
    if (!overlay) return;
    overlay.classList.remove("active");
    document.body.style.overflow = "";
  }

  function buildHtml() {
    return CATEGORIES
      .filter(cat => cat.items.length > 0)
      .map(cat => `
        <div class="sym-category">
          <h3 class="sym-category-title" style="border-left: 4px solid ${cat.color}; padding-left: 10px">${cat.label}</h3>
          <div class="sym-grid">
            ${cat.items.map(item => `
              <div class="sym-card">
                <img class="sym-img" src="${cat.path}/${item.file}" alt="${item.title}" loading="lazy">
                <span class="sym-label">${item.title}</span>
              </div>
            `).join("")}
          </div>
        </div>
      `).join("");
  }

  return { init, open, close, CATEGORIES };
})();
