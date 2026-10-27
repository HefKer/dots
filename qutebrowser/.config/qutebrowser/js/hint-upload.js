// Hint group for file inputs, followed with a plain `normal` hint click: a file
// picker only opens for a click from the user, and a hint click counts where
// input.click() from jseval doesn't. See hint-marks.js.
//
// Drag-and-drop sites hide the input, and a hidden element gets neither a hint
// nor a click, so each hidden one is shown for the hint as a small, nearly
// transparent box over a visible stand-in: one of its <label>s, or else its
// closest visible ancestor, usually the drop zone. Its own style comes back
// once it's clicked, or on the next run if hinting was cancelled.
(() => {
  const visible = el => {
    const rect = el.getBoundingClientRect();
    const style = getComputedStyle(el);
    return rect.width > 0 && rect.height > 0 &&
      style.visibility === 'visible' && style.opacity !== '0';
  };
  // Up through shadow roots too, from a shadow root's top to its host
  const parent = el => el.parentElement || el.getRootNode().host;
  const standIn = input => {
    const label = [...(input.labels || [])].find(visible);
    if (label) return label;
    for (let el = parent(input); el; el = parent(el)) if (visible(el)) return el;
  };

  const surface = input => {
    const at = standIn(input)?.getBoundingClientRect();
    if (!at) return;
    const style = input.getAttribute('style');
    qbHint.onReset(() => {
      if (style === null) input.removeAttribute('style');
      else input.setAttribute('style', style);
    });
    // Clamped into the viewport, since a hint only goes on what's on screen
    input.style.cssText = `
      display: block !important; visibility: visible !important;
      opacity: 0.01 !important; position: fixed !important;
      left: ${Math.max(0, at.left)}px !important; top: ${Math.max(0, at.top)}px !important;
      width: 24px !important; height: 24px !important;
      z-index: 2147483647 !important;
    `;
  };

  const walk = root => {
    for (const el of root.querySelectorAll('*')) {
      if (el.shadowRoot) walk(el.shadowRoot);
      if (el.tagName === 'INPUT' && el.type === 'file') {
        if (!visible(el)) surface(el);
        qbHint.mark(el, 'upload');
        el.addEventListener('click', () => qbHint.reset(), { once: true });
      }
      if (el.tagName === 'IFRAME') {
        try { if (el.contentDocument) walk(el.contentDocument); } catch {}
      }
    }
  };
  walk(document);
})();
