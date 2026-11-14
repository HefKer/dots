// Step the number at or after the caret in the focused text field, vim's
// Ctrl-A/Ctrl-X: (step) => status message. binds.py wraps this in a call.
// The edit goes through execCommand('insertText'), so it lands on the field's
// undo stack and fires a real input event that frameworks (React etc.) see.
// Its lines get joined into one, so comments must sit on lines of their own.
(step) => {
  const el = document.activeElement;
  if (!el) return 'no field';
  if (el.type === 'number') {
    el.value = String((parseFloat(el.value) || 0) + step);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
    return el.value;
  }
  const editable = el.isContentEditable;
  if (!editable && typeof el.selectionStart !== 'number') return 'no text field';

  let text, caret, node;
  if (editable) {
    const sel = getSelection();
    node = sel.focusNode;
    if (!node || node.nodeType !== Node.TEXT_NODE) return 'no number';
    text = node.data;
    caret = sel.focusOffset;
  } else {
    text = el.value;
    caret = el.selectionStart;
  }

  // like vim: the number the caret touches, else the next one on the line
  const lineStart = text.lastIndexOf('\n', caret - 1) + 1;
  let lineEnd = text.indexOf('\n', caret);
  if (lineEnd < 0) lineEnd = text.length;
  const re = /-?\d+/g;
  re.lastIndex = lineStart;
  let m;
  while ((m = re.exec(text)) && m.index < lineEnd) {
    if (m.index + m[0].length >= caret) break;
  }
  if (!m || m.index >= lineEnd) return 'no number';

  let start = m.index;
  let digits = m[0];
  // a '-' glued to a word (foo-3) is a separator, not a sign
  if (digits[0] === '-' && start > 0 && /\w/.test(text[start - 1])) {
    start += 1;
    digits = digits.slice(1);
  }
  const negative = digits[0] === '-';
  const width = digits.length - (negative ? 1 : 0);
  const next = BigInt(digits) + BigInt(step);
  const abs = (next < 0n ? -next : next).toString();
  // keep zero padding (007 -> 008)
  const padded = digits[negative ? 1 : 0] === '0' && width > 1 ? abs.padStart(width, '0') : abs;
  const out = (next < 0n ? '-' : '') + padded;
  const end = start + digits.length;

  if (editable) {
    const range = document.createRange();
    range.setStart(node, start);
    range.setEnd(node, end);
    const sel = getSelection();
    sel.removeAllRanges();
    sel.addRange(range);
  } else {
    el.setSelectionRange(start, end);
  }
  // leaves the caret just after the new number, so repeats keep hitting it
  document.execCommand('insertText', false, out);
  return out;
}
