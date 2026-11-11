function __extract_yt_id --description "Print the 11-char YouTube video ID in a URL or bare ID; fail if there is none"
    set id (string match -r -g '(?:^|[?&]v=|youtu\.be/|/(?:shorts|embed|live)/)([A-Za-z0-9_-]{11})(?:$|[^A-Za-z0-9_-])' -- $argv[1])
    or begin
        echo "not a YouTube video ID or URL: $argv[1]" >&2
        return 1
    end
    echo $id[1]
end
