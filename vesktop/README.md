# vesktop

[Vesktop](https://github.com/Vencord/Vesktop) is a Discord client with
[Vencord](https://vencord.dev) built in. `settings.json` is Vesktop's own
settings, and `settings/` holds Vencord's settings and Quick CSS. Both programs
write these files in place, so changes made in the GUI save through the links
into this repo. Edit the JSON only while Vesktop is closed, since it rewrites
the files from memory. The colours come from `themes/dank-discord.css`, which
DankMaterialShell generates, so that file stays out of the repo.

## Worth stealing

- <a id="quick-css"></a>**Quick CSS that hides Shop, Nitro, Quests and gift
  buttons, squares the corners and sets the code font.** Avatars stay round.
  [`quickCss.css`](.config/vesktop/settings/quickCss.css)
