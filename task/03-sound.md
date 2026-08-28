# 03 — Sound

Audio plays through `SfxPlayer` from `package:game_assets`. Each
`.wav` lives in `game_assets/assets/sfx/`. Generated procedurally
by `tool/synth_sfx.py` — no licensed audio.

## Trigger map

| Event | File | Notes |
| --- | --- | --- |
| Drop | `tap.wav` | On any drop |
| Win | `win.wav` | On four-in-a-row |

## How to play

```dart
import 'package:game_assets/game_assets.dart';

SfxPlayer.instance.play('eat');   // fire and forget
SfxPlayer.instance.setMuted(true); // for a 'mute SFX' settings toggle
```

## Performance

- Each call to `SfxPlayer.play()` stops any currently-playing SFX
  and starts the new one. There is no overlapping. If you need
  overlaps (e.g. rapid tap→tap→tap), call `play()` in a fire-and-
  forget Future and ignore the await.
- `audioplayers` is initialized lazily on first use. No setup in
  the page constructor.

## What if the asset is missing?

`SfxPlayer.play()` swallows the exception silently. So a missing
file = silent, not crash. The CI step `flutter test` still fails
on missing assets because the test loads `pubspec.yaml`'s asset
list explicitly.
