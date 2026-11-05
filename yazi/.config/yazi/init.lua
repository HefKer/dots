-- Runs at startup: plugin setup calls and Lua UI overrides.

-- Git status signs in the file list; the fetchers that feed it are in yazi.toml.
require("git"):setup({ order = 1500 })

-- Report the cwd to WezTerm (OSC 7), so new WezTerm tabs and splits open where yazi is.
require("term-cwd"):setup()

-- Vim counts (5j, 3k); numbers before each file, the pending motion in the status bar.
-- Installed from Jormala's fork: upstream dedukun still calls ya.mgr_emit, removed in yazi 26 (fix pending as dedukun PR #32).
require("relative-motions"):setup({ show_numbers = "relative", show_motion = true })
