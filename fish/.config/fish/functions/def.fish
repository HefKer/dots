function def --description "Look up a word/phrase definition via translate-shell (online)"
    argparse f/full -- $argv
    or return 1

    if test (count $argv) -eq 0
        echo "Usage: def [-f|--full] <word|phrase>"
        echo "  def eigenvalue            # lean: defs + inline synonyms"
        echo "  def -f string             # full: adds grouped synonyms + usage examples"
        echo "  def 'machine learning'    # quote multi-word phrases"
        return 1
    end

    if not command -q trans
        echo "def: 'trans' (translate-shell) not found on PATH — add it in ~/nixos/"
        return 1
    end

    # -d :en = English dictionary mode. Join argv so an unquoted multi-word
    # call still lands as one lookup string.
    #   -show-original-phonetics n  drop the /striNG/ pseudo-phonetic line
    #   -no-warn                    silence lang-guess warnings
    #   less -RF                    keep color; skip pager when it fits one screen
    set -l base trans -d :en -show-original-phonetics n -no-warn (string join ' ' $argv)

    if set -q _flag_full
        # Full: everything, incl. trailing grouped Synonyms + Examples blocks.
        $base | less -RF
    else
        # Lean (default): chop the trailing col-0 Synonyms/Examples dumps.
        # Keeps per-sense defs + each sense's inline synonyms.
        $base | awk '/^(Synonyms|Examples)$/{exit} {print}' | less -RF
    end
end
