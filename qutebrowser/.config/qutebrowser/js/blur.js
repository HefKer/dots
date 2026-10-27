// Blur the focused element, descending into shadow roots, so keys reach the page
// again, e.g. YouTube's arrow seeking after the volume slider grabbed focus.
(() => {
  let el = document.activeElement;
  while (el?.shadowRoot?.activeElement) el = el.shadowRoot.activeElement;
  el?.blur();
})();
