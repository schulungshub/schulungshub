/* ================================================================
   SchulungsHub v4 – Content Editor
   Markdown-Editor, Toolbar, Section CRUD
   Depends on: js/utils.js ($, esc, nowIso, debounce),
               js/state.js (S, reloadState, canEdit),
               js/markdown.js (renderMarkdown),
               js/sidebar.js (renderSidebar),
               render.js (renderPage, buildContentSectionHtml) — loaded later, called at runtime
   ================================================================ */
const Editor = (() => {
  function openEditor(sectionId) {
    S.editingSection = sectionId;
    sessionStorage.setItem("autosave-editing", sectionId);
    let sec = findSection(sectionId);
    if (!sec) return;

    const container = document.getElementById(`sec-${sectionId}`);
    if (!container) return;

    const currentMd = sec.content_md || "";

    container.innerHTML = `
      <h2>${esc(sec.title)}
        <button class="btn-icon editor-close-btn" title="Schliessen"><span uk-icon="icon: close; ratio:0.8"></span></button>
      </h2>
      <div class="editor-wrap">
        <div class="editor-toolbar">
          <button type="button" data-prefix="# " title="H1">H1</button>
          <button type="button" data-prefix="## " title="H2">H2</button>
          <button type="button" data-prefix="### " title="H3">H3</button>
          <button type="button" data-wrap="**" title="Fett">B</button>
          <button type="button" data-wrap="*" title="Kursiv">I</button>
          <button type="button" data-prefix="- " title="Liste">List</button>
          <button type="button" data-prefix="1. " title="Num. Liste">1.</button>
          <button type="button" data-action="code" title="Code (inline / Block)">Code</button>
          <button type="button" data-block="note" title="Hinweis">Hinweis</button>
          <button type="button" data-block="tip" title="Tipp">Tipp</button>
          <button type="button" data-block="warning" title="Warnung">Warnung</button>
          <button type="button" data-block="important" title="Achtung">Achtung</button>
          <button type="button" data-action="slideshow" title="Slideshow">Slides</button>
          <button type="button" data-action="pdf" title="PDF-Link einfügen">PDF</button>
          <span class="toolbar-sep"></span>
          <button type="button" data-stoerung="gelb" title="Störung Gelb" style="background:#ffd600;color:#000;border-radius:4px">Gelb</button>
          <button type="button" data-stoerung="orange" title="Störung Orange" style="background:#ff9100;color:#000;border-radius:4px">Orange</button>
          <button type="button" data-stoerung="rot" title="Störung Rot" style="background:#ff1744;color:#000;border-radius:4px">Rot</button>
        </div>
        <div class="editor-split">
          <div class="editor-input">
            <textarea id="editor-textarea" spellcheck="true">${esc(currentMd)}</textarea>
          </div>
          <div class="editor-preview md-content" id="editor-preview"></div>
        </div>
        <div class="editor-actions">
          <button class="btn-secondary btn-sm editor-cancel-btn">Abbrechen</button>
          <button class="btn-primary btn-sm editor-save-btn">Speichern</button>
        </div>
      </div>
    `;

    const textarea = $("#editor-textarea");
    const preview = $("#editor-preview");

    /* ── Autosave: restore draft if page was reloaded while editing ── */
    const draftKey = "autosave-" + sectionId;
    const draft = sessionStorage.getItem(draftKey);
    if (draft !== null && draft !== currentMd) {
      textarea.value = draft;
      notify("Entwurf wiederhergestellt", "success");
    }

    const updatePreview = () => { preview.innerHTML = renderMarkdown(textarea.value); initSlideshows(preview); };
    updatePreview();

    /* Save draft to sessionStorage on every input (debounced 500ms) */
    const saveDraft = debounce(() => sessionStorage.setItem(draftKey, textarea.value), 500);
    textarea.addEventListener("input", () => { saveDraft(); debounce(updatePreview, 200)(); });

    container.querySelectorAll(".editor-toolbar button").forEach(btn => {
      btn.addEventListener("click", () => {
        if (btn.dataset.prefix) prefixSelection(textarea, btn.dataset.prefix);
        else if (btn.dataset.wrap) wrapSelection(textarea, btn.dataset.wrap);
        else if (btn.dataset.block) blockSelection(textarea, btn.dataset.block);
        else if (btn.dataset.action === "code") codeSelection(textarea);
        else if (btn.dataset.action === "slideshow") slideshowSelection(textarea);
        else if (btn.dataset.action === "pdf") pdfLinkSelection(textarea);
        else if (btn.dataset.stoerung) stoerungSelection(textarea, btn.dataset.stoerung);
        updatePreview();
      });
    });

    container.querySelector(".editor-save-btn").addEventListener("click", async () => {
      try {
        await Api.updateContent(sectionId, { content_md: textarea.value });
      } catch (e) { notify("Speichern fehlgeschlagen: " + e.message, "danger"); return; }
      sessionStorage.removeItem(draftKey);
      sessionStorage.removeItem("autosave-editing");
      S.editingSection = null;
      notify("Gespeichert!", "success");
      await reloadState();
      renderPage();
    });

    const closeEditor = async () => {
      sessionStorage.removeItem(draftKey);
      sessionStorage.removeItem("autosave-editing");
      S.editingSection = null;
      await reloadState();
      renderPage();
    };

    container.querySelector(".editor-cancel-btn").addEventListener("click", closeEditor);
    container.querySelector(".editor-close-btn").addEventListener("click", closeEditor);
  }

  function prefixSelection(textarea, prefix) {
    const s = textarea.selectionStart, e = textarea.selectionEnd;
    const sel = textarea.value.slice(s, e);
    if (sel) {
      const prefixed = sel.split("\n").map(l => prefix + l).join("\n");
      textarea.value = textarea.value.slice(0, s) + prefixed + textarea.value.slice(e);
      textarea.selectionStart = s;
      textarea.selectionEnd = s + prefixed.length;
    } else {
      textarea.value = textarea.value.slice(0, s) + prefix + textarea.value.slice(e);
      textarea.selectionStart = textarea.selectionEnd = s + prefix.length;
    }
    textarea.focus();
  }

  function wrapSelection(textarea, w) {
    const s = textarea.selectionStart, e = textarea.selectionEnd;
    const sel = textarea.value.slice(s, e);
    if (sel) {
      textarea.value = textarea.value.slice(0, s) + w + sel + w + textarea.value.slice(e);
      textarea.selectionStart = s + w.length;
      textarea.selectionEnd = s + w.length + sel.length;
    } else {
      textarea.value = textarea.value.slice(0, s) + w + w + textarea.value.slice(e);
      textarea.selectionStart = textarea.selectionEnd = s + w.length;
    }
    textarea.focus();
  }

  function codeSelection(textarea) {
    const s = textarea.selectionStart, e = textarea.selectionEnd;
    const sel = textarea.value.slice(s, e);
    const multiline = sel.includes("\n");
    if (multiline || !sel) {
      const inner = sel || "Code hier...";
      const block = "\n```\n" + inner + "\n```\n";
      textarea.value = textarea.value.slice(0, s) + block + textarea.value.slice(e);
      textarea.selectionStart = s + 5;
      textarea.selectionEnd = s + 5 + inner.length;
    } else {
      textarea.value = textarea.value.slice(0, s) + "`" + sel + "`" + textarea.value.slice(e);
      textarea.selectionStart = s + 1;
      textarea.selectionEnd = s + 1 + sel.length;
    }
    textarea.focus();
  }

  function slideshowSelection(textarea) {
    const s = textarea.selectionStart, e = textarea.selectionEnd;
    const placeholder = "bild1.jpg\nbild2.jpg\nbild3.jpg";
    const block = "\n:::slideshow\n" + placeholder + "\n:::\n";
    textarea.value = textarea.value.slice(0, s) + block + textarea.value.slice(e);
    textarea.selectionStart = s + 14;
    textarea.selectionEnd = s + 14 + placeholder.length;
    textarea.focus();
  }

  function stoerungSelection(textarea, color) {
    const s = textarea.selectionStart, e = textarea.selectionEnd;
    const sel = textarea.value.slice(s, e) || "Störungstext hier...";
    const block = `\n:::${color}\n${sel}\n:::\n`;
    textarea.value = textarea.value.slice(0, s) + block + textarea.value.slice(e);
    const textStart = s + 4 + color.length + 1;
    textarea.selectionStart = textStart;
    textarea.selectionEnd = textStart + sel.length;
    textarea.focus();
  }

  function pdfLinkSelection(textarea) {
    const s = textarea.selectionStart, e = textarea.selectionEnd;
    const sel = textarea.value.slice(s, e);
    const title = sel || "Dokumentname";
    const link = `[pdf:${title}](pfad/zum/dokument.pdf)`;
    textarea.value = textarea.value.slice(0, s) + link + textarea.value.slice(e);
    // Select the path part for easy replacement
    const pathStart = s + link.indexOf("(") + 1;
    const pathEnd = s + link.indexOf(")");
    textarea.selectionStart = pathStart;
    textarea.selectionEnd = pathEnd;
    textarea.focus();
  }

  function blockSelection(textarea, type) {
    const s = textarea.selectionStart, e = textarea.selectionEnd;
    const sel = textarea.value.slice(s, e) || "Text hier...";
    const quoted = sel.split("\n").map(l => "> " + l).join("\n");
    const block = "\n> [!" + type.toUpperCase() + "]\n" + quoted + "\n";
    textarea.value = textarea.value.slice(0, s) + block + textarea.value.slice(e);
    textarea.selectionStart = s;
    textarea.selectionEnd = s + block.length;
    textarea.focus();
  }

  function startInlineRename(el) {
    const secId = el.dataset.sectionId;
    const sec = findSection(secId);
    if (!sec) return;

    const oldTitle = sec.title;
    const input = document.createElement("input");
    input.type = "text";
    input.value = oldTitle;
    input.className = "inline-rename";
    input.style.cssText = "font:inherit;font-size:inherit;font-weight:inherit;letter-spacing:inherit;color:var(--heading);background:var(--bg);border:2px solid var(--accent);border-radius:6px;padding:2px 8px;width:100%;outline:none;";

    el.replaceWith(input);
    input.focus();
    input.select();

    function commit() {
      const newTitle = input.value.trim();
      if (newTitle && newTitle !== oldTitle) {
        sec.title = newTitle;
        Api.updateContent(secId, { title: newTitle }).catch(() => {});
        renderSidebar();
      }
      const span = document.createElement("span");
      span.className = "section-title";
      span.dataset.sectionId = secId;
      span.title = "Doppelklick zum Umbenennen";
      span.textContent = sec.title;
      span.style.cursor = "pointer";
      span.addEventListener("dblclick", () => startInlineRename(span));
      input.replaceWith(span);
    }

    function cancel() {
      const span = document.createElement("span");
      span.className = "section-title";
      span.dataset.sectionId = secId;
      span.title = "Doppelklick zum Umbenennen";
      span.textContent = oldTitle;
      span.style.cursor = "pointer";
      span.addEventListener("dblclick", () => startInlineRename(span));
      input.replaceWith(span);
    }

    input.addEventListener("keydown", e => {
      if (e.key === "Enter") { e.preventDefault(); commit(); }
      if (e.key === "Escape") { e.preventDefault(); cancel(); }
    });
    input.addEventListener("blur", commit);
  }

  function findSection(id) {
    for (const s of (S.db.content_sections || [])) {
      if (s.id === id) return s;
      for (const ch of (s.children || [])) {
        if (ch.id === id) return ch;
        for (const sub of (ch.children || [])) { if (sub.id === id) return sub; }
      }
    }
    return null;
  }

  async function handleAddSection(parentId = null) {
    const label = parentId ? "Titel des Unterpunkts:" : "Titel der neuen Sektion:";
    const title = prompt(label);
    if (!title || !title.trim()) return;

    const secId = title.trim().toLowerCase().replace(/[^a-z0-9äöüß]+/g, "-").replace(/^-|-$/g, "") || `sec-${Date.now()}`;

    try {
      await Api.createContent({ id: secId, title: title.trim(), position: 999, content_md: "", parent_id: parentId });
    } catch (e) {
      const msg = e.message.includes("already exists")
        ? `Eine Sektion mit dem Titel "${title.trim()}" existiert bereits.`
        : "Fehler: " + e.message;
      notify(msg, "danger");
      return;
    }
    history.replaceState(null, "", "#sec-" + secId);
    await reloadState();
    renderSidebar();
    renderPage();
    notify(parentId ? "Unterpunkt erstellt!" : "Sektion erstellt!", "success");
  }

  async function handleDeleteSection(secId) {
    const sec = findSection(secId);
    if (!sec) return;
    const childCount = (sec.children || []).reduce((n, ch) => n + 1 + (ch.children || []).length, 0);
    const msg = childCount
      ? `"${sec.title}" und ${childCount} Unterpunkt(e) wirklich löschen?`
      : `"${sec.title}" wirklich löschen?`;
    if (!confirm(msg)) return;

    // Find next sibling to scroll to after delete
    const el = document.getElementById("sec-" + secId);
    const nextEl = el && el.nextElementSibling;
    const prevEl = el && el.previousElementSibling;
    const stayAt = (nextEl && nextEl.id) || (prevEl && prevEl.id) || "";

    const ids = [secId];
    (sec.children || []).forEach(ch => {
      ids.push(ch.id);
      (ch.children || []).forEach(sub => ids.push(sub.id));
    });
    for (const id of ids) { await Api.deleteContent(id); }
    if (stayAt) history.replaceState(null, "", "#" + stayAt);
    await reloadState();
    renderSidebar();
    renderPage();
    notify("Gelöscht!", "success");
  }

  async function handleMoveSection(secId, direction) {
    // Find section in content tree
    const sec = findSection(secId);
    if (!sec) return;

    // Find siblings from the tree
    let siblings;
    const findSiblings = (sections, targetId) => {
      for (const s of sections) {
        for (const ch of (s.children || [])) {
          if (ch.id === targetId) return s.children;
          for (const sub of (ch.children || [])) {
            if (sub.id === targetId) return ch.children;
          }
        }
        if (s.id === targetId) return sections;
      }
      return null;
    };
    siblings = findSiblings(S.db.content_sections, secId);
    if (!siblings) return;

    const idx = siblings.findIndex(s => s.id === secId);
    if (idx < 0) return;
    const swapIdx = direction === "up" ? idx - 1 : idx + 1;
    if (swapIdx < 0 || swapIdx >= siblings.length) return;

    // Swap positions via API
    const posA = siblings[idx].position;
    const posB = siblings[swapIdx].position;
    await Api.reorderContent([
      { id: siblings[idx].id, position: posB },
      { id: siblings[swapIdx].id, position: posA },
    ]);
    history.replaceState(null, "", "#sec-" + secId);
    await reloadState();
    renderSidebar();
    renderPage();
  }

  return {
    openEditor, prefixSelection, wrapSelection, codeSelection, slideshowSelection,
    stoerungSelection, blockSelection, startInlineRename, findSection, handleAddSection,
    handleDeleteSection, handleMoveSection,
  };
})();

/* Global shortcuts */
const openEditor = Editor.openEditor;
const prefixSelection = Editor.prefixSelection;
const wrapSelection = Editor.wrapSelection;
const codeSelection = Editor.codeSelection;
const slideshowSelection = Editor.slideshowSelection;
const stoerungSelection = Editor.stoerungSelection;
const blockSelection = Editor.blockSelection;
const startInlineRename = Editor.startInlineRename;
const findSection = Editor.findSection;
const handleAddSection = Editor.handleAddSection;
const handleDeleteSection = Editor.handleDeleteSection;
const handleMoveSection = Editor.handleMoveSection;
