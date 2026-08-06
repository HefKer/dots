function nixlog --description "Show the upstream changelog / release notes for a nixpkgs package at a given version"
    argparse u/url l/list= r/raw d/deep h/help -- $argv
    or return 1

    if set -q _flag_help; or test (count $argv) -eq 0
        echo "Usage: nixlog <pkg> [version]      # release notes for a package version"
        echo ""
        echo "  nixlog ripgrep               # notes for the version you have pinned"
        echo "  nixlog ripgrep 15.3.0        # notes for a specific version"
        echo "  nixlog neovim                # works even with no meta.changelog"
        echo "  nixlog pipewire              # GitLab projects too"
        echo "  nixlog curl                  # HTML release-note pages, via pandoc"
        echo "  nixlog nano --deep           # last resort: read NEWS from the source"
        echo "  nixlog bat --raw             # whole changelog, not just this version"
        echo "  nixlog fish --url            # just print the URLs, fetch nothing"
        echo "  nixlog fish --list=10        # list the 10 most recent upstream releases"
        echo ""
        echo "Resolution order:"
        echo "  1. GitHub release for the tag      (gh)"
        echo "  2. GitLab release for the tag      (any GitLab host, no auth)"
        echo "  3. meta.changelog fetched directly (text as-is, HTML via pandoc)"
        echo "  4. --deep only: NEWS/ChangeLog from the source tarball"
        echo "  5. the URLs themselves, so you can go read it yourself"
        echo ""
        echo "Pair with nixup: 'nixup rg' tells you 15.2.0 -> 15.3.0,"
        echo "then 'nixlog rg 15.3.0' tells you what that actually changes."
        return (set -q _flag_help; and echo 0; or echo 1)
    end

    if not command -q nix
        echo "nixlog: 'nix' not found on PATH" >&2
        return 1
    end

    set -l pkg $argv[1]
    set -l want $argv[2]

    # --- resolve the attr ------------------------------------------------------
    # Many packages you actually *use* are wrappers with no src of their own
    # (neovim -> neovim-unwrapped, firefox -> firefox-unwrapped). The wrapper
    # carries the version but the unwrapped derivation carries the source, so
    # keep both: `attr` for metadata, `srcattr` for anything src-derived.
    set -l attr $pkg
    set -l pinned (nix eval --raw nixpkgs#$attr.version 2>/dev/null)
    if test -z "$pinned"
        # Store paths preserve upstream capitalisation (OpenTabletDriver) while
        # the nixpkgs attr is usually lowercase, so a name copied out of `nixup`
        # or a store path won't resolve on the first try.
        set -l lower (string lower -- $pkg)
        if test "$lower" != "$pkg"
            set pinned (nix eval --raw nixpkgs#$lower.version 2>/dev/null)
            test -n "$pinned"; and set attr $lower
        end
    end
    if test -z "$pinned"
        echo "nixlog: no such package '$pkg' in nixpkgs (bad attr name?)" >&2
        return 1
    end
    test -z "$want"; and set want $pinned

    set -l srcattr $attr
    if not nix eval --raw nixpkgs#$attr.src.url >/dev/null 2>&1
        if nix eval --raw nixpkgs#$attr-unwrapped.src.url >/dev/null 2>&1
            set srcattr $attr-unwrapped
        end
    end

    # --- gather candidate URLs, best first -------------------------------------
    set -l changelog (nix eval --raw nixpkgs#$attr.meta.changelog 2>/dev/null)
    set -l srcurl (nix eval --raw nixpkgs#$srcattr.src.url 2>/dev/null)
    set -l homepage (nix eval --raw nixpkgs#$attr.meta.homepage 2>/dev/null)

    # nixpkgs interpolates ${version} into these URLs, so a URL for the pinned
    # version becomes a URL for any other version by swapping the version string.
    # This is what makes tag prefixes work for free: jq's tag is "jq-1.8.2", so
    # substituting 1.8.2 -> 1.9.0 yields "jq-1.9.0" rather than a bare "1.9.0".
    if test "$want" != "$pinned"
        set changelog (string replace -a -- $pinned $want "$changelog")
        set srcurl (string replace -a -- $pinned $want "$srcurl")
    end

    set -l repo (__nixlog_gh_repo "$changelog" "$srcurl" "$homepage")
    set -l tag (__nixlog_tag "$changelog" "$srcurl")
    test -z "$tag"; and set tag $want

    # --- --list ----------------------------------------------------------------
    if set -q _flag_list
        if test -z "$repo"
            echo "nixlog: --list needs a GitHub repo, and none was found for $pkg" >&2
            return 1
        end
        echo "# github.com/$repo" >&2
        gh release list --repo $repo --limit $_flag_list
        return $status
    end

    # --- --url: report what we found and stop ----------------------------------
    if set -q _flag_url
        test -n "$changelog"; and echo "changelog: $changelog"
        test -n "$repo"; and echo "release:   https://github.com/$repo/releases/tag/$tag"
        test -n "$srcurl"; and echo "src:       $srcurl"
        test -n "$homepage"; and echo "homepage:  $homepage"
        return 0
    end

    # Note the separate variable: in fish, concatenating a command substitution
    # that produces no output collapses the whole argument, so an inline
    # `"$pkg $want"(...)` would silently print nothing when versions match.
    set -l pinnote ""
    test "$want" != "$pinned"; and set pinnote "  (pinned: $pinned)"
    set_color --bold
    echo "$pkg $want$pinnote"
    set_color normal

    # --- 1. a GitHub release for this tag --------------------------------------
    # Preferred: written per-release by upstream, so it is exactly the
    # "what changed in THIS version" answer, with no slicing guesswork.
    if test -n "$repo"
        set -l body (gh release view $tag --repo $repo --json body --jq '.body' 2>/dev/null)
        if test -z "$body"
            # Tag conventions drift across a project's life (v1.2.0 today,
            # 1.2.0 five years ago). Ask GitHub for a tag ending in the version
            # rather than guessing prefixes ourselves.
            set -l alt (gh release list --repo $repo --limit 100 --json tagName --jq '.[].tagName' 2>/dev/null \
                | string match -r ".*"(string escape --style=regex -- $want)"\$" | head -1)
            if test -n "$alt"
                set tag $alt
                set body (gh release view $tag --repo $repo --json body --jq '.body' 2>/dev/null)
            end
        end
        if test -n "$body"; and not __nixlog_thin "$body" $want
            __nixlog_src "github.com/$repo release $tag"
            printf '%s\n' $body | __nixlog_render
            return 0
        end
    end

    # --- 2. a GitLab release for this tag --------------------------------------
    # GitLab's releases API is open without auth, and covers freedesktop.org /
    # GNOME / gitlab.com alike — which between them are most of the Linux
    # plumbing that never shows up on GitHub.
    set -l gl (__nixlog_gitlab "$changelog" "$srcurl" "$homepage")
    if test (count $gl) -eq 3
        set -l enc (string replace -a '/' '%2F' -- $gl[2])
        set -l api "https://$gl[1]/api/v4/projects/$enc/releases/$gl[3]"
        set -l desc (curl -fsSL --max-time 20 $api 2>/dev/null | jq -r '.description // empty' 2>/dev/null)
        if test -n "$desc"; and not __nixlog_thin "$desc" $want
            __nixlog_src "$gl[1] release $gl[3]"
            printf '%s\n' $desc | __nixlog_render
            return 0
        end
    end

    # --- 3. fetch meta.changelog and read whatever it turns out to be ----------
    # Rather than enumerate forges, fetch the URL and branch on Content-Type:
    # plain text prints as-is, HTML goes through pandoc. That covers cgit, gitweb,
    # sourcehut, vendor release-note pages and anything else without special-casing.
    if test -n "$changelog"
        # A GitLab blob URL renders a whole HTML file browser; the raw endpoint
        # serves the file itself, so ask for that instead.
        set -l fetch (string replace -- '/-/blob/' '/-/raw/' $changelog | string replace -r '\?ref_type=.*$' '')
        set -l text (__nixlog_fetch $fetch)
        if test -n "$text"
            __nixlog_src "$fetch"
            if set -q _flag_raw
                printf '%s\n' $text | __nixlog_render
            else
                printf '%s\n' $text | __nixlog_section $want | __nixlog_render
            end
            return 0
        end
    end

    # --- 4. --deep: read the changelog out of the source itself ----------------
    # The only fully general answer. Nearly every tarball ships a NEWS or
    # ChangeLog, so this reaches the mirror:// long tail (GNU, X.org, kernel.org)
    # that publishes no release API at all. Opt-in because it downloads the source.
    if set -q _flag_deep
        echo "fetching source …" >&2
        set -l sp (nix build --no-link --print-out-paths nixpkgs#$srcattr.src 2>/dev/null)
        if test -n "$sp"
            set -l text (__nixlog_from_src $sp)
            if test -n "$text"
                __nixlog_src (basename $sp)
                if set -q _flag_raw
                    printf '%s\n' $text | __nixlog_render
                else
                    printf '%s\n' $text | __nixlog_section $want | __nixlog_render
                end
                return 0
            end
        end
    end

    # --- 5. nothing machine-readable: hand over the links ----------------------
    # Better to point at the real page than to scrape it and be subtly wrong.
    # Call out the snapshot case specifically: when nixpkgs pins a raw commit
    # ("0-unstable-2026-07-16", or a bare SHA) there is no release to fetch and
    # no amount of retrying will produce one — the commit log IS the changelog.
    if string match -qr '^[0-9a-f]{40}$' -- $tag; or string match -qr 'unstable' -- $want
        set_color yellow
        echo "packaged from an untagged git snapshot — no release notes exist"
        set_color normal
        test -n "$repo"; and echo "  commits:   https://github.com/$repo/commits/$tag"
        test -n "$homepage"; and echo "  homepage:  $homepage"
        return 1
    end

    set_color yellow
    echo "no fetchable changelog found — try these:"
    set_color normal
    test -n "$changelog"; and echo "  changelog: $changelog"
    test -n "$repo"; and echo "  releases:  https://github.com/$repo/releases"
    test -n "$srcurl"; and echo "  src:       $srcurl"
    test -n "$homepage"; and echo "  homepage:  $homepage"
    set -q _flag_deep; or echo "  (or retry with --deep to read NEWS out of the source)"
    return 1
end

# Pull a changelog file out of a fetched source, tarball or unpacked tree.
# Ordered by how version-specific the file usually is: NEWS is curated prose,
# ChangeLog is often a raw commit dump.
function __nixlog_from_src
    set -l p $argv[1]
    set -l names NEWS.md NEWS CHANGELOG.md CHANGELOG ChangeLog.md ChangeLog HISTORY
    if test -d $p
        for n in $names
            set -l f (find $p -maxdepth 2 -iname $n -type f 2>/dev/null | head -1)
            if test -n "$f"
                cat $f
                return 0
            end
        end
    else
        set -l members (tar -tf $p 2>/dev/null)
        or return 1
        for n in $names
            set -l hit (printf '%s\n' $members | string match -ri '(^|.*/)'(string escape --style=regex -- $n)'$' | head -1)
            if test -n "$hit"
                tar -xOf $p $hit 2>/dev/null
                return 0
            end
        end
    end
    return 1
end

# True when a release body carries no actual information. Plenty of projects
# tag a release and leave the notes as just the version string (gnome-keyring's
# "50.0"), which would otherwise win over a NEWS file that says something real.
# Judge by what's left after removing the version and punctuation.
function __nixlog_thin
    set -l meat (string replace -a -- "$argv[2]" '' "$argv[1]" | string replace -ar '[^a-zA-Z]' '')
    test (string length -- "$meat") -lt 20
end

function __nixlog_src
    set_color brblack
    echo "via $argv[1]"
    set_color normal
    echo ""
end

# Extract owner/repo from whichever candidate URL is GitHub-shaped.
function __nixlog_gh_repo
    for u in $argv
        test -n "$u"; or continue
        set -l m (string match -r 'github\.com/([^/]+)/([^/]+?)(?:\.git)?(?:/|$)' -- $u)
        test (count $m) -eq 3; and echo $m[2]/$m[3]; and return 0
    end
end

# Extract host, project path and tag from a GitLab URL. Project paths nest
# arbitrarily (GNOME/cheese, mesa/mesa), so take everything between the host
# and the '/-/' separator rather than assuming one group and one repo.
function __nixlog_gitlab
    for u in $argv
        test -n "$u"; or continue
        string match -qr 'gitlab' -- $u; or continue
        # The archive endpoint nixpkgs fetches from: project is already encoded.
        set -l m (string match -r '://([^/]+)/api/v4/projects/([^/]+)/repository/archive[^?]*\?sha=(.+)$' -- $u)
        if test (count $m) -eq 4
            # sha= is percent-encoded and often a full ref rather than a bare
            # tag ("refs%2Ftags%2F0.5.15"); the releases API wants just "0.5.15".
            set -l t (string replace -a '%2F' '/' -- $m[4] | string replace -r '^refs/(tags|heads)/' '')
            printf '%s\n%s\n%s\n' $m[2] (string replace -a '%2F' '/' -- $m[3]) $t
            return 0
        end
        set m (string match -r '://([^/]+)/(.+?)/-/(?:releases|tags)/([^/?#]+)' -- $u)
        if test (count $m) -eq 4
            printf '%s\n%s\n%s\n' $m[2] $m[3] $m[4]
            return 0
        end
        set m (string match -r '://([^/]+)/(.+?)/-/(?:blob|raw)/([^/]+)/' -- $u)
        if test (count $m) -eq 4
            printf '%s\n%s\n%s\n' $m[2] $m[3] $m[4]
            return 0
        end
    end
    return 1
end

# Extract the upstream tag. src.url is the reliable one: nixpkgs builds it from
# the real tag, so it survives prefixes (v1.2.3), namespaces (jq-1.8.2) and
# oddities (release-2024-01) that guessing from the version alone would miss.
function __nixlog_tag
    for u in $argv
        test -n "$u"; or continue
        set -l m (string match -r 'archive/refs/tags/(.+?)\.(tar\.gz|zip|tar\.bz2|tar\.xz)$' -- $u)
        test (count $m) -eq 3; and echo $m[2]; and return 0
        set m (string match -r 'releases/tag/([^/?#]+)' -- $u)
        test (count $m) -eq 2; and echo $m[2]; and return 0
        set m (string match -r 'archive/(.+?)\.(tar\.gz|zip|tar\.bz2|tar\.xz)$' -- $u)
        test (count $m) -eq 3; and echo $m[2]; and return 0
    end
end

# Fetch a URL and return readable text, deciding by Content-Type rather than by
# file extension — half these changelogs are extensionless NEWS files and the
# other half are HTML pages that happen to end in .html, .cgi or nothing at all.
function __nixlog_fetch
    set -l tmp (mktemp)
    set -l ctype (curl -fsSL --max-time 25 -w '%{content_type}' -o $tmp $argv[1] 2>/dev/null)
    if test $status -ne 0; or not test -s $tmp
        rm -f $tmp
        return 1
    end
    if string match -qr 'html|xml' -- "$ctype"; and command -q pandoc
        # Keep '#' headings (the section slicer keys off them) but switch off the
        # extensions that would otherwise echo the page's div/span chrome back at
        # you as literal ':::' fences and raw HTML.
        pandoc -f html --wrap=none $tmp 2>/dev/null \
            -t markdown-raw_html-fenced_divs-native_divs-bracketed_spans-link_attributes
    else if string match -qr 'html|xml' -- "$ctype"
        rm -f $tmp
        return 1
    else
        cat $tmp
    end
    rm -f $tmp
end

# Slice a changelog down to one version's section. Two shapes are common:
# markdown headings (## v1.2.3) and plain NEWS files ("Changes in version 50.0").
# Both mean "start here, stop at the next peer heading". Falls back to the whole
# document when neither matches, so you never get empty output.
function __nixlog_section
    awk -v want="$argv[1]" '
    { all[m++] = $0 }
    END {
        # Pass 1: markdown headings.
        for (i = 0; i < m; i++) {
            if (match(all[i], /^#+/)) {
                d = RLENGTH
                if (!found && index(all[i], want)) { found = 1; depth = d; start = i }
                else if (found && d <= depth) { stop = i; break }
            }
        }
        # Pass 2: a plain-text heading at column 0 naming the version, running
        # until the next unindented line that names a different version.
        if (!found) {
            for (i = 0; i < m; i++) {
                if (!found && index(all[i], want) && all[i] ~ /^[^ \t]/) { found = 1; start = i }
                else if (found && all[i] ~ /^[^ \t]/ && all[i] ~ /[0-9]+\.[0-9]+/ && index(all[i], want) == 0) { stop = i; break }
            }
        }
        if (!found) { for (i = 0; i < m; i++) print all[i]; exit }
        if (stop == 0) stop = m
        for (i = start; i < stop; i++) print all[i]
    }'
end

# Pretty-print markdown if a renderer is around; otherwise stay out of the way.
function __nixlog_render
    if command -q glow
        glow -
    else if command -q mdcat
        mdcat
    else if command -q bat
        bat --language markdown --style plain --paging never
    else
        cat
    end
end
