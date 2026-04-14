# dots

My dotfiles (using [GNU Stow](https://www.gnu.org/software/stow/)).

## qutebrowser

A keyboard-focused browser with vim bindings. Although it doesn't have extensions, it is highly customizable through its config file. I'm still messing with it but the sessions are really powerful, essentially letting you create, load, and delete workspaces on the fly.

### Dependencies

To detach videos (download & play locally):

- [mpv - player](https://mpv.io/)
- [yt-dlp - download videos to play externally](https://github.com/yt-dlp/yt-dlp)
- mpv-sponsorblock to block sponsored sections in mpv

For bitwarden:

- [Rofi for bitwarden login menu](https://wiki.archlinux.org/title/Rofi)
- [tldextract · PyPI](https://pypi.org/project/tldextract/)
- [pyperclip · PyPI](https://pypi.org/project/pyperclip/)
- bitwarden-cli

> [!NOTE]
> I'm still having issues with the Bitwarden setup. It's slow + doesn't autofill properly on a lot of sites.

For the adblock:

- [adblock · PyPI](https://pypi.org/project/adblock/)
- Run `:adblock-update` in qb to update adblock lists
