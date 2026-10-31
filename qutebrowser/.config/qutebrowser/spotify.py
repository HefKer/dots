import subprocess

from qutebrowser.api import interceptor

# open.spotify.com's other pages have no spotify: URI, so they stay in the browser.
SPOTIFY_TYPES = {
    "album",
    "artist",
    "episode",
    "playlist",
    "show",
    "socialsession",
    "track",
    "user",
}


# qutebrowser is the default browser, so this catches links clicked in any app.
def open_in_spotify(request):
    url = request.request_url
    if (
        request.is_blocked  # interceptors can't be removed, so :config-source stacks them
        or url.host() != "open.spotify.com"
        or request.resource_type != interceptor.ResourceType.main_frame
    ):
        return
    parts = [p for p in url.path().split("/") if p and not p.startswith("intl-")]
    if len(parts) < 2 or parts[0] not in SPOTIFY_TYPES:
        return
    request.block()
    subprocess.Popen(["xdg-open", "spotify:" + ":".join(parts)], start_new_session=True)


interceptor.register(open_in_spotify)
