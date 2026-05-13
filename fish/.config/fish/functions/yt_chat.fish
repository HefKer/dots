function yt_chat --description "Chat about a YouTube video transcript in Claude Code"
    if test (count $argv) -eq 0
        echo "Usage: yt_chat <video_id_or_url>"
        return 1
    end

    set video_id (__extract_yt_id $argv[1])

    set tmpfile /tmp/yt_transcript_$video_id.txt

    echo "Fetching transcript for $video_id..."
    youtube_transcript_api $video_id --format json \
        | jq -r '.[][].text' \
        | tr '\n' ' ' >$tmpfile

    if test $status -ne 0 -o ! -s $tmpfile
        echo "Failed to fetch transcript"
        return 1
    end

    claude "I want to discuss a YouTube video (ID: $video_id). The transcript is at $tmpfile — please read it, then let's chat about it."
end
