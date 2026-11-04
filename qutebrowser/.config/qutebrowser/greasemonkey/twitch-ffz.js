// ==UserScript==
// @name         twitch-ffz
// @namespace    https://github.com/hefker/dots
// @version      1.1.0
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
// object values from GM.setValue, none of which qutebrowser has, so FFZ keeps settings in its own
// IndexedDB. script.min.js picks the right bundle (avalon, player, clips) for the page and skips
// Twitch's non-site subdomains itself.

(function () {
  'use strict';

  // qutebrowser hands greasemonkey scripts a window proxy; FFZ's globals live on the page's window
  const win = typeof unsafeWindow !== 'undefined' ? unsafeWindow : window;

  // FFZ ships both off and keeps settings per browser profile, so a fresh profile would lose them
  const FORCED = {
    'chat.points.auto-rewards': true, // claim the bonus chest in chat
    'chat.drops.auto-rewards': true, // claim each drop as it completes
  };

  const script = document.createElement('script');
  script.id = 'ffz_script';
  script.src = `https://cdn2.frankerfacez.com/script/script.min.js?_=${Date.now()}`;
  document.head.appendChild(script);

  // FFZ's default profile (id 0) exists once its settings module has loaded the profiles,
  // after the provider reads storage; poll for it rather than hook FFZ's internal events
  let tries = 0;
  const timer = setInterval(() => {
    if (++tries > 120) return clearInterval(timer);
    let profile;
    try {
      const settings = win.FrankerFaceZ?.get()?.resolve('settings');
      profile = settings?.enabled && settings.profile(0);
    } catch {
      return;
    }
    if (!profile) return;
    clearInterval(timer);
    for (const [key, value] of Object.entries(FORCED)) {
      if (profile.get(key) !== value) profile.set(key, value);
    }
  }, 500);
})();
