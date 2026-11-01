import functools
import os.path

from qutebrowser.utils import message, objreg, usertypes, utils


def write_pdf(data, path):
    path = os.path.expanduser(path)
    try:
        with open(path, "wb") as f:
            f.write(data)
    except OSError as e:
        message.error(f"Printing to {path} failed: {e}")
    else:
        message.info(f"Printed to {path}")


def ask_pdf_path(tab, data):
    from qutebrowser.browser import downloads  # see the note on register below

    if not data:
        message.error("Printing failed!")
        return
    name = utils.sanitize_filename(tab.title() or "print", shorten=True) + ".pdf"
    message.ask_async(
        "Print frame to PDF:",
        usertypes.PromptMode.text,
        functools.partial(write_pdf, data),
        default=os.path.join(downloads.download_dir(), name),
    )


# qutebrowser only handles window.print() in the top frame, and a page's print button
# often calls it in a frame: Qt reports that as printRequestedByFrame, which nothing
# connects to, so the button does nothing. QWebEnginePage.print() can't target a frame,
# which leaves saving it as a PDF. Render before asking, since the frame PyQt passes
# doesn't outlive this signal.
def on_print_requested_by_frame(tab, frame):
    frame.printToPdf(functools.partial(ask_pdf_path, tab))


def connect_frame_print(tab, connect_signals):
    connect_signals()
    tab._widget.page().printRequestedByFrame.connect(
        functools.partial(on_print_requested_by_frame, tab)
    )


# qutebrowser unloads what the config imports once the config has run, so patching
# WebEngineTab here would only reach a copy tabs aren't made from. objreg is loaded
# before the config, and tabs register in it before connecting their signals.
# :config-source reruns this file, so wrap the original rather than the last wrapper.
orig_register = getattr(objreg, "orig_register", objreg.register)
objreg.orig_register = orig_register


def register(name, obj, **kwargs):
    orig_register(name, obj, **kwargs)
    if name == "tab":
        obj._connect_signals = functools.partial(
            connect_frame_print, obj, obj._connect_signals
        )


objreg.register = register
