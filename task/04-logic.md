# 04 — Logic

> The engine lives in `lib/src/connect_four_state.dart`. **No imports of
> `package:flutter/*` allowed in this file.** The page imports the
> state, not the other way around.

## Class diagram

```
connect_four_state.dart (pure Dart)
  └── classes listed below
connect_four_page.dart (Flutter)
  └── owns the State subclass that wraps connect_four_state
```

## Classes

### `Player`

enum { red, yellow }

### `ConnectFourStatus`

enum { playing, won, draw }

### `Cell`

Player? value

### `ConnectFourState`

static const rows=6, cols=7; List<Player?> board (42, row-major); Player current; ConnectFourStatus status; List<int>? winningLine. Methods: drop(int col), validDrops(), isFull().

### `ConnectFourAI`

Negamax with alpha-beta pruning, depth param, move ordering by center column preference, simple score: +100 per 4, +10 per 3 with open end, +1 per 2 with open end, etc.

## Hard rules

1. **No `Widget` or `BuildContext` references** in the state file.
   If a UI helper is needed, put it in `*_page.dart`.
2. **No `import 'package:flutter/...'`** in the state file.
   Use only `dart:core`, `dart:math`, `dart:collection`.
3. **Constructor takes everything it needs** — no global state.
   The page passes initial values and listens via `Stream` or
   `Listenable` if needed.
4. **Methods return new state, not mutate** when possible. For
   performance-critical loops (e.g. 2048 slide), in-place mutation
   is OK as long as the previous state is captured for undo.
5. **Seedable RNG** for any shuffle/random. Use `Random(seed)` so
   tests can be deterministic.

## Integration with the page

```dart
class ConnectFourPage extends StatefulWidget {{
  const ConnectFourPage({{super.key}});
  @override
  State<ConnectFourPage> createState() => _ConnectFourPageState();
}}

class _ConnectFourPageState extends State<ConnectFourPage> {{
  late ConnectFourState _state;

  @override
  void initState() {{
    super.initState();
    _state = ConnectFourState.initial();
  }}

  void _onAction(...) {{
    setState(() {{
      _state = _state.copyWith(...);
    }});
    SfxPlayer.instance.play('tap');
  }}

  @override
  Widget build(BuildContext context) => /* see 05-ui.md */;
}}
```
