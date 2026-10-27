// Mark every scrollable element and iframe for `hint scrollable`, and define
// qbScrollFocus(url) for the hint to call on the chosen one.
//
// A `run` hint needs a URL to substitute for {hint-url}, so each marked element
// gets href="qbscroll:N", N indexing window.qbScroll. The marks come off once a
// hint is chosen, or on the next run if hinting was cancelled.
(() => {
  const unmark = els => els.forEach(el => {
    el.removeAttribute('data-qb-scroll');
    el.removeAttribute('href');
  });
  unmark(window.qbScroll || []);

  const els = [];
  const mark = el => {
    el.setAttribute('data-qb-scroll', '');
    el.setAttribute('href', `qbscroll:${els.length}`);
    els.push(el);
  };
  const scrolls = (overflow, scroll, client) =>
    /auto|scroll|overlay/.test(overflow) && scroll > client + 1;

  // The page root scrolls with overflow: visible, so it's checked on its own
  const root = document.scrollingElement;
  if (root && root.scrollHeight > root.clientHeight) mark(root);
  const walk = parent => parent.querySelectorAll('*').forEach(el => {
    if (el.shadowRoot) walk(el.shadowRoot);
    if (el === root || el.hasAttribute('href')) return;
    if (el.tagName === 'IFRAME' || el.tagName === 'FRAME') return mark(el);
    const style = getComputedStyle(el);
    if (scrolls(style.overflowY, el.scrollHeight, el.clientHeight) ||
        scrolls(style.overflowX, el.scrollWidth, el.clientWidth)) mark(el);
  });
  walk(document);
  window.qbScroll = els;

  window.qbScrollFocus = url => {
    const el = els[Number(url.split(':')[1])];
    unmark(els);
    window.qbScroll = [];
    if (!el) return;
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
