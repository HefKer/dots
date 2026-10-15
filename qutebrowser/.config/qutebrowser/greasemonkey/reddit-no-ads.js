// ==UserScript==
// @name         reddit-no-ads
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Hide Reddit's promoted posts and ad slots with CSS only, on new (shreddit) and old reddit.
// @match        *://*.reddit.com/*
// @run-at       document-start
// @grant        none
// @license      MIT
// ==/UserScript==

// qutebrowser's adblock applies only the network rules of the lists in privacy.py, not their
// cosmetic (##) rules, and reddit serves its ads first-party, so they need hiding here.
// Selectors adapted from uBlock Origin's reddit.com rules in uAssets filters.txt (Oct 2026);
// `:upward()` rules have no CSS equivalent and are approximated with :has().

(function () {
  'use strict';

  const selectors = [
    // new reddit (shreddit): feed, comments page, sidebar
    'shreddit-ad-post',
    'shreddit-comments-page-ad',
    '[data-faceplate-tracking-context*="\\"promoted\\":true"]',
    'div[data-before-content="advertisement"]',
    'div[class][data-before-content="Werbung"]:not([id])',
    // the sidebar ad's wrapper, otherwise it leaves an empty card
    'aside div:has(> div[id*="sidebar"][data-before-content="advertisement"])',

    // older redesign
    '.size-compact.Post:has([class*="promoted"])',

    // old reddit
    '.promotedlink:not([style^="height: 1px;"])',
    '.native-ad-container',
  ];

  function addStyle() {
    const style = document.createElement('style');
    style.id = 'reddit-no-ads';
    style.textContent = selectors.join(',\n') + ' { display: none !important; }';
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
