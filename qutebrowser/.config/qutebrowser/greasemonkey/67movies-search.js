// ==UserScript==
// @name         67movies-search
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Make 67movies.st searchable from a URL: /?q=term opens its search box with term typed in.
// @match        *://67movies.st/?*
// @run-at       document-idle
// @grant        none
// @license      MIT
// ==/UserScript==

// The site's search lives in client state, with no URL of its own: the
// /search?q= it advertises in its metadata is a 404, and the page ignores query
// parameters. This is what lets the "67" search engine work. React tracks the
// input's value, so the text goes through the native setter and an input event.

(function () {
  'use strict';

  const term = new URLSearchParams(location.search).get('q');
  if (!term) return;

  const setValue = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;

  const run = () => {
    const input = document.querySelector('input[placeholder^="Search"]');
    if (input) {
      observer.disconnect();
      setValue.call(input, term);
      input.dispatchEvent(new Event('input', { bubbles: true }));
      return;
    }
    document.querySelector('button[title^="Search"]')?.click();
  };

  const observer = new MutationObserver(run);
  observer.observe(document.body, { childList: true, subtree: true });
  run();
})();
