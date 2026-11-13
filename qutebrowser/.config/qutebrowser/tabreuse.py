import sys

from qutebrowser.config import configinit

# Only links to these sites (and their subdomains) reuse an open tab. A site served on a
# non-default port is named host:port, so other servers on the same host are left alone.
REUSE = ["osugacha.com", "127.0.0.1:7271"]  # osug dashboard


def site(url):
    host = url.host().lower().removeprefix("www.")
    port = url.port()
    return f"{host}:{port}" if host and port != -1 else host


def reusable(host):
    return any(host == d or host.endswith("." + d) for d in REUSE)


def all_tabs(browser):
    """(browser, tab) for every tab in windows of browser's privacy, browser's own first."""
    from qutebrowser.utils import objreg

    browsers = [browser] + [
        w.tabbed_browser
        for w in objreg.window_registry.values()
        if w.tabbed_browser is not browser and w.tabbed_browser.is_private == browser.is_private
    ]
    return [(b, t) for b in browsers for t in b.widgets()]


def route(url):
    """Site and path, ignoring query, fragment and a trailing slash."""
    return site(url), url.path().rstrip("/")


def find_tab(browser, url, skip):
    """An open tab on url's site in a window of the same privacy, exact URL first.

    skip is a tab (or tabs) never to match: the new tab itself and the tab the link was
    clicked in, so a same-site link can't navigate its own source tab."""
    host = site(url)
    if not host or not reusable(host):
        return None
    skip = skip if isinstance(skip, tuple) else (skip,)
    tabs = [(b, t) for b, t in all_tabs(browser) if t not in skip]
    same_site = [(b, t) for b, t in tabs if site(t.url()) == host]
    exact = [(b, t) for b, t in same_site if t.url() == url]
    return (exact or same_site or [None])[0]


def reuse(browser, tab, url):
    """Focus tab, navigating it to url unless it is already there."""
    browser.widget.setCurrentWidget(tab)
    window = browser.window()
    window.activateWindow()
    window.raise_()
    if tab.url() != url:
        tab.load_url(url)


def catch_first_navigation(browser, tab, source):
    """A tab from a clicked link starts empty; its URL arrives as its first navigation."""
    from qutebrowser.qt.core import QTimer

    page = tab._widget.page()

    def on_request(navigation):
        if not navigation.is_main_frame:
            return
        page.navigation_request.disconnect(on_request)
        found = find_tab(browser, navigation.url, (tab, source))
        if found is None:
            return
        navigation.accepted = False
        url = navigation.url

        # Closing the tab inside Qt's navigation callback would delete the page under it.
        def swap():
            browser.close_tab(tab, add_undo=False)
            reuse(*found, url)

        QTimer.singleShot(0, swap)

    page.navigation_request.connect(on_request)


# Clicked links (target=_blank, hints) open related tabs; :open -t and bookmarks open
# unrelated ones, which are left alone. Background opens (middle-click) always get a new
# tab: asking for one in the background is asking not to be moved.
def tabopen(self, url=None, background=None, related=True, idx=None):
    reusing = related and not background
    source = self.widget.currentWidget()
    if reusing and url is not None and url.isValid():
        found = find_tab(self, url, source)
        if found is not None:
            reuse(*found, url)
            return found[1]
    tab = TabbedBrowser._tabreuse_orig(self, url, background, related, idx)
    if reusing and url is None:
        catch_first_navigation(self, tab, source)
    return tab


# URLs from outside (xdg-open, e.g. osug watch's notification actions) arrive over IPC
# through app.open_url, which opens an unrelated tab, so reuse is checked here.
def open_url(url, target=None, no_raise=False, via_ipc=True):
    from qutebrowser import app
    from qutebrowser.mainwindow import mainwindow
    from qutebrowser.utils import objreg

    try:
        window = objreg.last_focused_window()
    except objreg.NoWindow:
        window = None
    found = window and url.isValid() and find_tab(window.tabbed_browser, url, ())
    if not found:
        return app._tabreuse_open_url(url, target, no_raise, via_ipc)
    reuse(*found, url)
    window = found[0].window()
    if not no_raise:
        mainwindow.raise_window(window)
    return window


# Every site, unlike REUSE: a quickmark whose route is already open focuses that tab, left
# as it is, instead of loading again. -b still opens a new background tab.
def quickmark_load(dispatcher, name, tab=False, bg=False, window=False):
    from qutebrowser.browser import urlmarks
    from qutebrowser.utils import objreg

    if not bg:
        try:
            url = objreg.get("quickmark-manager").get(name)
        except urlmarks.Error:
            url = None
        if url is not None and url.isValid():
            want = route(url)
            browser = dispatcher._tabbed_browser
            found = next((bt for bt in all_tabs(browser) if route(bt[1].url()) == want), None)
            if found is not None:
                browser_, tab_ = found
                browser_.widget.setCurrentWidget(tab_)
                browser_.window().activateWindow()
                browser_.window().raise_()
                return
    return _quickmark_load_orig(dispatcher, name, tab, bg, window)


def patch():
    global TabbedBrowser, _quickmark_load_orig
    from qutebrowser import app
    from qutebrowser.mainwindow.tabbedbrowser import TabbedBrowser
    from qutebrowser.misc import objects

    # The command keeps the handler it was registered with, so patch that, not the class.
    cmd = objects.commands["quickmark-load"]
    if not hasattr(cmd, "_tabreuse_orig"):
        cmd._tabreuse_orig = cmd.handler
    _quickmark_load_orig = cmd._tabreuse_orig
    cmd.handler = quickmark_load

    # :config-source reruns this file, so wrap the original rather than the last wrapper.
    if not hasattr(TabbedBrowser, "_tabreuse_orig"):
        TabbedBrowser._tabreuse_orig = TabbedBrowser.tabopen
    TabbedBrowser.tabopen = tabopen
    if not hasattr(app, "_tabreuse_open_url"):
        app._tabreuse_open_url = app.open_url
    app.open_url = open_url


# At startup the module isn't loaded yet, and one first imported while the config is read
# is discarded afterwards, so wait for late_init (see injectfix.py).
if "qutebrowser.mainwindow.tabbedbrowser" in sys.modules:
    patch()
else:
    _late_init = configinit.late_init

    def late_init(*args, **kwargs):
        patch()
        _late_init(*args, **kwargs)

    configinit.late_init = late_init
