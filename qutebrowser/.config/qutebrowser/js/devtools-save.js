// ==UserScript==
// @name    devtools-save
// @include devtools://*
// @run-at  document-end
// ==/UserScript==

// QtWebEngine compiles DevTools' file saving out (DevToolsUIBindings::SaveToFile is a no-op),
// so Export HAR, Save as and the like do nothing. Hand the file to the page as a download
// instead, which lands on qutebrowser's download prompt. Streamed saves (HAR, console logs)
// open with empty content, append chunks and then close; anything else arrives whole.
(() => {
  const host = window.InspectorFrontendHost;
  if (!host || typeof DevToolsAPI === "undefined") return;
  const pending = new Map();

  const download = (url, parts) => {
    let name = url;
    try {
      name = new URL(url).pathname;
    } catch {}
    name = name.split("/").filter(Boolean).pop() || "devtools-save";
    const a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob(parts));
    a.download = name;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 60_000);
  };

  host.save = (url, content, forceSaveAs, isBase64) => {
    const data = isBase64 ? Uint8Array.from(atob(content), (c) => c.charCodeAt(0)) : content;
    if (data.length) {
      pending.delete(url);
      download(url, [data]);
    } else {
      pending.set(url, []);
    }
    DevToolsAPI.savedURL(url, url);
  };

  host.append = (url, content) => {
    pending.get(url)?.push(content);
    DevToolsAPI.appendedToURL(url);
  };

  host.close = (url) => {
    const parts = pending.get(url);
    pending.delete(url);
    if (parts) download(url, parts);
  };
})();
