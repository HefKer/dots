"""Write qutebrowser commands to $QUTE_FIFO without letting text add commands.

Imported by the Python userscripts beside it. Not executable, so it is no
userscript itself.

A FIFO line is a command line. Before any quoting is looked at, qutebrowser
splits it on CR/LF (one command per line) and on `;;` (unless the first command
is no_cmd_split, which message-* and open aren't), then lexes the arguments
shell-style and substitutes `{url}`, `{title}`, ... in each of them. So a page
title with `x ;; spawn ...` in it runs that spawn, and quoting alone can't stop
it. text_arg and url_arg make a string arrive as exactly one argument.
"""

import os
import re
import shlex

# Variables qutebrowser substitutes in command arguments (commands/runners.py).
# `{{url}}` comes out as the literal `{url}`.
_VARIABLES = (
    "url", "url:pretty", "url:domain", "url:auth", "url:scheme", "url:username",
    "url:password", "url:host", "url:port", "url:path", "url:query", "url:yank",
    "title", "clipboard", "primary",
)
_VARIABLE_RE = re.compile("{(" + "|".join(re.escape(v) for v in _VARIABLES) + ")}")

# Between the two semicolons of `;;`: invisible and no line break, so the message
# reads the same while the line no longer holds the separator.
_WORD_JOINER = "⁠"


def _escape_variables(text):
    return _VARIABLE_RE.sub(r"{{\1}}", text)


def _encodable(text):
    # A lone surrogate (an undecodable byte in the environment) can't be written.
    return text.encode("utf-8", "replace").decode("utf-8")


def text_arg(text):
    """Free text as one quoted argument; shows as the same text."""
    text = re.sub(r"\r\n|[\r\n]", " ", _encodable(text))
    text = text.replace(";;", f";{_WORD_JOINER};").replace(";;", f";{_WORD_JOINER};")
    return shlex.quote(_escape_variables(text))


# Encoded rather than quoted: open and other maxsplit commands take the rest of
# the line raw, quotes included, while the others lex it shell-style. A URL with
# none of these characters is one argument to both. `;` only where it would
# form `;;`, and `-` only leading, where it would read as a flag.
_URL_UNSAFE = re.compile(r"""[\s'"\\]|;(?=;)|^-""")


def url_arg(url):
    """A URL as one argument, unquoted, percent-encoding what would split it."""
    url = _URL_UNSAFE.sub(lambda m: "".join(f"%{b:02X}" for b in m.group().encode()), _encodable(url))
    return _escape_variables(url)


def send(*commands):
    """Write each command as a line; False when not run by qutebrowser."""
    fifo = os.environ.get("QUTE_FIFO")
    if not fifo:
        return False
    with open(fifo, "a", encoding="utf-8") as f:
        f.writelines(f"{command}\n" for command in commands)
    return True


def message(level, text):
    """Show text in the status bar: level is info, warning or error."""
    return send(f"message-{level} {text_arg(text)}")
