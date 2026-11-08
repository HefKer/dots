I added the sops secret `$0` with `secret`. Wire it into the Nix config.

Find which file under secrets/ holds the key, but don't decrypt or print any values. Declare `sops.secrets.<key>` where the service that uses it is configured. Follow how existing secrets are set up: host files are the default sopsFile, shared.yaml needs an explicit `sopsFile`, and set `owner` when a user service reads it. If the program wants an env file or config, use `sops.templates` with `config.sops.placeholder`. Then point the consumer at `.path` and run the checks.
