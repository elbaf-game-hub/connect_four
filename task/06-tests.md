# 06 — Tests

Two test files: `test/connect_four_state_test.dart` (engine) and
`test/connect_four_widget_test.dart` (page).

## Engine tests (state)

> Target: ≥90% line coverage on `lib/src/connect_four_state.dart`.

1. Initial board is 42 nulls, current = red, status = playing
2. validDrops() returns only non-full columns
3. drop(col) on a non-full column places the token at the lowest empty row in that column
4. drop(col) on a full column is a no-op
5. Horizontal win: board[2][0..3] = red → status = won, winningLine = [2,0,2,1,2,2,2,3]
6. Vertical win: 4 in a column
7. Diagonal win: both directions
8. draw when board is full and no winner
9. Current toggles after every drop
10. AI: doesn't drop into a full column
11. AI: finds forced win in 1 (depth 2)
12. AI: blocks opponent's forced win in 1
13. Widget test: dropping a token updates the rendered board

## Widget tests (page)

A minimal smoke test that the page renders and the primary
interaction works:

```dart
// test/connect_four_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_four/connect_four.dart';

void main() {
  testWidgets('ConnectFour page renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConnectFourPage()));
    expect(find.byType(ConnectFourPage), findsOneWidget);
  });
}
```

## Coverage bar

```bash
cd game_hub_modules/connect_four
flutter test --coverage
# open coverage/lcov-report.html
```

Required: lines covered on `lib/src/connect_four_state.dart` ≥ 90%.
The CI step in the wrapper fails the build otherwise.

## What NOT to test

- Pure widget rendering details (e.g. "the title is centered").
- SFX firing (you'd have to mock `audioplayers`; not worth it).
- The `GameModule` descriptor — it's a static const.

## How to run a single test

```bash
flutter test test/connect_four_state_test.dart --plain-name "tap places"
```
