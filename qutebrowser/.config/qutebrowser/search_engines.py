# Search engines
c.url.open_base_url = True
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "y": "https://www.youtube.com/results?search_query={}",
    "gh": "https://github.com/search?o=desc&q={}&s=stars",
    # Nix
    "nix": "https://search.nixos.org/packages?channel=unstable&include_modular_service_options=1&include_nixos_options=1&query={}",
    # Google stuff
    "g": "https://www.google.com/search?q={}",
    "g.m": "https://www.google.com/maps?q={}",
    "g.s": "https://scholar.google.com/scholar?q={}",
    # Wikis
    "wiki": "https://www.wikipedia.org/w/index.php?search={}",
    "aw": "https://wiki.archlinux.org/?search={}",
    # Game wikis
    "sv": "https://wiki.stardewvalley.net/mediawiki/index.php?search={}&title=Special%3ASearch&go=Go",
    # Shopping
    "amazon": "https://www.amazon.com/s?k={}",
    "amz": "https://www.amazon.com/s?k={}",
    "aliexpress": "https://www.aliexpress.com/wholesale?SearchText={}",
    "rb": "https://www.redbubble.com/shop/{}",
    "redbubble": "https://www.redbubble.com/shop/{}",
    # Socials
    "linkedin": "https://www.linkedin.com/search/results/all/?keywords={}&origin=GLOBAL_SEARCH_HEADER",
    "li": "https://www.linkedin.com/search/results/all/?keywords={}&origin=GLOBAL_SEARCH_HEADER",
}

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
