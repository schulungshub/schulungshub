/* ================================================================
   SchulungsHub v4 – PDF Viewer Overlay
   Opens PDFs inline in a modal overlay using browser's native viewer
   ================================================================ */
const PdfViewer = (() => {
  let overlay, frame, titleEl, openTabLink, backdrop, closeBtn;

  function init() {
    overlay   = $('#pdf-overlay');
    frame     = $('#pdf-overlay-frame');
    titleEl   = $('#pdf-overlay-title');
    openTabLink = $('#pdf-open-tab');
    backdrop  = $('#pdf-overlay-backdrop');
    closeBtn  = $('#pdf-overlay-close');

    if (!overlay) return;

    backdrop.addEventListener('click', close);
    closeBtn.addEventListener('click', close);
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && overlay.classList.contains('active')) close();
    });
  }

  function open(path, title) {
    if (!overlay) return;
    frame.src = path + '#navpanes=0';
    titleEl.textContent = title || path.split('/').pop();
    openTabLink.href = path;
    overlay.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  function close() {
    if (!overlay) return;
    overlay.classList.remove('active');
    frame.src = 'about:blank';
    document.body.style.overflow = '';
  }

  return { init, open, close };
})();

/* Global shortcut */
const openPdf = PdfViewer.open;
