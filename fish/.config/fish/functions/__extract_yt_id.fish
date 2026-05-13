function __extract_yt_id
    set url $argv[1]
    if string match -q "*youtube.com*" $url
        string replace -r '.*[?&]v=([^&]+).*' '$1' $url
    else if string match -q "*youtu.be*" $url
        string replace -r '.*youtu\.be/([^?]+).*' '$1' $url
    else
        echo $url
    end
end
