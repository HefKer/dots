---
name: config-walkthrough
description: Walk through a program's config options in rounds with the user and tune it to the look and behaviour they want, starting from no config or an existing one.
disable-model-invocation: true
---

# Config walkthrough

The user names a program; together you work through its options in **rounds**, and the user judges each round by using the program. The user owns every taste decision; you bring the option list, the recommendations and the edits.

## 1. Survey

Establish what is true on this machine:

- Version, and where the config lives. Note whether a config exists at all, and whether a skill in this repo covers the program.
- The full option list, read from the installed version: `man`, `--help`, the template the package ships in its store path. Your memory of the options is only a lead.
- The validation command, if any (e.g. `--check-config`), and how the program picks up a change: next launch, a reload command, or a restart.
- Who else uses the program. A setting that suits one consumer can break another, the way a launcher is also a password manager's picker.
- The desktop's current look, read from the niri, DMS, wezterm and qutebrowser configs: colours, font, size, border, corners.

Done when you can name the config path, the option source, the reload method, every consumer, and the palette with where each colour came from.

## 2. Scaffold

Skip this if the program already has a config in this repo.

Copy the shipped template into a new package here, every option commented at its default, so the program behaves the same until a line is uncommented. With no template, start from an empty file. Validate it, add the link set entry per `AGENTS.md`, and mirror it in the dotfiles check's expected link set in `~/nixos/main/checks/default.nix` for each host. Once `nix flake check` passes, commit those two files in `~/nixos/main`, staging only them, then stop for the user to rebuild.

Done when the user has rebuilt and the config path resolves to this repo.

## 3. Rounds

Group the options by what the user would notice, biggest change first: colours and borders, font and sizing, contents, position and matching, then keybindings and niche settings. For each round:

1. Show a table of the round's options: name, current value, what it changes.
2. Give your recommendation with its reason, and flag the options that affect another consumer or that are worth trying alone.
3. Apply what the user picked, validate, and tell them what to open to see it.
4. Take their reaction and iterate until they move on.

The first round can be applied as a proposal, since a look is judged by seeing it. Later rounds wait for the user's picks.

Edit by uncommenting and changing the template's line in place, so the file keeps its shape. To undo a change, restore the commented default. Leave a note on a line the user wants to revisit, in the template's `# a|b|c` style.

When the user asks for something the program may not do, check the option source, then answer plainly and offer the nearest real option. If a value is your guess, such as a unit or a size picked by eye, say so.

Done when every group has been offered and the user says they're finished. An option group the user waves off counts as offered.

## 4. Finish

Commit this repo's changes when the user says to, staging only this program's files, since the tree often holds unrelated changes.
