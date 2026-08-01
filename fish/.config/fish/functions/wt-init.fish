function wt-init --description "Bare + worktree layout: clone a repo (default), or migrate one in place (-m)"
    argparse h/help m/migrate y/yes n/dry-run -- $argv
    or return 1

    if set -q _flag_help; or begin; not set -q _flag_migrate; and test (count $argv) -eq 0; end
        echo "Usage:"
        echo "  wt-init <repo-url> [container-dir]      # clone fresh into a bare layout"
        echo "  wt-init -m [repo-path]                  # migrate an existing repo in place"
        echo
        echo "Clone mode — bare-clones the url, sets the fetch refspec a --bare clone omits,"
        echo "and checks out the remote's default branch as the first worktree:"
        echo "  wt-init git@github.com:me/proj.git           # -> ./proj/{.bare, main/}"
        echo "  wt-init https://github.com/me/proj.git work  # -> ./work/{.bare, main/}"
        echo
        echo "Migrate mode (-m/--migrate) — converts an existing repo (default: cwd) to the"
        echo "bare layout WITHOUT re-cloning, so stashes, unpushed commits, and gitignored"
        echo "files survive. Existing worktrees are carried along. Flags:"
        echo "  -y/--yes       skip the confirmation prompt"
        echo "  -n/--dry-run   print the plan and exit, change nothing"
        echo
        echo "Add more branches later:"
        echo "  git -C <container> worktree add <dir> <branch>          # existing branch"
        echo "  git -C <container> worktree add -b <new> <dir> <base>   # new branch"
        set -q _flag_help; and return 0; or return 1
    end

    if not command -q git
        echo "wt-init: 'git' not found on PATH — add it in ~/nixos/"
        return 1
    end

    # ─────────────────────────────── migrate mode ───────────────────────────────
    if set -q _flag_migrate
        if not command -q rsync
            echo "wt-init: --migrate needs 'rsync' (safe non-tracked transplant) — add it in ~/nixos/"
            return 1
        end
        if not command -q tar
            echo "wt-init: --migrate needs 'tar' (backup) — add it in ~/nixos/"
            return 1
        end

        set -l target $argv[1]
        test -z "$target"; and set target (pwd)
        if not git -C $target rev-parse --git-dir >/dev/null 2>&1
            echo "wt-init: '$target' is not inside a git repository."
            return 1
        end

        # Enumerate worktrees. The first block of `worktree list --porcelain` is the
        # main worktree; each block carries exactly one branch (or 'detached').
        set -l wt_paths
        set -l wt_branches
        for line in (git -C $target worktree list --porcelain)
            if string match -q 'worktree *' -- $line
                set -a wt_paths (string replace 'worktree ' '' -- $line)
            else if string match -q 'branch refs/heads/*' -- $line
                set -a wt_branches (string replace 'branch refs/heads/' '' -- $line)
            else if test "$line" = detached
                set -a wt_branches ':detached:'
            end
        end

        set -l primary $wt_paths[1]
        if test ! -d "$primary/.git"
            echo "wt-init: $primary/.git is not a real directory — already bare/migrated? Aborting."
            return 1
        end
        if contains ':detached:' $wt_branches
            echo "wt-init: a worktree is in detached HEAD — give it a branch first. Aborting."
            return 1
        end

        # Gate: refuse if any worktree has uncommitted TRACKED changes (a fresh
        # checkout would discard them). Untracked '??' entries are fine — transplanted.
        set -l dirty
        for p in $wt_paths
            set -l changes (git -C $p status --porcelain | string match -rv '^\?\?')
            test (count $changes) -gt 0; and set -a dirty $p
        end
        if test (count $dirty) -gt 0
            echo "wt-init: uncommitted tracked changes in:"
            for p in $dirty; echo "    $p"; end
            echo "Commit or stash them first — the migration re-checks-out tracked files."
            return 1
        end

        # Worktree dir names: branch with '/' -> '-' (unique, since branches are unique).
        set -l slugs
        for b in $wt_branches; set -a slugs (string replace -a '/' '-' -- $b); end

        set -l parent (dirname $primary)
        set -l name (basename $primary)
        set -l final $parent/$name
        set -l tmp $parent/$name.wt-migrate
        set -l hold $parent/$name.wt-hold
        set -l backup $parent/$name-premigration-(date +%Y%m%d-%H%M%S).tar.gz
        for d in $tmp $hold
            if test -e $d
                echo "wt-init: staging path $d already exists — remove it and retry."
                return 1
            end
        end

        # Plan
        echo "wt-init: in-place migration plan"
        echo "  repo    : $primary"
        echo "  final   : $final/{.bare, .git, "(string join ', ' $slugs)"/}"
        echo "  worktrees:"
        for i in (seq (count $slugs))
            echo "      $slugs[$i]  <-  $wt_branches[$i]   (was $wt_paths[$i])"
        end
        echo "  backup  : $backup"
        echo "  effect  : tracked files re-checked-out; untracked+ignored transplanted;"
        echo "            old worktree dirs replaced. Destructive."
        if set -q _flag_dry_run
            echo "wt-init: --dry-run — nothing changed."
            return 0
        end
        if not set -q _flag_yes
            read -l -P "Proceed? [y/N] " ans
            if not string match -qir '^y(es)?$' -- $ans
                echo "wt-init: aborted."
                return 1
            end
        end

        # 1. Backup everything (absolute paths; tar stores them relative).
        echo "wt-init: backing up -> $backup"
        if not tar czf $backup $wt_paths
            echo "wt-init: backup failed — aborting before any change."
            return 1
        end

        # 2. Hold each worktree's files aside (minus .git) so non-tracked files survive.
        mkdir -p $hold
        for i in (seq (count $wt_paths))
            rsync -a --exclude='.git' $wt_paths[$i]/ $hold/$slugs[$i]/
        end

        # 3. Lift the git db out to become the container's bare repo.
        mkdir -p $tmp
        mv $primary/.git $tmp/.bare
        git --git-dir=$tmp/.bare config core.bare true
        printf 'gitdir: ./.bare\n' >$tmp/.git

        # 4. Remove the old checkouts (files safe in $hold + backup). This makes the
        #    secondary worktree registrations prunable.
        for p in $wt_paths; rm -rf $p; end

        # 5. Drop the stale registrations, freeing every branch for re-add.
        git -C $tmp worktree prune

        # 6. Recreate each worktree, then restore its non-tracked files on top.
        for i in (seq (count $slugs))
            if not git -C $tmp worktree add $slugs[$i] $wt_branches[$i]
                echo "wt-init: failed adding worktree $slugs[$i] ($wt_branches[$i])."
                echo "         Nothing overwrote your data — restore from $backup if needed."
                return 1
            end
            rsync -a --ignore-existing --exclude='.git' $hold/$slugs[$i]/ $tmp/$slugs[$i]/
        end

        # 7. Swap into the final name and repair the back-links the rename breaks.
        rm -rf $hold
        mv $tmp $final
        set -l abs
        for s in $slugs; set -a abs $final/$s; end
        git -C $final worktree repair $abs

        echo
        echo "wt-init: migration complete -> $final/{.bare, .git, "(string join ', ' $slugs)"/}"
        git -C $final worktree list
        echo
        echo "Reminders:"
        echo "  • Tracked files now live one level down in $final/<worktree>/."
        echo "    Path-relative tooling moves too — e.g. run builds from $final/$slugs[1]."
        echo "  • Stashes and un-checked-out branches are preserved inside .bare."
        echo "    Resume a stash:  git -C $final worktree add <dir> <branch>"
        echo "                     git -C $final/<dir> stash apply"
        echo "  • If this tree is synced (Syncthing/Dropbox), re-point it at $final, then unpause."
        echo "  • Backup: $backup  (delete once a rebuild/verify confirms all is well)."
        return 0
    end

    # ──────────────────────────────── clone mode ────────────────────────────────
    set -l url $argv[1]

    # Container dir: explicit arg, else the repo name — strip everything up to the
    # last '/' or ':' (handles both https and scp-like SSH urls) and a trailing .git.
    set -l container $argv[2]
    if test -z "$container"
        set container (string replace -r '.*[/:]' '' -- $url | string replace -r '\.git$' '')
    end

    if test -e "$container"
        echo "wt-init: '$container' already exists — pick another name or remove it first."
        return 1
    end

    set -l bare "$container/.bare"

    echo "wt-init: bare-cloning $url -> $bare"
    git clone --bare $url $bare
    or begin
        echo "wt-init: clone failed — nothing left behind."
        return 1
    end

    # The container's .git is a FILE redirecting every git command to the bare db.
    # './.bare' is relative on purpose so renaming the container never breaks it.
    printf 'gitdir: ./.bare\n' >$container/.git

    # A --bare clone does NOT set the usual fetch refspec, so remote branches never
    # populate refs/remotes/origin/* and `worktree add <branch>` can't resolve them.
    # Restore the refspec a normal clone would have, then fetch to fill it.
    git --git-dir=$bare config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git --git-dir=$bare fetch origin

    # A bare clone points HEAD at the remote's default branch — use that as the
    # first worktree; fall back to 'main' if it can't be read.
    set -l default (git --git-dir=$bare symbolic-ref --short HEAD 2>/dev/null)
    test -z "$default"; and set default main

    echo "wt-init: adding worktree '$default'"
    git -C $container worktree add $default $default
    or begin
        echo "wt-init: bare repo is ready but the '$default' worktree failed."
        echo "         Add one by hand: git -C $container worktree add <dir> <branch>"
        return 1
    end

    echo
    echo "wt-init: done -> $container/{.bare, .git, $default/}"
    echo "  cd $container/$default"
end
