# Sequences are group-first, on LazyVim's dictionary

Status: accepted

A sequence's first letter names a domain, not an action: `e b h` is external →
browser → helium, not a verb applied to an object. One letter names the same
domain in every scope, and under a leader LazyVim's leader groups are the
dictionary (`q` is sessions in nvim, qutebrowser and the desktop leader alike).
A bare prefix keeps the app's own convention (qutebrowser's `c` config, vim's
`c` change), since moving those fights every app's defaults for little gain. This was already
the shape of the hand-written qutebrowser binds, and it gives hint popups a
tree to show; LazyVim's set is the largest and best designed, and fighting it
inside nvim costs the most.

## Considered options

- **Verb-first, like vim's operator + motion.** Rejected: the binds worth
  keeping were already group-first, and a verb set shared across scopes
  collided at once (`c` is *change* in vim, *config* in qutebrowser).
- **Each scope its own namespace.** Rejected: the same letter drifting to a
  different domain per app erodes the mnemonics that make sequences cheap.

## Consequences

- qutebrowser's leader groups that disagreed with LazyVim moved: sessions
  `,s` → `,q`, qutewarden `,q` → `,p`, toggles `,t` → `,u`.
- A domain LazyVim lacks claims a new letter for every scope (`e` external).
