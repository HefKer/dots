// ==UserScript==
// @name         youtube-no-playables
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Hide YouTube Playables (Watch & Play games) with CSS only and send /playables pages back to the home feed.
// @match        *://*.youtube.com/*
// @exclude      *://accounts.youtube.com/*
// @run-at       document-start
// @grant        none
// @license      MIT
// ==/UserScript==

// mini-game-card-view-model from "Hide YouTube Playables Too" by Vivian-Green,
// https://github.com/Vivian-Green/ublock-hide-yt-playables-too; the rest matches on /playables links,
// so it works in any ui language.

(function () {
  'use strict';

  const selectors = [
    // game cards, wherever they show up
    'mini-game-card-view-model',
    'ytd-rich-item-renderer:has(a[href*="/playables/"])',
    'ytd-video-renderer:has(a[href*="/playables/"])',
    'ytd-compact-video-renderer:has(a[href*="/playables/"])',

    // the home-feed playables shelf, header included, otherwise it leaves an empty gap
    'ytd-rich-section-renderer:has(mini-game-card-view-model)',
    'ytd-rich-section-renderer:has(a[href*="/playables"])',
    'grid-shelf-view-model:has(mini-game-card-view-model)',

    // entry points
    'ytd-guide-entry-renderer:has(> a#endpoint[href^="/playables"])',
    'ytd-mini-guide-entry-renderer:has(> a[href^="/playables"])',

    // mobile (m.youtube.com)
    'ytm-rich-item-renderer:has(a[href*="/playables/"])',
    'ytm-rich-section-renderer:has(a[href*="/playables"])',
  ];

  const playablesPath = /^\/playables(\/|$)/;

  function redirect(href) {
    let url;
    try {
      url = new URL(href, location.href);
    } catch (e) {
      return false;
    }
    if (!playablesPath.test(url.pathname)) return false;
    location.replace('/');
    return true;
  }

  if (redirect(location.href)) return;

  function addStyle() {
    const style = document.createElement('style');
    style.id = 'youtube-no-playables';
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

  // scripts only run on full loads, so catch spa navigation into /playables.
  // navigate-start carries the target url, letting us bail before the game loads.
  window.addEventListener('yt-navigate-start', (e) => {
    const d = e.detail || {};
    const href = d.url ||
      (d.endpoint && d.endpoint.commandMetadata &&
        d.endpoint.commandMetadata.webCommandMetadata &&
        d.endpoint.commandMetadata.webCommandMetadata.url);
    if (href) redirect(href);
  });
  // fallbacks once the url has changed: desktop, mobile, back/forward
  for (const ev of ['yt-navigate-finish', 'state-navigateend', 'popstate']) {
    window.addEventListener(ev, () => redirect(location.href));
  }
})();
