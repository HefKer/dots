// Adjust the page's video: (action, step) => status message. binds.py wraps
// this in a call and runs it in the main world, where YouTube's player API is
// reachable; setting <video>.volume behind the player's back leaves its own
// volume state and slider stale.
//   speed:  step is added to playbackRate; 0 resets to 1x
//   volume: step is added to the volume, as a fraction of full
// Its lines get joined into one, so comments must sit on lines of their own.
(action, step) => {
  const clamp = (lo, x, hi) => Math.min(hi, Math.max(lo, x));
  const player = document.getElementById('movie_player');
  const v = player?.querySelector('video') || document.querySelector('video');
  if (!v) return 'no video';

  if (action === 'speed') {
    v.playbackRate = step === 0 ? 1 : clamp(0.25, v.playbackRate + step, 4);
    return `speed ${v.playbackRate}x`;
  }

  if (player?.setVolume) {
    const volume = clamp(0, player.getVolume() + step * 100, 100);
    player.unMute();
    player.setVolume(volume);
    return `volume ${volume}%`;
  }
  v.muted = false;
  v.volume = clamp(0, v.volume + step, 1);
  return `volume ${Math.round(v.volume * 100)}%`;
}
