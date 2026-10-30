// ==UserScript==
// @name         ntv-embed
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Stop ntv.st's embed page hijacking the player frame: drop every script but its own loader.
// @match        *://ntv.st/embed*
// @match        *://ntv.cx/embed*
// @run-at       document-start
// @grant        none
// @license      MIT
// ==/UserScript==

// The ad scripts on this page send the whole frame to an ad landing page a few
// seconds in, taking the stream iframe with it. Its host rotates and the scripts
// are inline, so a filter list can't catch them. The observer runs before the
// parser executes each script, so they never start. The loader stays because it
// reveals the iframe, which sits at opacity 0 until then.

(function () {
  'use strict';

  const observer = new MutationObserver((mutations) => {
    for (const { addedNodes } of mutations) {
      for (const node of addedNodes) {
        if (node.nodeName === 'SCRIPT' && !node.textContent.includes('streamIframe')) node.remove();
      }
    }
  });
  observer.observe(document, { childList: true, subtree: true });
})();
