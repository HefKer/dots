// Hint group for scrollable elements and iframes; the picked one takes focus,
// so j/k, d/u and PgUp/PgDn scroll it. With two areas on screen and one of them
// current, only the other is marked, so js-hint --follow-lone jumps straight to
// it. See hint-marks.js.
(() => {
  const scrolls = (overflow, scroll, client) =>
    /auto|scroll|overlay/.test(overflow) && scroll > client + 1;

  // The page root scrolls with overflow: visible, so it's checked on its own
  const root = document.scrollingElement;
  const found = [];
  if (root && root.scrollHeight > root.clientHeight) found.push(root);
  const walk = parent => parent.querySelectorAll('*').forEach(el => {
    if (el.shadowRoot) walk(el.shadowRoot);
    if (el === root) return;
    if (el.tagName === 'IFRAME' || el.tagName === 'FRAME') return found.push(el);
    const style = getComputedStyle(el);
    if (scrolls(style.overflowY, el.scrollHeight, el.clientHeight) ||
        scrolls(style.overflowX, el.scrollWidth, el.clientWidth)) found.push(el);
  });
  walk(document);

  // What qutebrowser's own hinting counts as visible, so both see the same areas
  const visible = el => {
    const style = getComputedStyle(el);
    const rect = el.getBoundingClientRect();
    return style.visibility === 'visible' && style.display !== 'none' && style.opacity !== '0' &&
      rect.top <= innerHeight && rect.bottom >= 0 && rect.left <= innerWidth && rect.right >= 0 &&
      el.getClientRects().length > 0;
  };

  const deepActive = () => {
    let active = document.activeElement;
    while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
    return active;
  };

  // The area holding focus; nothing focused walks up to the root
  const current = areas => {
    let el = deepActive();
    while (el && !areas.includes(el)) el = el.parentElement ?? el.getRootNode().host;
    return el;
  };

  const areas = found.filter(visible);
  const from = areas.length === 2 && current(areas);
  (from ? areas.filter(el => el !== from) : found).forEach(el => qbHint.mark(el, 'scrollable'));

  qbHint.onPick = el => {
    // Back to the page itself: drop whatever inner element holds focus
    if (el === root) {
      deepActive()?.blur();
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
