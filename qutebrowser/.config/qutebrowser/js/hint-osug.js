// Hint group for osugacha.com's recurring buttons, by their text and the
// current route, followed with a plain `normal` hint click: a real click from
// the user, since the site bans automation. Nothing here clicks; it only marks.
// See hint-marks.js.
//
// A label matches a button whose text is the label, or starts with it followed
// by a non-letter ("Auto ▶", "To the lift (3)"), case and spacing ignored.
//
// Each route lists tiers of labels, first tier first: only the first tier with
// a button on screen is hinted, so a lone one there is clicked straight away.
// A tier entry { css } takes the elements matching a selector instead, for
// buttons with no fixed text (the Depths door tiles).
(() => {
  const ROUTES = {
    '/depths': [['on to elite', 'on to gate', 'on to boss', 'descend', 'to the lift', 'auto',
      'ride up', 'go deeper'],
      [{ css: '.dp-doors .dp-door' }]],
    '/farm': [['auto']],
    '/packs': [['open next', 'reveal all', 'done'], ['open pack']],
    '/tower': [['auto']],
  };
  const route = Object.keys(ROUTES).find(r =>
    location.pathname === r || location.pathname.startsWith(r + '/'));
  if (!route) return;

  const norm = s => s.toLowerCase().replace(/\s+/g, ' ').trim();
  let labels, selectors;
  const matches = text => labels.some(l =>
    text === l || (text.startsWith(l) && !/\p{L}/u.test(text[l.length])));
  const CLICKABLE = 'button, [role=button], a, input[type=button], input[type=submit]';
  // A button never hinted, whatever else it says: --follow-lone clicks a lone
  // hint without a keypress, and these can't be undone
  const NEVER = /sell/;
  const textOf = el => norm(el.value || el.textContent);
  // The innermost element holding the label, so a button's extra text (a key
  // hint, a count in a sibling span) doesn't spoil the match. textContent first,
  // as a cheap filter, then innerText, which leaves out hidden text.
  const holdsLabel = el => matches(textOf(el)) && ![...el.children].some(c => matches(textOf(c))) &&
    matches(norm(el.value || el.innerText || ''));
  // Up to what takes the click: a real button or link, or else the outermost
  // element still showing a pointer cursor (cursor is inherited, so the label's
  // own element shows it too); the label's own element if neither
  const pointer = el => el && el !== document.body && getComputedStyle(el).cursor === 'pointer';
  const target = el => {
    const real = el.closest(CLICKABLE);
    if (real) return real;
    let at = el;
    while (pointer(at.parentElement)) at = at.parentElement;
    return at;
  };

  // What qutebrowser's own hinting counts as visible, so a tier's buttons only
  // count when they would get a hint
  const onScreen = el => {
    const style = getComputedStyle(el);
    const rect = el.getBoundingClientRect();
    return style.visibility === 'visible' && style.display !== 'none' && style.opacity !== '0' &&
      rect.top <= innerHeight && rect.bottom >= 0 && rect.left <= innerWidth && rect.right >= 0 &&
      el.getClientRects().length > 0;
  };

  const add = (el, found) => {
    if (el.disabled || el.getAttribute('aria-disabled') === 'true' || !onScreen(el)) return;
    if (NEVER.test(norm(el.innerText || ''))) return;
    found.add(el);
  };
  const find = (root, found = new Set()) => {
    for (const css of selectors) for (const el of root.querySelectorAll(css)) add(el, found);
    for (const label of root.querySelectorAll('*')) {
      if (label.shadowRoot) find(label.shadowRoot, found);
      if (labels.length && holdsLabel(label)) add(target(label), found);
    }
    return found;
  };

  for (const tier of ROUTES[route]) {
    labels = tier.filter(l => typeof l === 'string');
    selectors = tier.filter(l => l.css).map(l => l.css);
    const found = find(document);
    if (!found.size) continue;
    for (const el of found) {
      qbHint.mark(el, 'osug');
      // Restores an <a>'s own href before its default action reads it
      el.addEventListener('click', () => qbHint.reset(), { once: true, capture: true });
    }
    break;
  }
})();
