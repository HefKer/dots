# Dotfiles

The content of the user's app configs. This glossary fixes the vocabulary for
binds (what triggers them, which scope owns them, and what earns one) and for
writing to a Claude agent from nvim.

## Language

### Binds

**Bind**:
A pairing of a trigger with the action it runs, within one scope.
_Avoid_: binding, keybind, keybinding, shortcut, hotkey

**Trigger**:
What is pressed to fire a bind: a combo, a chord, or a sequence.
_Avoid_: key, shortcut

**Action**:
What a bind runs once its trigger completes.
_Avoid_: command, function

**Combo**:
Modifiers held with one other key, such as `Super+Shift+H`.
_Avoid_: chord, shortcut

**Chord**:
Several non-modifier keys pressed together, as on a chording keyboard.
_Avoid_: combo

**Sequence**:
Triggers pressed one after another, such as `e b h`.
_Avoid_: chord, key sequence

**Prefix**:
Any trigger in a sequence other than the last, such as a multiplexer's.

**Leader**:
A prefix set aside as the user's own namespace within a scope.
_Avoid_: prefix (for the user's own)

**Scope**:
One layer of the stack that receives keys, such as the remapper, the
window manager, a multiplexer, an app, or a mode within an app. Each scope
consumes only the triggers it claims and passes the rest through.
_Avoid_: context, layer

**Group**:
A prefix that names a domain rather than an action, such as `e` for external.
A group letter names the same domain in every scope; what follows it is local
to the scope.
_Avoid_: verb, category, submenu

**Overlap**:
One trigger running different actions in two scopes the user switches between,
or one group letter naming different domains. A typed command sharing letters
with a sequence, like the shell's `cd`, is not an overlap.
_Avoid_: conflict (that is two binds on one trigger within a scope)

**Alias**:
A short typed name for a target, such as `yt` for YouTube, shared by every
scope that takes aliases (quickmarks, search keywords). One alias names one
target; a collision goes to the target used more, and the other is suffixed.
_Avoid_: quickmark (one scope's kind of alias), shortcut, keyword

**Rung**:
How reachable an action is, from fastest to slowest: a combo or chord, a
mnemonic sequence, search, a menu. An action earns a rung by how often it is
used, or by being needed mid-task; search is the floor every action reaches.
_Avoid_: tier, level

**Bind palette**:
One fuzzy search over every scope's binds, showing each trigger beside its
action so that searching teaches the bind.
_Avoid_: command palette (one app's own), cheatsheet

**Desktop leader**:
The window manager's leader: herdr's prefix raised one scope by adding `Mod`.
It holds rare desktop actions, and app actions reachable over the app's IPC.
_Avoid_: global leader, universal leader

**Shell bind**:
A bind whose action belongs to the desktop shell (launcher, clipboard,
notifications, media, volume, lock) rather than to the window manager. Owned
and edited by the shell; window-manager binds and personal binds are owned by
the user's own config. The command shell's binds are not shell binds: they
belong to the `fish` scope.
_Avoid_: DMS bind, system bind

**Summon**:
Bringing a specific app to focus from anywhere: its most recently focused
window on the first press, the next of its windows on each repeat, a new one
if none is open. Distinct from spawning, which always opens a new window.
_Avoid_: launch, focus-or-spawn

### Prompt pane

**Prompt pane**:
An nvim pane, opened over a Claude agent's pane, for writing to that agent while
reading its replies.
_Avoid_: prompt editor, nvim-claude

**Draft**:
The unsent text in the prompt pane, kept across crashes until it is sent.
_Avoid_: prompt (for the unsent text)

**Reply**:
What Claude wrote between two of your prompts, shown above the draft.

**Command queue**:
The slash commands leading a draft, each sent on its own and finished before
the next, ahead of the prose that follows them. A command directly followed by
text takes that text as its arguments.
_Avoid_: message queue

**Stash**:
The Claude sessions set aside to come back to, each with an optional note and
its draft, kept per machine. Stashing marks a session, or marks it and closes
its agent; resuming one takes it off the stash.
_Avoid_: bookmark, saved session
