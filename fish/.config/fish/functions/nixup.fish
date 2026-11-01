function nixup --description "Check if a nixpkgs package (or all installed) has a newer version on a channel before rebuilding"
    argparse a/all u/up-to-date h/help -- $argv
    or return 1

    if set -q _flag_help; or begin; test (count $argv) -eq 0; and not set -q _flag_all; end
        echo "Usage: nixup <pkg> [branch]        # compare your pinned version vs a channel"
        echo "       nixup -a|--all [branch]      # do it for every installed package"
        echo ""
        echo "  nixup neovim                 # neovim: pinned vs latest unstable"
        echo "  nixup neovim stable          # vs the current stable channel"
        echo "  nixup ripgrep nixos-25.05    # vs an explicit release channel"
        echo "  nixup --all                  # sweep all installed pkgs, unstable"
        echo "  nixup -a -u stable           # sweep, also list up-to-date and unresolved pkgs"
        echo ""
        echo "branch: unstable (default) | unstable-small | stable | master"
        echo "        | nixos-X<.YY> | any flake ref"
        echo ""
        echo "'current' = the installed version, overlays included; else what your"
        echo "            system nixpkgs pin evaluates to right now"
        echo "'latest'  = the tip of the requested channel (--refresh'd each run)"
        return (set -q _flag_help; and echo 0; or echo 1)
    end

    if not command -q nix
        echo "nixup: 'nix' not found on PATH"
        return 1
    end

    # --- resolve branch alias -> a flake ref pointing at the tested channel -----
    # Channels (channels.nixos.org via the registry) are what a rebuild actually
    # pulls, so we compare against those rather than raw github branch tips.
    set -l branch $argv[-1]
    # In single-pkg mode the last arg is the branch ONLY if there's more than the pkg.
    if not set -q _flag_all; and test (count $argv) -lt 2
        set branch unstable
    end
    if set -q _flag_all; and test (count $argv) -eq 0
        set branch unstable
    end

    set -l ref
    set -l label
    switch $branch
        case unstable ''
            set ref nixpkgs/nixos-unstable; set label unstable
        case unstable-small small
            set ref nixpkgs/nixos-unstable-small; set label unstable-small
        case stable
            # Highest nixos-XX.YY known to the registry == current stable channel.
            set -l chan (nix registry list 2>/dev/null \
                | string match -r 'nixos-[0-9]+\.[0-9]+(?!-)' \
                | sort -uV | tail -1)
            if test -z "$chan"
                echo "nixup: couldn't resolve 'stable' from the registry"
                return 1
            end
            set ref nixpkgs/$chan; set label $chan
        case master
            set ref github:NixOS/nixpkgs/master; set label master
        case 'nixos-*'
            set ref nixpkgs/$branch; set label $branch
        case '*'
            # Fall through: treat the arg as a full flake ref.
            set ref $branch; set label $branch
    end

    # ===========================================================================
    # SINGLE PACKAGE
    # ===========================================================================
    if not set -q _flag_all
        set -l pkg $argv[1]
        echo "Checking $pkg on $label …" >&2

        # The pin knows nothing of overlays, so it's only the fallback.
        set -l cur (__nixup_installed | string replace -rf '^'(string escape --style=regex -- $pkg)'\t' '')[1]
        test -z "$cur"; and set cur (nix eval --raw nixpkgs#$pkg.version 2>/dev/null)
        set -l new (__nixup_eval --raw --refresh $ref#$pkg.version)

        if test -z "$new"
            echo "nixup: couldn't read $pkg from $label"
            return 1
        end
        if test -z "$cur"
            echo "$pkg: $new on $label  (not installed or in your pin)"
            return 0
        end

        set -l dir (__nixup_dir "$cur" "$new")
        switch $dir
            case '=='
                echo "$pkg: $cur  (up to date on $label)"
            case '->'
                set_color green
                echo "$pkg: $cur -> $new  (update available on $label)"
                set_color normal
            case '<-'
                set_color yellow
                echo "$pkg: $cur <- $new  (local is newer than $label)"
                set_color normal
        end
        return 0
    end

    # ===========================================================================
    # ALL INSTALLED PACKAGES
    # ===========================================================================
    # Look every installed pname up on the target channel in ONE evaluation
    # (getFlake + tryEval so misses don't abort).
    echo "Collecting installed packages …" >&2

    set -l pnames
    set -l curvers
    for line in (__nixup_installed)
        set -l kv (string split \t -- $line)
        set -a pnames $kv[1]
        set -a curvers $kv[2]
    end

    if test (count $pnames) -eq 0
        echo "nixup: no installed packages found to check"
        return 1
    end
    echo "Looking up "(count $pnames)" packages on $label (one eval, may take a bit) …" >&2

    # Build the nix list literal: "a" "b" "c"
    set -l quoted
    for n in $pnames
        set -a quoted '"'$n'"'
    end
    set -l expr 'let f = builtins.getFlake "'$ref'";
        p = f.legacyPackages.${builtins.currentSystem};
    in builtins.listToAttrs (map (n: {
        name = n;
        value = (builtins.tryEval (p.${n}.version or null)).value;
    }) [ '(string join ' ' $quoted)' ])'

    set -l json (__nixup_eval --impure --refresh --json --expr $expr)
    if test -z "$json"
        echo "nixup: evaluation against $ref failed"
        return 1
    end

    # Walk each pname, pull the channel version out of the JSON with jq, compare.
    set -l n_update 0
    set -l n_same 0
    set -l n_newer 0
    set -l n_skip 0
    for i in (seq (count $pnames))
        set -l pn $pnames[$i]
        set -l cur $curvers[$i]
        set -l new (echo $json | jq -r --arg k $pn '.[$k] // empty' 2>/dev/null)
        if test -z "$new"
            set n_skip (math $n_skip + 1)
            set -q _flag_up_to_date; and printf '  %-28s %s\n' $pn "$cur (unresolved)"
            continue
        end
        set -l dir (__nixup_dir "$cur" "$new")
        switch $dir
            case '=='
                set n_same (math $n_same + 1)
                set -q _flag_up_to_date; or continue
                printf '  %-28s %s\n' $pn "$cur (up to date)"
            case '->'
                set n_update (math $n_update + 1)
                set_color green
                printf '  %-28s %s\n' $pn "$cur -> $new"
                set_color normal
            case '<-'
                set n_newer (math $n_newer + 1)
                set_color yellow
                printf '  %-28s %s\n' $pn "$cur <- $new (local newer)"
                set_color normal
        end
    end

    echo ""
    echo "$label: $n_update update(s), $n_same up to date, $n_newer local-newer, $n_skip unresolved" >&2
end

# Run nix eval, keeping its stderr quiet on success (warnings, fetch progress)
# but showing it on failure, so an outage doesn't read as a bad attr name.
function __nixup_eval
    set -l tmp (mktemp)
    nix eval $argv 2>$tmp
    set -l rc $status
    test $rc -ne 0; and cat $tmp >&2
    command rm -f $tmp
    return $rc
end

# Map a store-path pname to its nixpkgs attr, for pnames that name a different
# package there: attr 'zoom' is a Z-Code player, the Zoom client is zoom-us.
function __nixup_attr
    switch $argv[1]
        case zoom
            echo zoom-us
        case '*'
            echo $argv[1]
    end
end

# Print one 'attr<TAB>version' line per installed package, from both the system
# profile and the home-manager profile, parsed straight off the store paths.
function __nixup_installed
    set -l seen
    for prof in /run/current-system/sw /etc/profiles/per-user/$USER ~/.nix-profile
        test -e $prof; or continue
        for path in (nix-store -q --references $prof 2>/dev/null)
            set -l base (string replace -r '^/nix/store/[a-z0-9]{32}-' '' -- $path)
            # Drop trailing output suffixes so foo-1.2-man dedupes with foo-1.2.
            set base (string replace -r -- '-(man|dev|bin|doc|lib|out|info|debug)$' '' $base)
            # Split at the first '-<digit>': everything before is the pname.
            set -l m (string match -r '^(.+?)-([0-9].*)$' -- $base)
            test (count $m) -eq 3; or continue
            set -l attr (__nixup_attr $m[2])
            # Skip dupes (same pname from multiple profiles/outputs).
            contains -- $attr $seen; and continue
            set -a seen $attr
            printf '%s\t%s\n' $attr $m[3]
        end
    end
end

# What $argv[1] has beyond $argv[2], if $argv[2] is a prefix of it.
function __nixup_extra
    string match -q -- "$argv[2]*" "$argv[1]"; or return 1
    string sub -s (math (string length -- "$argv[2]") + 1) -- "$argv[1]"
end

# True for a suffix marking a pre-release, which sorts before the bare version
# even though sort -V ranks the longer string higher.
function __nixup_prerelease
    string match -qir -- '^[-.]?(rc|alpha|beta|pre)' "$argv[1]"
end

# Direction between two version strings: '->' (channel newer), '<-' (local
# newer), or '=='. Store paths carry suffixes .version lacks: outputs (-tools),
# patch levels (-57), upstream tag flavours (-lazer). Those are the same release.
function __nixup_dir
    set -l cur $argv[1]
    set -l new $argv[2]
    test "$cur" = "$new"; and echo '=='; and return
    set -l extra (__nixup_extra $cur $new)
    if test -n "$extra"
        __nixup_prerelease $extra; and echo '->'; and return
        string match -q -- '-*' $extra; and echo '=='; and return
    end
    set extra (__nixup_extra $new $cur)
    if test -n "$extra"
        __nixup_prerelease $extra; and echo '<-'; and return
        string match -q -- '-*' $extra; and echo '=='; and return
    end
    set -l top (printf '%s\n%s\n' $cur $new | sort -V | tail -1)
    test "$top" = "$new"; and echo '->'; or echo '<-'
end
