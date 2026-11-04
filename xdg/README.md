# xdg

[`mimeapps.list`](.config/mimeapps.list) holds the default app for each file
type and link scheme. It has no comments, because apps rewrite it: Slack, and
anything else that sets a default through GLib, writes the whole file back
without them. Notes on its entries live here instead.

| Kind | Default |
|---|---|
| Web pages and links | qutebrowser |
| Folders | yazi |
| Zip archives | Nautilus |
| PDFs | zathura |
| Text, markdown, JSON, TOML, YAML, shell scripts | nvim |
| Images | imv |
| Video and audio | mpv |
| osu! beatmaps, skins, replays and `osu://` links | osu!lazer |

The `x-scheme-handler` lines from `discord` down were registered by the apps
themselves, not chosen by hand. The `discord-<id>` line is osu!lazer's Discord
Rich Presence, which osu!lazer re-adds on each launch.

## Using it yourself

- An app rewriting the file writes through the symlink, so the change shows up
  as a diff here. Check `git diff` before committing, since a GLib rewrite also
  drops blank lines and can add an empty `[Added Associations]` section.
- A tool that saves by rename instead replaces the link with a plain file, and
  the next home-manager rebuild aborts on it. Move the file back into this repo
  and relink it.
