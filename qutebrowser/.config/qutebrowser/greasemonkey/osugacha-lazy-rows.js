// ==UserScript==
// @name         osugacha-lazy-rows
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Let the browser skip layout and paint of off-screen trade rows on osugacha.com, so a long trade list loads without freezing.
// @match        *://osugacha.com/*
// @match        *://*.osugacha.com/*
// @run-at       document-start
// @grant        none
// @license      MIT
// ==/UserScript==

// /trades draws every trade at once: 300 rows of card thumbnails, ~130k DOM nodes, and
// QtWebEngine 6.140 spent 6.6s in layout loading it, with a 3.6s freeze. content-visibility: auto
// lays out only the rows near the screen; the page looks the same. CSS only: the site bans automation.

(function () {
  'use strict';

  const CSS = '.trd-row { content-visibility: auto; contain-intrinsic-size: auto 84px; }';

  function addStyle() {
    const style = document.createElement('style');
    style.id = 'osugacha-lazy-rows';
    style.textContent = CSS;
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
