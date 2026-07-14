function hmopt --description "Search Home Manager module options from the nix store"
    if test (count $argv) -eq 0
        echo "Usage: hmopt <module> [concept|option]"
        echo "  hmopt fish             # list every option WITH its type"
        echo "  hmopt fish alias       # search options by concept (case-insensitive)"
        echo "  hmopt fish shellAbbrs  # show one option's type/default/example"
        echo "  hmopt git ignore       # works for any programs.* / services.* / misc module"
        return 1
    end

    set -l mod $argv[1]
    set -l query $argv[2]

    # Find Home Manager's OWN module tree, not nixpkgs'. programs.git (etc.) exists
    # in both HM and NixOS as DIFFERENT modules; a loose '*/modules/*' glob would grab
    # nixpkgs' 'nixos/modules/programs/git.nix' by mistake. HM's signature file is
    # modules/home-environment.nix, so anchor on that. Multiple HM versions can coexist
    # in the store; tail -1 picks one deterministically (usually your current pin).
    set -l hmmods (find /nix/store -maxdepth 4 -path '*/modules/home-environment.nix' 2>/dev/null \
        | sort -u | tail -1 | string replace '/home-environment.nix' '')

    if test -z "$hmmods"
        echo "hmopt: couldn't locate the Home Manager module tree in /nix/store"
        return 1
    end

    set -l file (find $hmmods -name "$mod.nix" 2>/dev/null | sort -u | tail -1)

    if test -z "$file"
        echo "hmopt: no HM module found for '$mod'"
        return 1
    end
    echo "# $file"

    if test -z "$query"
        # Menu: pair each option with its type, prettified toward extranix-style wording.
        # awk holds the option name, then grabs the next 'type = …;' line. mkEnableOption
        # has no type line — it's always a boolean.
        awk '
        function pretty(t) {
            sub(/;.*$/, "", t)                       # drop trailing ; and comment
            gsub(/with[ ]+(lib\.)?types;?[ ]*/, "", t)
            gsub(/lib\.types\.|types\.|lib\./, "", t)
            if (t ~ /submodule/) return "submodule"
            gsub(/nullOr/, "null or", t)
            gsub(/listOf/, "list of", t)
            gsub(/attrsOf/, "attribute set of", t)
            gsub(/\<str\>/, "string", t)
            gsub(/\<bool\>/, "boolean", t)
            gsub(/\<int\>/, "integer", t)
            gsub(/[ ]+/, " ", t)
            gsub(/^[ ]+|[ ]+$/, "", t)
            return t
        }
        # Grab the type expression starting on the current line, joining up to a few
        # continuation lines until a ; appears (handles `type = with types;` + next line).
        function grabtype(   buf, more, n) {
            buf = $0; sub(/^[[:space:]]*type[[:space:]]*=[[:space:]]*/, "", buf)
            sub(/with[ ]+(lib\.)?types;?[ ]*/, "", buf)   # a with-; is not the end
            n = 0
            while (buf !~ /;/ && n < 4 && (getline more) > 0) {
                sub(/^[[:space:]]+/, "", more); buf = buf " " more; n++
            }
            return pretty(buf)
        }
        {
            if (match($0, /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*(lib\.)?mkEnableOption/)) {
                n = $0; sub(/[[:space:]]*=.*/, "", n); gsub(/[[:space:]]/, "", n)
                printf "%5d  %-24s boolean\n", NR, n; name=""; next
            }
            if (match($0, /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*(lib\.)?mkOption/)) {
                if (name != "") printf "%5d  %-24s ?\n", nl, name
                name=$0; sub(/[[:space:]]*=.*/, "", name); gsub(/[[:space:]]/, "", name); nl=NR; next
            }
            if (name != "" && match($0, /^[[:space:]]*type[[:space:]]*=/)) {
                tp = grabtype(); if (tp == "") tp = "?"
                printf "%5d  %-24s %s\n", nl, name, tp; name=""; next
            }
        }
        END { if (name != "") printf "%5d  %-24s ?\n", nl, name }
        ' $file
    else if grep -qE "$query = (lib\.)?mk(Option|EnableOption)" $file
        # Query is an option name: show its block — type, default, example.
        grep -nA 15 -E "$query = (lib\.)?mk(Option|EnableOption)" $file
    else
        # Otherwise: concept search across the whole module.
        grep -niE "$query" $file
    end
end
