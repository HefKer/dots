// ==UserScript==
// @name         youtube-quality
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Set YouTube playback quality to 1080p, or the highest available below it.
// @match        *://*.youtube.com/*
// @match        *://*.youtube-nocookie.com/embed/*
// @exclude      *://accounts.youtube.com/*
// @exclude      *://music.youtube.com/*
// @run-at       document-start
// @grant        none
// @license      MIT
// ==/UserScript==

(function () {
  'use strict';

  // Best first. The target is the first entry; anything above it is never picked.
  const ladder = ['hd1080', 'hd720', 'large', 'medium', 'small', 'tiny'];

  // Applied once per video, so a manual change in the gear menu sticks.
  let doneFor = null;

  function apply() {
    const player = document.getElementById('movie_player');
    if (!player || typeof player.getAvailableQualityLevels !== 'function') return;

    const id = player.getVideoData?.().video_id;
    if (!id || id === doneFor) return;

    // Empty until the stream manifest has loaded; a later media event retries.
    const levels = player.getAvailableQualityLevels();
    if (!levels.length) return;

    const quality = ladder.find((q) => levels.includes(q));
    if (!quality) return;

    player.setPlaybackQualityRange?.(quality, quality);
    player.setPlaybackQuality?.(quality);
    doneFor = id;
  }

  // Media events don't bubble, but capture on document catches every <video>.
  for (const type of ['loadedmetadata', 'canplay', 'playing']) {
    document.addEventListener(type, apply, true);
  }
  // SPA navigation between videos.
  document.addEventListener('yt-navigate-finish', apply);
})();
