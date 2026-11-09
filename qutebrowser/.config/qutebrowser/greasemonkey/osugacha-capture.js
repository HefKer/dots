// ==UserScript==
// @name         osugacha-capture
// @namespace    https://github.com/HefKer/osugacha
// @version      1.0.0
// @description  Passively copy the game API responses your own browsing receives (map drop tables, map boards, banner) to the local osug dashboard. Read-only: no requests to the site, no clicks.
// @match        https://osugacha.com/*
// @match        https://www.osugacha.com/*
// @run-at       document-start
// @grant        none
// @qute-js-world main
// @license      MIT
// ==/UserScript==

// ADR 0003 (docs/adr/0003-passive-capture-userscript.md). Wraps fetch and XHR; when the page itself gets a 200 from a
// recognised endpoint, POSTs {url, body, captured_at} to http://127.0.0.1:PORT/api/capture (`osug dashboard`). Never sends headers or
// cookies, never requests anything from osugacha.com, never touches the DOM. Keep PATHS in step with har.ENDPOINTS.

(function () {
  'use strict';
  const PORT = 7271; // `osug dashboard --port`
  const SINK = `http://127.0.0.1:${PORT}/api/capture`;
  const PATHS = [/^\/api\/farm$/, /^\/api\/farm\/board\/[^/]+\/\d+$/, /^\/api\/banner$/];
  const RETRY_MS = 60000;
  const MAX_PENDING = 20;

  const realFetch = window.fetch.bind(window);
  const pending = []; // captures the dashboard didn't take yet (not running): retried, newest MAX_PENDING kept

  function wanted(url, method) {
    if ((method || 'GET').toUpperCase() !== 'GET') return null;
    try {
      const u = new URL(url, location.href);
      return u.origin === location.origin && PATHS.some((p) => p.test(u.pathname)) ? u.href : null;
    } catch (e) {
      return null;
    }
  }

  async function post(item) {
    const r = await realFetch(SINK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item),
      credentials: 'omit',
      referrerPolicy: 'no-referrer',
    });
    if (r.status >= 500) throw new Error(`dashboard ${r.status}`);
    if (!r.ok) console.warn('[osugacha-capture] rejected', r.status, await r.text());
  }

  let flushing = false;
  async function flush() {
    if (flushing) return;
    flushing = true;
    try {
      while (pending.length) {
        await post(pending[0]); // throws while the dashboard is down: the rest wait for the next try
        pending.shift();
      }
    } catch (e) {
      /* retried by the interval or the next capture */
    } finally {
      flushing = false;
    }
  }

  function send(url, body) {
    pending.push({ url, body, captured_at: new Date().toISOString() });
    if (pending.length > MAX_PENDING) pending.splice(0, pending.length - MAX_PENDING);
    flush();
  }
  setInterval(() => pending.length && flush(), RETRY_MS);

  window.fetch = function (input, init) {
    const p = realFetch(input, init);
    try {
      const url = typeof input === 'string' || input instanceof URL ? String(input) : input.url;
      const method = (init && init.method) || (input instanceof Request ? input.method : 'GET');
      const hit = wanted(url, method);
      if (hit) {
        p.then((res) => {
          if (res.status === 200) res.clone().json().then((body) => send(hit, body), () => {});
        }, () => {});
      }
    } catch (e) {
      /* never break the page's fetch */
    }
    return p;
  };

  const open = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    const hit = wanted(String(url), method);
    if (hit) {
      this.addEventListener('load', () => {
        if (this.status !== 200) return;
        try {
          send(hit, this.responseType === 'json' ? this.response : JSON.parse(this.responseText));
        } catch (e) {
          /* not JSON */
        }
      });
    }
    return open.apply(this, arguments);
  };
})();
