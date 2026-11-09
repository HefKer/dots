// ==UserScript==
// @name         osugacha-gc
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Force a garbage collection on osugacha.com every 20s, which QtWebEngine's Blink skips until the tab runs out of memory.
// @match        *://osugacha.com/*
// @match        *://*.osugacha.com/*
// @run-at       document-end
// @grant        none
// @license      MIT
// ==/UserScript==

// In QtWebEngine 6.140 (Chromium 140) Blink's GC heap fills with garbage while packs open,
// ~80 MB/s, and nothing collects it: one forced GC took the renderer from 1.7 GB to 350 MB
// (dots-issues#19). gc() exists only with qt.args js-flags=--expose-gc (config.py).
// Touches only browser memory, nothing on the site.

(function () {
  'use strict';
  if (typeof gc !== 'function') return;
  setInterval(() => {
    if (!document.hidden) gc();
  }, 20000);
})();
