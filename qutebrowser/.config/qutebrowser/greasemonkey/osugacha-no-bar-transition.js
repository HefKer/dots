// ==UserScript==
// @name         osugacha-no-bar-transition
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Turn off the pack-slot refill bar's width transition on osugacha.com, which leaks renderer memory in QtWebEngine until the tab crashes.
// @match        *://osugacha.com/*
// @match        *://*.osugacha.com/*
// @run-at       document-start
// @grant        none
// @license      MIT
// ==/UserScript==

// The bar restarts a 1s `width` transition every second. In QtWebEngine 6.140 (Chromium 140)
// each one grows Blink's GC heap, ~120 MB/s, and the renderer crashes within a minute or two.
// Without the transition it's ~35-58 MB/s (dots-issues#19). CSS only: the site bans automation.

(function () {
  'use strict';

  function addStyle() {
    const style = document.createElement('style');
    style.id = 'osugacha-no-bar-transition';
    style.textContent = '.slot-progress > i { transition: none !important; }';
    document.documentElement.appendChild(style);
  }

  if (document.documentElement) {
    addStyle();
  } else {
    // documentElement can still be null this early at document-start
    new MutationObserver((_, obs) => {
      if (!document.documentElement) return;
      obs.disconnect();
      addStyle();
    }).observe(document, { childList: true });
  }
})();
