// Marks for hinting elements no built-in hint group finds. The js-hint
// userscript loads this, then hint-<group>.js, which marks elements with
// qbHint.mark(); then it hints [data-qb-hint=<group>].
//
// The default hint target runs qbHint.pick('{hint-url}'), handing the picked
// element to qbHint.onPick. A `run` hint needs a URL to substitute, so each
// marked element gets href="qbhint:N", N indexing the marks; any href it had
// comes back on reset, along with whatever a group registered via onReset.
// Picking resets, and so does the next run if hinting was cancelled.
window.qbHint?.reset();
window.qbHint = (() => {
  let marks = [];
  let undos = [];
  const reset = () => {
    for (const [el, href] of marks) {
      el.removeAttribute('data-qb-hint');
      if (href === null) el.removeAttribute('href');
      else el.setAttribute('href', href);
    }
    undos.forEach(undo => undo());
    marks = [];
    undos = [];
  };
  return {
    onPick: () => {},
    onReset: undo => undos.push(undo),
    reset,
    mark(el, group) {
      if (el.hasAttribute('data-qb-hint')) return;
      marks.push([el, el.getAttribute('href')]);
      el.setAttribute('data-qb-hint', group);
      el.setAttribute('href', `qbhint:${marks.length - 1}`);
    },
    pick(url) {
      const [el] = marks[Number(url.split(':')[1])] || [];
      reset();
      if (el) this.onPick(el);
    },
  };
})();
