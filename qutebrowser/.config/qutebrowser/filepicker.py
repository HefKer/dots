import shutil


# Use ranger/yazi as file picker (using wezterm)
# Idea from [Qutebrowser + Ranger = Pure Awesome - YouTube](https://www.youtube.com/watch?v=ce2NOmTBWfo)
def file_picker(manager="yazi"):
    wezterm = shutil.which("wezterm")
    shell = shutil.which("fish") or shutil.which("bash")

    if manager == "yazi":
        bin = shutil.which("yazi")
        if not all([wezterm, shell, bin]):
            return None, None
        cmd = [
            wezterm,
            "start",
            "--always-new-process",
            "--class",
            "yazi",
            "--",
            shell,
            "-c",
            f"{bin} --chooser-file={{}}",
        ]
        return cmd, cmd

    elif manager == "ranger":
        bin = shutil.which("ranger")
        if not all([wezterm, shell, bin]):
            return None, None
        single = [
            wezterm,
            "start",
            "--always-new-process",
            "--class",
            "ranger",
            "--",
            shell,
            "-c",
            f"{bin} --choosefile={{}}",
        ]
        multiple = [
            wezterm,
            "start",
            "--always-new-process",
            "--class",
            "ranger",
            "--",
            shell,
            "-c",
            f"{bin} --choosefiles={{}}",
        ]
        return single, multiple

    return None, None


single, multiple = file_picker("yazi")
if single and multiple:
    config.set("fileselect.handler", "external")
    config.set("fileselect.single_file.command", single)
    config.set("fileselect.multiple_files.command", multiple)

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
