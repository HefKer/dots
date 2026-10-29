// ==UserScript==
// @name         youtube-timestamp
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Keep the watch page's URL at the playback position (t=123s), so a saved session or yanked URL resumes there.
// @match        *://www.youtube.com/*
// @grant        none
// @license      MIT
// ==/UserScript==

(function () {
  'use strict';

  // Playback seconds between URL updates; pausing and seeking update at once.
  const EVERY = 5;
  // Closer to the start than this, the URL drops t= instead.
  const MIN = 5;

  // Only once this video has played, so the 0 the player reports while a
  // restored t= is still being applied doesn't overwrite it.
  let playedId = null;
  let last = -Infinity;

  function update(force) {
    if (location.pathname !== '/watch') return;
    const player = document.getElementById('movie_player');
    if (!player || typeof player.getCurrentTime !== 'function') return;
    // During an ad the player's time is the ad's.
    if (player.classList.contains('ad-showing')) return;

    const url = new URL(location.href);
    const id = url.searchParams.get('v');
    // Right after SPA navigation the player can still hold the previous video.
    if (!id || player.getVideoData?.().video_id !== id) return;
    if (player.getPlayerState?.() === 1) playedId = id; // 1: playing
    if (playedId !== id) return;

    const t = Math.floor(player.getCurrentTime());
    if (!force && Math.abs(t - last) < EVERY) return;
    last = t;

    if (t < MIN) url.searchParams.delete('t');
    else url.searchParams.set('t', `${t}s`);
    // replaceState, not a navigation: no new history entry, and qutebrowser
    // only records global history on a page load, so completion stays clean.
    if (url.href !== location.href) history.replaceState(history.state, '', url.href);
  }

  // Media events don't bubble, but capture on document catches every <video>.
  document.addEventListener('timeupdate', (e) => e.target.tagName === 'VIDEO' && update(false), true);
  for (const type of ['playing', 'pause', 'seeked']) {
    document.addEventListener(type, (e) => e.target.tagName === 'VIDEO' && update(true), true);
  }
})();
