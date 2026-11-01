from qutebrowser.config import configinit

_late_init = configinit.late_init


# QtWebEngine skips a page's scripts after a cross-site navigation, which leaves hints, scrolling and
# userscripts dead in that tab (qutebrowser#8925), but it runs the profile's. Drop this once that's fixed.
# It waits for late_init because qutebrowser discards any module first imported while reading the config.
def late_init(*args, **kwargs):
    from qutebrowser.browser.webengine import webenginetab, webview

    webview.WebEnginePage.scripts = lambda self: self.profile().scripts()
    inject_js = webenginetab._WebEngineScripts._inject_js

    # Every tab injects its scripts, and they now land in one shared collection.
    def inject_js_once(self, name, *args, **kwargs):
        self._remove_js(name)
        inject_js(self, name, *args, **kwargs)

    webenginetab._WebEngineScripts._inject_js = inject_js_once
    _late_init(*args, **kwargs)


configinit.late_init = late_init
