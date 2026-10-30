# YouTube anti-adblock

What YouTube detects in this setup, and how to find the next thing it starts
detecting. The scripts involved are `greasemonkey/youtube-prune.js` (ports
uBO's YouTube filters) and `greasemonkey/youtube-ab.js` (skips ads that get
through, removes popups). `ubo-scriptlets` excludes youtube.com, and network
blocking (`content.blocking`) has never been the cause.

## Known detections

Each of these gets the enforcement screen served. Keep them out of the scripts:

- **Hiding `#player-ads`** with CSS (since 2026-10-28). uBO keeps it shown with
  `youtube.com#@##player-ads`. Hiding other ad containers tested fine.
- **Altering the ad keys of the real `/player` fetch response** (since
  2026-10-28). Deleting `adPlacements`, `adSlots` or `playerAds`, or renaming
  even one character of them, is detected; a parse/stringify round trip or a
  rebuilt `Response` with the same text is not. `youtube-prune` leaves
  `/player` out of `FETCH_URL`, so pre-roll ads load and `youtube-ab` mutes,
  speeds up and seeks past them.
- **Bait responses.** YouTube posts extra `/player` requests whose responses
  are placeholders like `{"adPlacements":true,"playerAds":true,...}` and checks
  that they come back intact. `isBait()` in `youtube-prune` passes them
  through unaltered.

Hooking `fetch` itself (a pass-through Proxy) and an empty userscript at any
`@run-at` are both fine.

## The enforcement screen

The block is the player's error screen ("Ad blockers violate YouTube's Terms of
Service", buttons "Allow YouTube Ads" / "Try YouTube Premium"). In the player
response it is `playabilityStatus.status: "ERROR"` with
`playabilityStatus.errorScreen.enforcementMessageViewModel`. The older form,
`UNPLAYABLE` with a `playerErrorMessageRenderer` linking
`support.google.com/youtube/answer/3037019`, is what uBO's antiSsap was written
for. `youtube-prune`'s antiSsap retries both with the next userAgent strategy,
but `loadVideoById` sends no new `/player` request for the new form, so the
retry doesn't clear it. Fix the trigger instead.

YouTube enforces mainly on signed-in sessions. A private window playing
therefore says "signed out", not "the scripts are innocent": greasemonkey
scripts run in private windows too.

## Finding a new trigger

Bisect in a throwaway qutebrowser instance on a copy of the profile, so the
user's windows are left alone and the copy can be broken freely. The step is
done when a single selector, hook or response edit flips the probe between
`OK` and `ERROR`.

1. **Start.** Use `scripts/qute-sandbox`, which copies the profile:

   ```sh
   scripts/qute-sandbox start --profile 'https://www.youtube.com/watch?v=<id>'
   ```

   Replace the `config/greasemonkey` link in its basedir with a folder of
   chosen scripts or links to them; the real folder stays untouched.
   `data/greasemonkey` holds the generated `ubo-scriptlets.js`.

2. **Probe.**

   ```sh
   scripts/qute-sandbox eval '(()=>{const r=document.getElementById("movie_player").getPlayerResponse();
   return {status:r.playabilityStatus.status,err:r.playabilityStatus.errorScreen&&Object.keys(r.playabilityStatus.errorScreen)};})()'
   ```

   After each change run `:greasemonkey-reload` and `:reload -f` through
   `qute-sandbox cmd`, then wait about 18 s before probing. Probe too early and
   `getPlayerResponse` isn't there yet. The title trick behind `eval` also works
   on the main instance, but only on its *active* tab: check `$QUTE_URL` first,
   since the user may switch tabs mid-test.

3. **Bisect.** Start with no scripts (expect `OK`), then add one script at a
   time. Inside a script, cut sections (fetch hook, XHR hooks, initial-response
   setters, JSON hooks, antiSsap, CSS, …) by halves, then narrow with minimal
   test userscripts. Re-run the no-scripts control whenever results look
   uniform: a flag that sticks would fake a trigger everywhere.

4. **Compare with uBO.** `filters/quick-fixes.txt` in uBlockOrigin/uAssets
   holds the current YouTube rules, and issue #30157 is the live YouTube
   thread. A `#@#` exception or a disabled rule there often names the
   trigger.

## Ruled out

Clearing YouTube's cookies (VISITOR_INFO1_LIVE, YSC, `__Secure-*`) and its
IndexedDB did not help (2026-10-21 session). Neither did force-reloading past
the service worker and HTTP cache.
