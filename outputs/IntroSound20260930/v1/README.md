# Frostfall intro audio

Original synthesized sound effects and a short winter-themed score. No external sound samples.

- frostfall-intro.wav: finished 7.9-second stereo mix, 48 kHz / 16-bit PCM.
- frostfall-intro.mp3: compressed listening copy.
- intro-sfx-only.wav and intro-music-only.wav: separate stems for adjustment.
- cues/: individual effect files. cue-timing.json uses cinematic-relative seconds.
- Preview video is in outputs/IntroSound20260930/frostfall-animation-with-sound.mp4.

Preview timing: cinematic begins approximately 1.75 seconds into the supplied screen recording. Snow impact lands at 3.25 seconds; shovel release at 6.97 seconds. The original video stream is retained, audio replaced, original recording unchanged.

Roblox integration pending: upload the WAV under the experience owner and grant the experience audio access. Assign its usable Roblox audio ID; preload it with the intro assets. Play locally at the actual cinematic time origin, not when the loading screen appears, and stop/destroy on completion, Skip, respawn or failure. Do not change the existing music-after-intro gate. Never use this recording's 1.75-second offset inside the game.

Verification: decoded source clip frames used for synchronization; source audio essentially silent. Files are synthesized and digitally checked for finite samples, peak/headroom, durations and successful video remux. Human listening and in-game speaker playback remain to be checked. Nothing uploaded, changed in Studio, saved or published.
