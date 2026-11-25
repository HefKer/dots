# niri: workspaces with jobs

Numbered workspaces don't get fixed jobs (`school`, `agents`, and the like) with
window rules that send apps to them.

## Why this is out of scope

The numbered workspaces are overflow, not categories: `1` on the main screen is
whatever is in progress, and `2`, `3`, … fill up as more things need to stay
within reach. The only workspaces with a fixed job are the passive ones that are
always open, `chat` and `web`, and those already exist in the host files.

A job would take a slot out of that overflow and reserve it for something that
is often not open at all. It also can't be expressed well:

- niri's window rules match the **app** (app-id, title), not what it is being
  used for. zathura shows school PDFs and every other PDF, so a rule would send
  all of them to `school`.
- Agents run in herdr inside the ordinary WezTerm window. Telling them apart
  needs a second WezTerm with its own app-id, which the terminal summon then
  skips, to enforce a separation that isn't wanted.

A named workspace with no rule is only a label, which adds nothing over its
number.

## Prior requests

- hefker/dots-issues#71: "niri: give a few workspaces jobs (chat, school, agents) and place apps on them"
