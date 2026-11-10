import sys

from qutebrowser.config import configinit

# Links to these sites (and their subdomains) always get a new tab.
EXCEPTIONS = ["youtube.com"]


def site(url):
    host = url.host().lower()
    return host.removeprefix("www.")


def excepted(host):
    return any(host == d or host.endswith("." + d) for d in EXCEPTIONS)


def find_tab(browser, url, skip):
    """An open tab on url's site in a window of the same privacy, exact URL first."""
    from qutebrowser.utils import objreg

    host = site(url)
    if not host or excepted(host):
        return None
    browsers = [browser] + [
        w.tabbed_browser
        for w in objreg.window_registry.values()
        if w.tabbed_browser is not browser and w.tabbed_browser.is_private == browser.is_private
    ]
    tabs = [(b, t) for b in browsers for t in b.widgets() if t is not skip]
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


def catch_first_navigation(browser, tab):
    """A tab from a clicked link starts empty; its URL arrives as its first navigation."""
    from qutebrowser.qt.core import QTimer

    page = tab._widget.page()

    def on_request(navigation):
        if not navigation.is_main_frame:
            return
        page.navigation_request.disconnect(on_request)
        found = find_tab(browser, navigation.url, tab)
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


# Clicked links (middle/ctrl-click, target=_blank, hints) open related tabs; :open -t and
# bookmarks open unrelated ones, which are left alone.
def tabopen(self, url=None, background=None, related=True, idx=None):
    if related and url is not None and url.isValid():
        found = find_tab(self, url, None)
        if found is not None:
            reuse(*found, url)
            return found[1]
    tab = TabbedBrowser._tabreuse_orig(self, url, background, related, idx)
    if related and url is None:
        catch_first_navigation(self, tab)
    return tab


def patch():
    global TabbedBrowser
    from qutebrowser.mainwindow.tabbedbrowser import TabbedBrowser

    # :config-source reruns this file, so wrap the original rather than the last wrapper.
    if not hasattr(TabbedBrowser, "_tabreuse_orig"):
        TabbedBrowser._tabreuse_orig = TabbedBrowser.tabopen
    TabbedBrowser.tabopen = tabopen


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
