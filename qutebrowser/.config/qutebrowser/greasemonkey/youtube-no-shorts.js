// ==UserScript==
// @name         youtube-no-shorts
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Hide YouTube Shorts with CSS only and redirect /shorts/<id> to the regular watch page.
// @match        *://*.youtube.com/*
// @exclude      *://accounts.youtube.com/*
// @run-at       document-start
// @grant        none
// @license      MIT
// ==/UserScript==

// Selector list adapted from "YouTube No-Shorts" by dogchild, https://greasyfork.org/scripts/547285 (MIT).
// /shorts/ -> /watch redirect idea from https://greasyfork.org/scripts/534013

(function () {
  'use strict';

  const selectors = [
    // shorts in desktop feeds, search, channel grids, playlists, watch-next
    'ytd-rich-grid-media:has(a[href*="/shorts/"])',
    'ytd-video-renderer:has(a[href*="/shorts/"])',
    'ytd-grid-video-renderer:has(a[href*="/shorts/"])',
    'ytd-rich-item-renderer:has(a[href*="/shorts/"])',
    'ytd-compact-video-renderer:has(a[href*="/shorts/"])',
    'ytd-playlist-video-renderer:has(a[href*="/shorts/"])',

    // shorts shelves, old and new
    'grid-shelf-view-model:has(ytm-shorts-lockup-view-model)',
    'grid-shelf-view-model:has(ytm-shorts-lockup-view-model-v2)',
    'ytd-reel-shelf-renderer',
    'ytd-rich-shelf-renderer[is-shorts]',
    // the home-feed section wrapping a shorts shelf, otherwise it leaves an empty gap
    'ytd-rich-section-renderer:has(> #content > ytd-rich-shelf-renderer[is-shorts])',

    // entry points; guide titles are localized, so these only match an english ui
    'ytd-guide-entry-renderer:has(> a#endpoint[title="Shorts"])',
    'ytd-mini-guide-entry-renderer[aria-label="Shorts"]',
    'yt-tab-shape[tab-title="Shorts"]',

    // mobile (m.youtube.com)
    'ytm-rich-item-renderer:has(a[href*="/shorts/"])',
    'ytm-compact-video-renderer:has(a[href*="/shorts/"])',
    'ytm-video-renderer:has(a[href*="/shorts/"])',
    'ytm-shorts-lockup-view-model',
    'ytm-shorts-lockup-view-model-v2',
    'ytm-reel-shelf-renderer',
    'ytm-shelf-renderer:has([href*="/shorts/"])',
    'ytm-rich-shelf-renderer:has([href*="/shorts/"])',
    // bottom pivot bar tab; its icon wrapper carries a pivot-shorts class
    'ytm-pivot-bar-item-renderer:has(.pivot-shorts)',
  ];

  const shortsPath = /^\/shorts\/([\w-]+)/;

  // /shorts/ID?foo=1 -> /watch?v=ID&foo=1, keeping the hash
  function watchUrl(href) {
    let url;
    try {
      url = new URL(href, location.href);
    } catch (e) {
      return null;
    }
    const m = url.pathname.match(shortsPath);
    if (!m) return null;
    const params = new URLSearchParams(url.search);
    params.delete('v');
    url.pathname = '/watch';
    url.search = '?' + new URLSearchParams([['v', m[1]], ...params]).toString();
    return url.href;
  }

  function redirect(href) {
    const target = watchUrl(href);
    if (target) location.replace(target);
    return !!target;
  }

  if (redirect(location.href)) return;

  function addStyle() {
    const style = document.createElement('style');
    style.id = 'youtube-no-shorts';
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

  // scripts only run on full loads, so catch spa navigation into /shorts/.
  // navigate-start carries the target url, letting us bail before the shorts player loads.
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
