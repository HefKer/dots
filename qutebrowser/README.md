# qutebrowser

My [qutebrowser](https://qutebrowser.org/) config: Everforest, vertical icon-only
tabs, dark mode that leaves already-dark sites alone, and a pile of userscripts
and greasemonkey scripts for the things qutebrowser doesn't do on its own.

![Overview: icon-only tabs on the left, Everforest statusbar](screenshots/overview.png)

| Hints | Completion |
|---|---|
| ![Hint labels over a GitHub page](screenshots/hints.png) | ![The :set completion menu](screenshots/completion.png) |

## Layout

[`config.py`](.config/qutebrowser/config.py) sets general behaviour and
`config.source`s one module per topic:

| File | What it holds |
|---|---|
| [`appearance.py`](.config/qutebrowser/appearance.py) | Theme, left-hand icon-only tabs, dark mode, fonts |
| [`privacy.py`](.config/qutebrowser/privacy.py) | WebRTC, cookies, adblock lists |
| [`binds.py`](.config/qutebrowser/binds.py) | Every keybinding, grouped by prefix |
| [`search_engines.py`](.config/qutebrowser/search_engines.py) | Search engine shortcuts (`:open nix foo`, `:open aw foo`, …) |
| [`filepicker.py`](.config/qutebrowser/filepicker.py) | yazi as the file picker |
| [`printing.py`](.config/qutebrowser/printing.py) | Print-to-PDF fixes |
| [`spotify.py`](.config/qutebrowser/spotify.py) | Hand Spotify links to the desktop app |
| [`injectfix.py`](.config/qutebrowser/injectfix.py) | Workaround for page scripts dying after cross-site navigation |
| [`devtoolssave.py`](.config/qutebrowser/devtoolssave.py) | Lets DevTools save files (Export HAR, Save as) through the download prompt |
| [`tabreuse.py`](.config/qutebrowser/tabreuse.py) | Links to an already open site reuse its tab |
| [`js/`](.config/qutebrowser/js/) | Small scripts the binds run through `jseval` |
| [`greasemonkey/`](.config/qutebrowser/greasemonkey/) | Per-site userscripts |
| [`userscripts/`](.local/share/qutebrowser/userscripts/) | qutebrowser userscripts, linked to `~/.local/share/qutebrowser/userscripts` |

## Worth stealing

Each entry is self-contained enough to copy on its own. Its links point to the
file as it is now and to the commit that added it, which explains why.

### Browsing

- <a id="private-window"></a>**Private window from a prompt.** `gP` prompts for
  a URL or search and opens it in a private window. `gp` reopens the current page
  in one. Private browsing is per-window in qutebrowser, so there are no private
  tabs. [`binds.py`](.config/qutebrowser/binds.py) ·
  [470fcdb](https://github.com/HefKer/dots/commit/470fcdb)
- <a id="dark-mode"></a>**Dark mode that doesn't wreck dark sites.** It asks
  sites for their native dark theme, skips backgrounds that are already dark, and
  inverts logos but not photos. `,uw` toggles dark mode for the whole host and
  works on the first press. [`appearance.py`](.config/qutebrowser/appearance.py) ·
  [5180c1e](https://github.com/HefKer/dots/commit/5180c1e)
- <a id="escape-dialogs"></a>**Escape stubborn dialogs.** `;o` hints overlays,
  modals and backdrops, so you can click out of a popup that ignores Escape.
  [`binds.py`](.config/qutebrowser/binds.py)
- <a id="caret-hints"></a>**Hint a paragraph into caret mode.** `v` hints
  paragraphs, list items and headings and drops the caret at the start of the
  chosen one, Tridactyl-style.
  [`caret-anchor`](.local/share/qutebrowser/userscripts/caret-anchor) ·
  [f5cbd7a](https://github.com/HefKer/dots/commit/f5cbd7a)
- <a id="scrollable-hints"></a>**Focus a scrollable area by hint.** `;s` hints
  scrollable elements and iframes so `j`/`k` scroll the one you pick. With
  exactly two on screen it jumps straight to the other one. `;q` drops focus back
  to the page, for example off YouTube's volume slider.
  [`js-hint`](.local/share/qutebrowser/userscripts/js-hint),
  [`js/hint-scrollable.js`](.config/qutebrowser/js/hint-scrollable.js) ·
  [c22ec3b](https://github.com/HefKer/dots/commit/c22ec3b),
  [ae16efa](https://github.com/HefKer/dots/commit/ae16efa)
- <a id="upload-hints"></a>**Hint hidden file inputs.** `;u` hints every file
  input, including the hidden ones behind drag-and-drop zones, and opens the
  picker with a real click. [`js/hint-upload.js`](.config/qutebrowser/js/hint-upload.js) ·
  [9fe8f48](https://github.com/HefKer/dots/commit/9fe8f48)
- <a id="download-file"></a>**Downloads filed by a decision model.** `edf`
  takes the newest file in `~/Downloads` and asks
  [Jev](https://docs.typesafe.ai/llms.txt) which directory it belongs in, going
  by its name, the page it came from and what each directory already holds. A
  menu lists the directories likeliest first, so Enter accepts the guess and
  any other row overrides it.
  [`download-file`](.local/share/qutebrowser/userscripts/download-file),
  [`scripts/jev`](../scripts/jev)
- <a id="file-picker"></a>**yazi as the file picker.** Upload dialogs open yazi
  in a terminal instead of Qt's picker.
  [`filepicker.py`](.config/qutebrowser/filepicker.py)

### Sessions

- <a id="session-append"></a>**Park a tab in a saved session without loading
  it.** `,qa` picks a session with fuzzel, appends the current tab and closes it.
  `,qA` does the same for a hinted link.
  [`session-append`](.local/share/qutebrowser/userscripts/session-append) ·
  [1c89fbc](https://github.com/HefKer/dots/commit/1c89fbc),
  [a410f06](https://github.com/HefKer/dots/commit/a410f06)
- <a id="session-take"></a>**Pull one tab back out of a session.** `,qt` picks a
  session and then one of its tabs with fuzzel and opens it, removing it from the
  session. `,qT` keeps it there.
  [`session-take`](.local/share/qutebrowser/userscripts/session-take) ·
  [8cd8721](https://github.com/HefKer/dots/commit/8cd8721)

### Video and YouTube

- <a id="mpv"></a>**Send video to mpv.** `emm` plays the current page in mpv and
  `emf` a hinted link, with subtitles. [`binds.py`](.config/qutebrowser/binds.py)
- <a id="video-keys"></a>**Speed and volume keys for any HTML5 video.**
  `Alt-.` / `Alt-,` change the speed and `Alt-j` / `Alt-k` the volume.
  [`js/video.js`](.config/qutebrowser/js/video.js) ·
  [c22ec3b](https://github.com/HefKer/dots/commit/c22ec3b)
- <a id="youtube-adblock"></a>**YouTube ad blocking.** qutebrowser's built-in
  adblock skips uBlock Origin's scriptlet rules, which is what YouTube needs.
  [`youtube-prune.js`](.config/qutebrowser/greasemonkey/youtube-prune.js) ports
  uBO's youtube.com filters, and
  [`youtube-ab.js`](.config/qutebrowser/greasemonkey/youtube-ab.js) skips anything
  that gets through. Expect to keep this one in sync as YouTube changes.
  [a7c3a33](https://github.com/HefKer/dots/commit/a7c3a33),
  [3dca3f8](https://github.com/HefKer/dots/commit/3dca3f8)
- <a id="youtube-timestamp"></a>**Resume where you left off.**
  [`youtube-timestamp.js`](.config/qutebrowser/greasemonkey/youtube-timestamp.js)
  keeps `t=<n>s` in the URL as the video plays, so a saved session or a yanked
  URL resumes at that point. [e169b73](https://github.com/HefKer/dots/commit/e169b73)
- <a id="youtube-misc"></a>**Smaller YouTube fixes.** Hide Shorts
  ([`youtube-no-shorts.js`](.config/qutebrowser/greasemonkey/youtube-no-shorts.js)),
  hide Playables
  ([`youtube-no-playables.js`](.config/qutebrowser/greasemonkey/youtube-no-playables.js)),
  force 1080p ([`youtube-quality.js`](.config/qutebrowser/greasemonkey/youtube-quality.js))
  and skip sponsor segments
  ([`sponsorblock-lite.js`](.config/qutebrowser/greasemonkey/sponsorblock-lite.js)).
- <a id="twitch-ffz"></a>**FrankerFaceZ on Twitch, with auto-claim on.**
  [`twitch-ffz.js`](.config/qutebrowser/greasemonkey/twitch-ffz.js) loads FFZ
  without its injector's settings provider, which needs GM APIs qutebrowser
  lacks. It then turns on FFZ's auto-claim for channel points and drops, which
  are off by default and saved per browser profile, so a fresh profile gets them
  too.

### Fixes for qutebrowser gaps

- <a id="ubo-scriptlets"></a>**Popunder and new-tab blocking.**
  [`ubo-scriptlets`](.local/share/qutebrowser/userscripts/ubo-scriptlets) generates
  a greasemonkey script from the adblock lists' `nowoif` and `set-cookie` rules,
  which qutebrowser's adblock ignores. `cu` refreshes the lists and regenerates it.
  [8ad2499](https://github.com/HefKer/dots/commit/8ad2499)
- <a id="paywalls"></a>**Paywall bypass without the extension.** The
  [Bypass Paywalls Clean](https://gitflic.ru/project/magnolia1234/bypass-paywalls-clean-filters)
  filter list blocks paywall scripts through the adblock, and
  [`ubo-scriptlets`](.local/share/qutebrowser/userscripts/ubo-scriptlets) ports
  the parts the adblock skips: element hiding and the scriptlets that unlock
  articles by stripping paywall classes, clearing meter cookies and stubbing the
  page's paywall flags. gitflic refuses qutebrowser's download, so `cu` mirrors
  the list with curl and points the adblock at the copy
  ([`privacy.py`](.config/qutebrowser/privacy.py)).
- <a id="injectfix"></a>**Hints and userscripts dying after a cross-site
  navigation.** QtWebEngine skips a page's scripts after some cross-site
  navigations, which leaves hints and greasemonkey dead in that tab.
  [`injectfix.py`](.config/qutebrowser/injectfix.py) routes them into the
  profile's script collection instead.
  [a2be125](https://github.com/HefKer/dots/commit/a2be125)
  ([qutebrowser#8925](https://github.com/qutebrowser/qutebrowser/issues/8925))
- <a id="devtools-save"></a>**DevTools file saving.** QtWebEngine compiles
  DevTools' saving out, so Export HAR and Save as do nothing.
  [`devtoolssave.py`](.config/qutebrowser/devtoolssave.py) adds
  [`js/devtools-save.js`](.config/qutebrowser/js/devtools-save.js) to every
  profile, which turns those saves into downloads, so they land on the normal
  download prompt.
- <a id="printing"></a>**Printing to a named PDF.** On Wayland, Qt's print dialog
  offers no filename and saves a low-resolution image of the page.
  [`printing.py`](.config/qutebrowser/printing.py) prints to a PDF through a
  normal filename prompt, catches `print()` calls from inside frames, and leaves
  page backgrounds out so dark mode doesn't print dark pages.
  [220f237](https://github.com/HefKer/dots/commit/220f237),
  [54f484d](https://github.com/HefKer/dots/commit/54f484d)
- <a id="tabreuse"></a>**Links reuse an open site's tab.** A link that would open
  a new foreground tab (`target=_blank`, tab hints) or a URL arriving from
  outside (`xdg-open`, e.g. a notification's action) switches to a tab already
  on that site instead, navigating it when the path differs. Only sites in
  `REUSE` are affected; middle-click and other background opens always get a
  new tab, and a link never reuses the tab it was clicked in.
  [`tabreuse.py`](.config/qutebrowser/tabreuse.py)
- <a id="spotify"></a>**Spotify links open the app.** Track, album, playlist and
  similar links go to the Spotify desktop app instead of the web player.
  [`spotify.py`](.config/qutebrowser/spotify.py) ·
  [5bd8683](https://github.com/HefKer/dots/commit/5bd8683)

## Using it yourself

- **Theme.** `appearance.py` imports `everforest` from `themes/`, which is a
  symlink to a separate repo that isn't public yet. Swap that import for your own
  colours, or for a published qutebrowser theme.
- **Hardcoded bits.** A few binds name things only my machine has: the KDE
  Connect device id behind `epp`/`epf`, `~/.local/bin/ytdl`, and the `zen-beta`
  and `helium` browsers in the `eb…` binds. Change or drop them.
- **Try it safely.** `qutebrowser --basedir <empty dir>` with these files copied
  into `<dir>/config/` runs the config without touching your profile.
  [`scripts/qute-sandbox`](../scripts/qute-sandbox) does the same from the shell.

### Dependencies

- **Videos:** [mpv](https://mpv.io/), [yt-dlp](https://github.com/yt-dlp/yt-dlp),
  mpv-sponsorblock
- **Pickers:** [fuzzel](https://codeberg.org/dnkl/fuzzel) for the session
  userscripts, and [yazi](https://yazi-rs.github.io/) +
  [WezTerm](https://wezterm.org/) for the file picker
- **Adblock:** the [adblock](https://pypi.org/project/adblock/) Python package, and curl for the mirrored paywall list.
  Run `:adblock-update` once.
- **Passwords:** the `,q…` binds call
  [qutewarden](https://github.com/HefKer/qutewarden), a Bitwarden userscript kept
  in its own repo.
- **Spellcheck (en-US)**, on NixOS:

  ```sh
  "$(find "$(nix-store --query --outputs "$(which qutebrowser)")" -iname 'dictcli.py' | head -1)" install en-US
  ```
