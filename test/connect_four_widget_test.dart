import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_four/connect_four.dart';

void main() {
  group('ConnectFour Widget Tests', () {
    testWidgets('ConnectFour page renders properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectFourPage(),
        ),
      );

      // Verify title & app bar
      expect(find.text('Connect Four'), findsOneWidget);
      expect(find.byType(ConnectFourPage), findsOneWidget);

      // Verify mode selector buttons
      expect(find.text('vs AI'), findsOneWidget);
      expect(find.text('2 Player'), findsOneWidget);

      // Verify board grid
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('Dropping a token updates the rendered board in 2-Player mode',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectFourPage(),
        ),
      );

      // Switch to 2 Player mode
      await tester.tap(find.text('2 Player'));
      await tester.pumpAndSettle();

      expect(find.text('Red’s Turn'), findsOneWidget);

      // Tap on slot 3 (column 3)
      final gridFinders = find.byType(GestureDetector);
      await tester.tap(gridFinders.at(5)); // A slot in the grid
      await tester.pumpAndSettle();

      // Now it should be Yellow's Turn
      expect(find.text('Yellow’s Turn'), findsOneWidget);

      // Tap again as Yellow
      await tester.tap(gridFinders.at(5));
      await tester.pumpAndSettle();

      // Back to Red's Turn
      expect(find.text('Red’s Turn'), findsOneWidget);
    });

    testWidgets('Restart button resets the board', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectFourPage(),
        ),
      );

      // Tap restart icon
      final restartBtn = find.byTooltip('Restart');
      await tester.tap(restartBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ConnectFourPage), findsOneWidget);
    });
  });
}
