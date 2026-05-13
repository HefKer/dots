function yt_summarize --description "Summarize a YouTube video transcript"
    if test (count $argv) -eq 0
        echo "Usage: yt_summarize <video_id_or_url>"
        return 1
    end

    set video_id (__extract_yt_id $argv[1])

    youtube_transcript_api $video_id --format json \
        | jq -r '.[][].text' \
        | tr '\n' ' ' \
        | claude --model haiku -p "summarize this transcript"
end
