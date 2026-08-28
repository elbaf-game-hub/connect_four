# 02 — Assets

All assets come from `package:game_assets`. The module declares a
path-dependency on it in `pubspec.yaml`. The wrapper's `game_assets`
package owns the actual files.

## Source of truth

- **Declarative YAML**: `game_hub_core/game_assets/tool/definitions/connect_four.yaml`
- **Procedural Python**: `game_hub_core/game_assets/tool/generate_tiles.py`
- **Regenerate**:
  ```bash
  cd game_hub_core/game_assets
  python3 tool/generate_svgs.py
  python3 tool/generate_tiles.py
  ```

## Core SVG assets

These are the visual primitives the page must reference. The table
maps each to a file under `game_assets/assets/svg/connect_four/`.

| File | Size | Purpose |
| --- | --- | --- |
| `board.svg` | 420x420 | 7×6 wooden-blue board with 42 dark holes |
| `piece_red.svg` | 48x48 | Red token |
| `piece_yellow.svg` | 48x48 | Yellow token |
| `piece_red_winner.svg` | 48x48 | Red token highlighted (winner cell) |
| `piece_yellow_winner.svg` | 48x48 | Yellow token highlighted |

## Fonts

System default.

## How the page loads an asset

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/svg/connect_four/<file>.svg',
  package: 'game_assets',
  width: 48,
)
```

## Asset budget

- **Hard cap**: total `assets/` in this module ≤ 200 KB
  (CI step in `game_hub_wrapper/.github/workflows/ci.yml`).
- This module's known usage: see sizes in the table above.
