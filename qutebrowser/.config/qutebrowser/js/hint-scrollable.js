// Hint group for scrollable elements and iframes; the picked one takes focus,
// so j/k, d/u and PgUp/PgDn scroll it. See hint-marks.js.
(() => {
  const scrolls = (overflow, scroll, client) =>
    /auto|scroll|overlay/.test(overflow) && scroll > client + 1;

  // The page root scrolls with overflow: visible, so it's checked on its own
  const root = document.scrollingElement;
  if (root && root.scrollHeight > root.clientHeight) qbHint.mark(root, 'scrollable');
  const walk = parent => parent.querySelectorAll('*').forEach(el => {
    if (el.shadowRoot) walk(el.shadowRoot);
    if (el === root) return;
    if (el.tagName === 'IFRAME' || el.tagName === 'FRAME') return qbHint.mark(el, 'scrollable');
    const style = getComputedStyle(el);
    if (scrolls(style.overflowY, el.scrollHeight, el.clientHeight) ||
        scrolls(style.overflowX, el.scrollWidth, el.clientWidth)) qbHint.mark(el, 'scrollable');
  });
  walk(document);

  qbHint.onPick = el => {
    // Back to the page itself: drop whatever inner element holds focus
    if (el === root) {
      let active = document.activeElement;
      while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
      active?.blur();
      return;
    }
    // A plain div only takes focus with a tabindex; hide the ring that focus() draws
    if (!el.hasAttribute('tabindex')) {
      el.tabIndex = -1;
      el.style.outline = 'none';
    }
    el.focus({ preventScroll: true });
  };
})();
