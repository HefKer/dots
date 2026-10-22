// ==UserScript==
// @name         twitch-ffz
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Load FrankerFaceZ on Twitch: 7TV/BTTV/FFZ emotes (via its add-ons), auto-claimed channel points and drops, and chat tweaks.
// @match        *://twitch.tv/*
// @match        *://*.twitch.tv/*
// @exclude      *://api.twitch.tv/*
// @run-at       document-end
// @grant        none
// @license      MIT
// ==/UserScript==

// The ffz_injector part of FFZ's own userscript (https://cdn.frankerfacez.com/static/ffz_injector.user.js),
// without its user-script settings provider: that wants GM.getValues, GM_addValueChangeListener and
// object values from GM.setValue, none of which qutebrowser has, so FFZ keeps settings in localStorage.
// script.min.js picks the right bundle (avalon, player, clips) for the page and skips Twitch's
// non-site subdomains itself.

(function () {
  'use strict';

  const script = document.createElement('script');
  script.id = 'ffz_script';
  script.src = `https://cdn2.frankerfacez.com/script/script.min.js?_=${Date.now()}`;
  document.head.appendChild(script);
})();
