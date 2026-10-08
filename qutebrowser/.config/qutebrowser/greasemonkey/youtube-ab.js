// ==UserScript==
// @name         youtube-ab
// @namespace    https://github.com/urtzienriquez/config_files
// @version      1.0.0
// @author       Urtzi Enriquez-Urzelai
// @description  Fallback for youtube-prune.js: hide page ads, skip any video ad that gets through, remove anti-adblock popups. Based on iamfugui/youtube-adb 6.21 (MIT).
// @match        *://*.youtube.com/*
// @exclude      *://accounts.youtube.com/*
// @exclude      *://www.youtube.com/live_chat_replay*
// @exclude      *://www.youtube.com/persist_identity*
// @grant        none
// @license      MIT
// ==/UserScript==

// Vendored unmodified from https://github.com/urtzienriquez/config_files/blob/e31b2f8215d9749fd9a8b689bb23d21604a5cf8c/qutebrowser/greasemonkey/youtube-ab.js
// Latest: https://github.com/urtzienriquez/config_files/tree/main/qutebrowser/greasemonkey

(function () {
  'use strict';

  let video;
  let adState = null; // user's muted/playbackRate, saved while an ad is skipped

  const adSelectors = [
    '#masthead-ad',
    'ytd-rich-item-renderer.style-scope.ytd-rich-grid-row #content:has(.ytd-display-ad-renderer)',
    '.video-ads.ytp-ad-module',
    'tp-yt-paper-dialog:has(yt-mealbar-promo-renderer)',
    'ytd-engagement-panel-section-list-renderer[target-id="engagement-panel-ads"]',
    '#related #player-ads',
    '#related ytd-ad-slot-renderer',
    'ytd-ad-slot-renderer',
    'yt-mealbar-promo-renderer',
    'ytd-popup-container:has(a[href="/premium"])',
    'ad-slot-renderer',
    'ytm-companion-ad-renderer',
  ];

  function addAdStyle() {
    const style = document.createElement('style');
    style.textContent = adSelectors.map((s) => `${s}{display:none!important}`).join(' ');
    (document.head || document.body).appendChild(style);
  }

  // tap for m.youtube.com, where click() doesn't trigger the skip button
  function nativeTouch(target) {
    const touch = new Touch({ identifier: Date.now(), target, clientX: 12, clientY: 34 });
    const opts = { bubbles: true, cancelable: true, view: window, changedTouches: [touch] };
    target.dispatchEvent(new TouchEvent('touchstart', { ...opts, touches: [touch], targetTouches: [touch] }));
    target.dispatchEvent(new TouchEvent('touchend', { ...opts, touches: [], targetTouches: [] }));
  }

  function getVideo() {
    video = document.querySelector('.ad-showing video') || document.querySelector('video');
  }

  function playAfterAd() {
    if (video && video.paused && video.currentTime < 1) video.play();
  }

  // remove the premium popup and its dimming backdrop
  function closeOverlay() {
    document.querySelectorAll('ytd-popup-container').forEach((c) => {
      if (c.querySelector('a[href="/premium"]')) c.remove();
    });
    const backdrop = [...document.querySelectorAll('tp-yt-iron-overlay-backdrop')].find(
      (b) => b.style.zIndex === '2201',
    );
    if (backdrop) {
      backdrop.className = '';
      backdrop.removeAttribute('opened');
    }
  }

  function skipAd() {
    if (!video) return;
    const skipButton = document.querySelector(
      '.ytp-ad-skip-button, .ytp-skip-ad-button, .ytp-ad-skip-button-modern',
    );
    const adOverlay = document.querySelector(
      '.video-ads.ytp-ad-module .ytp-ad-player-overlay, .ytp-ad-button-icon',
    );
    const isAd = skipButton || adOverlay || document.querySelector('.ad-showing');

    if (isAd) {
      if (!adState) adState = { muted: video.muted, rate: video.playbackRate };
      // muting breaks playback on m.youtube.com
      if (!location.href.startsWith('https://m.youtube.com/')) video.muted = true;
      video.playbackRate = 16;
      // server-stitched (SSAP) ads share the stream with the video, so seeking
      // to the end would skip the video too; youtube-prune.js handles those
      const player = document.getElementById('movie_player');
      const stats = player && player.getStatsForNerds && player.getStatsForNerds();
      const ssap = stats && String(stats.debug_info).startsWith('SSAP');
      if (!ssap && isFinite(video.duration)) video.currentTime = video.duration;
    } else if (adState) {
      video.muted = adState.muted;
      video.playbackRate = adState.rate;
      adState = null;
    }

    if (skipButton) {
      skipButton.click();
      nativeTouch(skipButton);
    }
  }

  function watchPlayer() {
    new MutationObserver(() => {
      getVideo();
      closeOverlay();
      skipAd();
      playAfterAd();
    }).observe(document.body, { childList: true, subtree: true });

    // `.ad-showing` is a class change the observer above misses; media events
    // (captured, since they don't bubble) fire as soon as an ad loads or plays
    for (const type of ['loadedmetadata', 'playing', 'timeupdate']) {
      document.addEventListener(
        type,
        (e) => {
          if (e.target.tagName !== 'VIDEO') return;
          video = e.target;
          skipAd();
        },
        true,
      );
    }
  }

  function main() {
    if (document.getElementById('youtube-adb-running')) return;
    const flag = document.createElement('style');
    flag.id = 'youtube-adb-running';
    (document.head || document.body).appendChild(flag);
    addAdStyle();
    watchPlayer();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', main);
  } else {
    main();
  }

  // anti-adblock enforcement popup: remove it and its backdrop, resume playback
  function resumeVideo() {
    const v = document.querySelector('video.html5-main-video');
    if (v && v.paused) v.play();
  }

  function removePopup(node) {
    const popup = node.querySelector(
      '.ytd-popup-container > .ytd-popup-container > .ytd-enforcement-message-view-model',
    );
    if (popup) {
      popup.parentNode.remove();
      for (const b of [...document.getElementsByTagName('tp-yt-iron-overlay-backdrop')]) b.remove();
      resumeVideo();
    }
    if (node.tagName.toLowerCase() === 'tp-yt-iron-overlay-backdrop') {
      node.remove();
      resumeVideo();
    }
  }

  new MutationObserver((mutations) => {
    for (const m of mutations) {
      for (const node of m.addedNodes) {
        if (node.nodeType === 1) removePopup(node);
      }
    }
  }).observe(document.body, { childList: true, subtree: true });
})();
