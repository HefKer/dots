// ==UserScript==
// @name         no-save-file-picker
// @namespace    https://github.com/hefker/dots
// @version      1.0.0
// @description  Hide showSaveFilePicker so sites save through a normal, named download, as they do in Firefox.
// @match        *://*/*
// @run-at       document-start
// @grant        none
// @qute-js-world main
// @license      MIT
// ==/UserScript==

// qutebrowser has no support for QtWebEngine's save mode, so this API lands on a bare file dialog
// instead of its download prompt. Firefox has no such API, which sends sites to their <a download>
// fallback, and that one gets the site's filename.
delete window.showSaveFilePicker;
