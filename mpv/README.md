# mpv

[mpv](https://mpv.io/) with [uosc](https://github.com/tomasklaen/uosc) as its UI.
The scripts (uosc, sponsorblock, thumbfast, mpris, memo, mpv-anilist-updater) are
installed by the NixOS config; this directory holds their settings in
`script-opts/`. `uosc.conf` is uosc's template with every option commented out,
and only the lines I changed uncommented. Colours are DMS's Everforest, copied by
hand, so they don't follow a wallpaper change.

## Worth stealing

- <a id="fast-youtube-start"></a>**YouTube starts sooner.** The format is capped
  at the 1080p screens instead of fetching 4K60, yt-dlp skips the HLS manifest
  it never uses (`youtube:skip=hls`), and `force-window=immediate` shows the
  window at once instead of nothing until the first frame.
  [`mpv.conf`](.config/mpv/mpv.conf)
- <a id="g-group"></a>**mpv's `g` select menus back from sponsorblock.**
  sponsorblock binds a plain `g`, which fires before mpv's `g-…` sequences can
  start; `g ignore` in `input.conf` outranks it. `g-g` lists every binding to
  run, `g-m` opens uosc's menu, `g-h` memo's history.
  [`input.conf`](.config/mpv/input.conf)
- <a id="source-url"></a>**`ctrl+u` shows the source URL, `ctrl+U` opens it.**
  It reads the `comment` tag yt-dlp's `--add-metadata` writes into downloads,
  and falls back to the stream's own path.
  [`input.conf`](.config/mpv/input.conf)
- <a id="playlist-buttons"></a>**Playlist buttons only with a playlist.** uosc's
  shuffle, loop-playlist, prev, items and next sit behind `<has_playlist>`, so a
  single video shows just loop and fullscreen.
  [`uosc.conf`](.config/mpv/script-opts/uosc.conf)
