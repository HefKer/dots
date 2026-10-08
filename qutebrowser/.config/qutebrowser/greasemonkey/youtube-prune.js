// ==UserScript==
// @name         youtube-prune
// @namespace    https://github.com/urtzienriquez/config_files
// @version      1.0.0
// @author       Urtzi Enriquez-Urzelai
// @description  Block YouTube ads before they load: a port of uBlock Origin's youtube.com filters (uAssets filters.txt + quick-fixes.txt, Sept 2026) for qutebrowser.
// @license      GPL-3.0-or-later
// @match        *://*.youtube.com/*
// @exclude      *://accounts.youtube.com/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

// Vendored unmodified from https://github.com/urtzienriquez/config_files/blob/e31b2f8215d9749fd9a8b689bb23d21604a5cf8c/qutebrowser/greasemonkey/youtube-prune.js
// Latest: https://github.com/urtzienriquez/config_files/tree/main/qutebrowser/greasemonkey

(function () {
  'use strict';

  // qutebrowser's `window` is a proxy; patch the real page globals
  const win = typeof unsafeWindow !== 'undefined' ? unsafeWindow : window;

  // originals, so our own hooks don't recurse
  const parse = win.JSON.parse.bind(win.JSON);
  const stringify = win.JSON.stringify.bind(win.JSON);

  // Proxy keeps a native-looking toString
  function hook(obj, name, apply) {
    const orig = obj[name];
    if (typeof orig !== 'function') return;
    obj[name] = new Proxy(orig, { apply });
  }

  function requestUrl(input) {
    if (typeof input === 'string') return input;
    if (input instanceof win.Request) return input.url;
    return input ? String(input) : '';
  }

  // --- ad data in player responses ---
  const AD_KEYS = ['adPlacements', 'adSlots'];

  function pruneAds(obj) {
    if (!obj || typeof obj !== 'object') return false;
    let changed = false;
    const strip = (t) => {
      if (!t || typeof t !== 'object') return;
      for (const k of AD_KEYS) {
        if (k in t) {
          delete t[k];
          changed = true;
        }
      }
    };
    if (Array.isArray(obj)) {
      for (const item of obj) strip(item && item.playerResponse);
    } else {
      strip(obj);
      strip(obj.playerResponse);
    }
    return changed;
  }

  function renameAdKeys(text) {
    return text.replace(/"adPlacements"/g, '"no_ads"').replace(/"adSlots"/g, '"no_ads"');
  }

  function stripXhrAds(text, url) {
    if (/playlist\?list=|\/player(?:\?.+)?$|watch\?[tv]=/.test(url)) {
      text = text.replace(/"adPlacements.*?([A-Z]"\}|"\}{2,4})\}\],/, '');
    }
    if (/\/player(?:\?.+)?$/.test(url)) {
      text = text.replace(/"adPlacements.*?("adSlots"|"adBreakHeartbeatParams")/gms, '$1');
    }
    return text;
  }

  const FETCH_URL = /\/player\?|\/playlist\?|\/get_watch\?/;
  hook(win, 'fetch', (target, thisArg, args) => {
    const promise = Reflect.apply(target, thisArg, args);
    if (!FETCH_URL.test(requestUrl(args[0]))) return promise;
    return promise
      .then((before) =>
        before.clone().text().then((text) => {
          let after = text;
          try {
            const obj = parse(text);
            if (obj && typeof obj === 'object' && pruneAds(obj)) after = stringify(obj);
          } catch (e) {}
          after = renameAdKeys(after);
          if (after === text) return before;
          const response = new win.Response(after, {
            status: before.status,
            statusText: before.statusText,
            headers: before.headers,
          });
          Object.defineProperties(response, {
            ok: { value: before.ok },
            redirected: { value: before.redirected },
            type: { value: before.type },
            url: { value: before.url },
          });
          return response;
        }),
      )
      .catch(() => promise);
  });

  const XHR_URL = /\/player(?:\?.+)?$|playlist\?list=|watch\?[tv]=/;
  const xhrUrls = new WeakMap();
  const xhrCache = new WeakMap();
  const XHR = win.XMLHttpRequest;
  const respGet = Object.getOwnPropertyDescriptor(XHR.prototype, 'response').get;
  const textGet = Object.getOwnPropertyDescriptor(XHR.prototype, 'responseText').get;
  hook(XHR.prototype, 'open', (target, thisArg, args) => {
    const url = String(args[1]);
    if (XHR_URL.test(url)) xhrUrls.set(thisArg, url);
    else xhrUrls.delete(thisArg);
    xhrCache.delete(thisArg);
    return Reflect.apply(target, thisArg, args);
  });
  function xhrFiltered(xhr, inner) {
    const url = xhrUrls.get(xhr);
    if (url === undefined || xhr.readyState !== 4) return inner;
    const cached = xhrCache.get(xhr);
    if (cached && cached.inner === inner) return cached.outer;
    let outer = inner;
    if (typeof inner === 'string') {
      outer = stripXhrAds(inner, url);
      try {
        const obj = parse(outer);
        if (obj && typeof obj === 'object' && pruneAds(obj)) outer = stringify(obj);
      } catch (e) {}
    } else if (inner && typeof inner === 'object') {
      pruneAds(inner);
    }
    xhrCache.set(xhr, { inner, outer });
    return outer;
  }
  Object.defineProperty(XHR.prototype, 'response', {
    configurable: true,
    enumerable: true,
    get: function () {
      return xhrFiltered(this, respGet.call(this));
    },
  });
  Object.defineProperty(XHR.prototype, 'responseText', {
    configurable: true,
    enumerable: true,
    get: function () {
      return xhrFiltered(this, textGet.call(this));
    },
  });

  // --- ad data in the initial page ---
  function forceUndefined(obj, keys) {
    if (!obj || typeof obj !== 'object') return obj;
    for (const k of keys) {
      try {
        Object.defineProperty(obj, k, { configurable: true, get: () => undefined, set: () => {} });
      } catch (e) {}
    }
    return obj;
  }
  for (const [name, keys] of [
    ['ytInitialPlayerResponse', ['playerAds', 'adPlacements', 'adSlots']],
    ['playerResponse', ['adPlacements']],
  ]) {
    let value = forceUndefined(win[name], keys);
    try {
      Object.defineProperty(win, name, {
        configurable: true,
        enumerable: true,
        get: () => value,
        set: (v) => {
          value = forceUndefined(v, keys);
        },
      });
    } catch (e) {}
  }

  // --- Shorts ads ---
  hook(win.JSON, 'parse', (target, thisArg, args) => {
    const obj = Reflect.apply(target, thisArg, args);
    if (obj && Array.isArray(obj.entries)) {
      obj.entries = obj.entries.filter(
        (e) => !(e && e.command && e.command.reelWatchEndpoint &&
          e.command.reelWatchEndpoint.adClientParams &&
          e.command.reelWatchEndpoint.adClientParams.isAd),
      );
    }
    return obj;
  });

  // --- /player request rewrite ---
  // When antiSsap tags the userAgent with a strategy, alter the request so the
  // server answers without server-inserted ads.
  function editPlayerRequest(obj) {
    if (!obj || typeof obj !== 'object' || !('attestationRequest' in obj)) return;
    const ua = obj.context && obj.context.client && obj.context.client.userAgent;
    if (typeof ua !== 'string' || !/adunit|channel|lactmilli|instream|inline|yahi|eafg/.test(ua)) return;
    const o = parse(stringify(obj));
    const client = o.context.client;
    const pc = o.playbackContext;
    const cpc = pc && pc.contentPlaybackContext;
    if (ua.includes('channel') && client.clientName === 'WEB') client.clientScreen = 'CHANNEL';
    if (ua.includes('lactmilli')) o.params = '8AUB';
    if (ua.includes('yahi')) o.params = 'YAHI';
    if (ua.includes('instream') && cpc) pc.adPlaybackContext = { adType: 'AD_TYPE_INSTREAM' };
    if (/channel|lactmilli|instream/.test(ua) && cpc) cpc.lactMilliseconds = `${Date.now()}`;
    if (cpc && typeof cpc.referer === 'string') {
      cpc.referer = cpc.referer.replace(/(?:#reloadxhr)?$/, '#reloadxhr');
    }
    return o;
  }
  hook(win.JSON, 'stringify', (target, thisArg, args) => {
    try {
      const edited = editPlayerRequest(args[0]);
      if (edited) args[0] = edited;
    } catch (e) {}
    return Reflect.apply(target, thisArg, args);
  });

  // --- server-inserted (SSAP) ads ---
  // If the server makes the player wait out an ad (stuck buffering, nothing
  // loaded), reload the video with the next strategy. Seek past SSAP ads.
  (function antiSsap() {
    const STRATEGIES = ['channel', 'lactmilli', 'instream', 'yahi'];
    let strategies = STRATEGIES;
    let reloadPending = false;
    let disabled = false;
    let origUA;

    const client = () => {
      const cfg = win.ytcfg && win.ytcfg.data_;
      return cfg && cfg.INNERTUBE_CONTEXT && cfg.INNERTUBE_CONTEXT.client;
    };
    const setStrategy = (tag) => {
      const c = client();
      if (!c || origUA === undefined) return;
      if (tag) {
        const m = typeof origUA === 'string' && origUA.match(/Mozilla\/5\.0 \([^)]+/);
        c.userAgent = m ? origUA.replace(m[0], `${m[0]}; ${tag}`) : origUA;
      } else {
        c.userAgent = origUA;
      }
    };
    const state = () => {
      const player = document.getElementById('movie_player');
      const call = (fn) => (player && typeof player[fn] === 'function' ? player[fn]() : undefined);
      const stateObj = call('getPlayerStateObject');
      return {
        player,
        response: call('getPlayerResponse'),
        stats: call('getStatsForNerds'),
        progress: call('getProgressState'),
        buffering: stateObj && stateObj.isBuffering,
      };
    };
    const stuck = (buffering, stats) =>
      buffering && stats && stats.buffer_health_seconds === '0.00 s' &&
      stats.resolution === '0x0' && strategies.length > 0;

    const onBackoff = () => {
      if (disabled) return;
      const { player, response, stats, buffering } = state();
      if (!player || !stuck(buffering, stats)) return;
      const url = response && response.playbackTracking &&
        response.playbackTracking.videostatsPlaybackUrl &&
        response.playbackTracking.videostatsPlaybackUrl.baseUrl;
      if (typeof url === 'string' && url.includes('reloadxhr')) strategies = strategies.slice(1);
      reloadPending = true;
    };

    const check = () => {
      if (disabled) return;
      const { player, response, stats, progress, buffering } = state();
      if (!player || !location.href.includes('/watch?')) {
        strategies = STRATEGIES;
        return;
      }
      const playing = (progress && progress.duration > 0 &&
        (progress.loaded < progress.duration || progress.duration - progress.current > 1)) ||
        (response && response.videoDetails && response.videoDetails.isLive);
      if (!playing) return;
      const debugInfo = stats && stats.debug_info;
      if (typeof debugInfo === 'string' && debugInfo.startsWith('SSAP, AD')) {
        if (progress && progress.duration > 0 && player.seekTo) player.seekTo(progress.duration);
        return;
      }
      if (!response) return;
      const videoId = response.videoDetails && response.videoDetails.videoId;
      const start = (response.playerConfig && response.playerConfig.playbackStartConfig &&
        response.playerConfig.playbackStartConfig.startSeconds) || 0;
      const ps = response.playabilityStatus;
      const err = ps && ps.errorScreen;
      const pem = err && err.playerErrorMessageRenderer;
      const runs = stringify(
        (pem && pem.subreason && pem.subreason.runs) ||
        (err && err.playerInterstitialRenderer && err.playerInterstitialRenderer.content &&
          err.playerInterstitialRenderer.content.interstitialViewModel &&
          err.playerInterstitialRenderer.content.interstitialViewModel.description &&
          err.playerInterstitialRenderer.content.interstitialViewModel.description.commandRuns),
      );
      const blocked = ps && ps.status === 'UNPLAYABLE' && !(pem && pem.playerCaptchaViewModel) &&
        typeof runs === 'string' && runs.includes('WEB_PAGE_TYPE_UNKNOWN') &&
        runs.includes('https://support.google.com/youtube/answer/3037019');
      if (blocked) {
        // "ad blockers are not allowed" screen: try the next strategy
        strategies = strategies.slice(1);
        setStrategy(strategies[0] || '');
        reloadPending = false;
        player.loadVideoById(videoId, start);
      } else if (strategies.length === 0) {
        reloadPending = false;
        setStrategy('');
      } else if (reloadPending && stuck(buffering, stats)) {
        setStrategy(strategies[0]);
        reloadPending = false;
        player.loadVideoById(videoId, start);
      } else if (!reloadPending && progress && progress.current - start < 5 &&
        location.href.includes('&list=') && player.getPlaylistId && player.getPlaylistId() === null) {
        // reloading drops the playlist; restore it
        const manager = document.querySelector('yt-playlist-manager');
        const data = manager && manager.getPlaylistData && manager.getPlaylistData();
        if (data) {
          manager.setPlaylistData && manager.setPlaylistData(data);
          manager.setPlayerPlaybackControlData &&
            manager.setPlayerPlaybackControlData({ playlistPanelRenderer: data });
        }
      }
    };

    document.addEventListener('DOMContentLoaded', () => {
      const logo = win.ytInitialData && win.ytInitialData.topbar &&
        win.ytInitialData.topbar.desktopTopbarRenderer &&
        win.ytInitialData.topbar.desktopTopbarRenderer.logo &&
        win.ytInitialData.topbar.desktopTopbarRenderer.logo.topbarLogoRenderer;
      const masthead = document.getElementById('masthead');
      const premium =
        (logo && logo.iconImage && logo.iconImage.iconType === 'YOUTUBE_PREMIUM_LOGO') ||
        (masthead && masthead.getAttribute('logo-type') === 'YOUTUBE_PREMIUM_LOGO');
      if (premium || location.href.startsWith('https://www.youtube.com/tv#/') ||
        location.href.startsWith('https://www.youtube.com/embed/')) {
        disabled = true;
        return;
      }
      const c = client();
      origUA = c && c.userAgent;
      check();
      new MutationObserver(check).observe(document, { childList: true, subtree: true });
    });

    // backoff signals: snackbar lookup, or the 104/105-byte wait response
    hook(win.Map.prototype, 'has', (target, thisArg, args) => {
      if (args[0] === 'onSnackbarMessage' && !reloadPending) onBackoff();
      return Reflect.apply(target, thisArg, args);
    });
    hook(win.Array.prototype, 'push', (target, thisArg, args) => {
      const a = args[0];
      if (a && typeof a === 'object' && a.constructor && a.constructor.name === 'Uint8Array' &&
        a.buffer && a.buffer.byteLength === a.length && (a.length === 105 || a.length === 104)) {
        onBackoff();
      }
      return Reflect.apply(target, thisArg, args);
    });
    // disable the anti-adblock "abnormality detected" handler
    hook(win.Promise.prototype, 'then', (target, thisArg, args) => {
      if (typeof args[0] === 'function' && args[0].toString().includes('onAbnormalityDetected')) {
        args[0] = function () {};
      }
      return Reflect.apply(target, thisArg, args);
    });
  })();

  // --- other anti-adblock countermeasures ---
  // shorten a 17 s anti-adblock wait
  hook(win, 'setTimeout', (target, thisArg, args) => {
    if (args[1] === 17000 && typeof args[0] === 'function' &&
      /\[native code\]/.test(args[0].toString())) {
      args[1] = 17;
    }
    return Reflect.apply(target, thisArg, args);
  });

  // YouTube grabs clean fetch/JSON.parse from a new iframe; give it ours
  hook(win.Node.prototype, 'appendChild', (target, thisArg, args) => {
    const result = Reflect.apply(target, thisArg, args);
    const elem = args[0];
    try {
      const cw = elem instanceof win.HTMLElement && elem.contentWindow;
      if (cw && `${cw}` === '[object Window]' &&
        (cw.location.href === 'about:blank' || cw.location.href === win.location.href)) {
        cw.fetch = win.fetch;
        cw.Request = win.Request;
        cw.JSON.parse = win.JSON.parse;
      }
    } catch (e) {}
    return result;
  });

  // empty the inline script that checks whether fetch was patched
  new MutationObserver((mutations) => {
    for (const m of mutations) {
      for (const node of m.addedNodes) {
        if (node.nodeName === 'SCRIPT' && !node.src && node.textContent.includes('window,"fetch"')) {
          node.textContent = '';
        }
      }
    }
  }).observe(document, { childList: true, subtree: true });

  // --- CSS ---
  const style = document.createElement('style');
  style.textContent = [
    '#masthead-ad',
    'ytd-ad-slot-renderer',
    'ad-slot-renderer',
    'ytd-rich-item-renderer:has(ytd-ad-slot-renderer)',
    '#player-ads',
    'ytd-engagement-panel-section-list-renderer[target-id="engagement-panel-ads"]',
    'yt-mealbar-promo-renderer',
    'ytm-companion-ad-renderer',
    // in-player ad UI (not the skip button, youtube-ab.js clicks it)
    '.ytp-ad-player-overlay',
    '.ytp-ad-player-overlay-layout',
    '.ytp-ad-overlay-container',
    '.ytp-ad-text',
    '.ytp-ad-preview-container',
  ].join(',') + '{display:none!important}' +
    // hide the video and progress bar while an ad shows
    '.ad-showing video,.ad-showing .ytp-chrome-bottom,.ad-showing .ytp-ad-module' +
    '{opacity:0!important}';
  // at document-start the root element may not exist yet
  if (document.documentElement) {
    document.documentElement.appendChild(style);
  } else {
    new MutationObserver((_, observer) => {
      if (!document.documentElement) return;
      observer.disconnect();
      document.documentElement.appendChild(style);
    }).observe(document, { childList: true });
  }
})();
