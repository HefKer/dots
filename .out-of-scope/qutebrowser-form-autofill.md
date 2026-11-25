# qutebrowser: address and card autofill

This repo doesn't add a userscript that fills address or payment-card fields
from the password vault.

## Why this is out of scope

Filling forms from the vault is qutewarden's job. qutewarden is its own project,
linked into qutebrowser's `userscripts/` from outside this repo; the dotfiles
only bind its commands. A second script here that reads vault entries and
detects form fields would duplicate its vault access and its field matching, in
a repo whose scripts are meant to stay single files with no tests.

A request for address or card autofill belongs in qutewarden.

## Prior requests

- hefker/dots-issues#21: "qutebrowser: close browser gaps with userscripts" (the "Address and card autofill" item)
