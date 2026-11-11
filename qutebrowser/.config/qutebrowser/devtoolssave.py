# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
from qutebrowser.config import configinit

_late_init = configinit.late_init
_source = (config.configdir / "js" / "devtools-save.js").read_text()


# DevTools can't save files in QtWebEngine (Export HAR, Save as do nothing), so every profile gets
# js/devtools-save.js, which turns those saves into downloads. Profiles are made after late_init,
# so it wraps their setup; imports wait for late_init, as in injectfix.py.
def late_init(*args, **kwargs):
    from qutebrowser.browser.webengine import webenginesettings
    from qutebrowser.qt.webenginecore import QWebEngineScript

    init_profile = webenginesettings._init_profile

    def init_profile_with_save(profile):
        init_profile(profile)
        script = QWebEngineScript()
        script.setName("devtools-save")
        script.setSourceCode(_source)
        script.setWorldId(QWebEngineScript.ScriptWorldId.MainWorld)
        profile.scripts().insert(script)

    webenginesettings._init_profile = init_profile_with_save
    _late_init(*args, **kwargs)


configinit.late_init = late_init
