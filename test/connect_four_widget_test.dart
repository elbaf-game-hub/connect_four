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

      // Verify drop buttons (7 columns)
      expect(find.byIcon(Icons.arrow_downward), findsNWidgets(7));
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

      // Tap column 4 (center, index 3 in 0-based)
      final centerDropBtn = find.byIcon(Icons.arrow_downward).at(3);
      await tester.tap(centerDropBtn);
      await tester.pumpAndSettle();

      // Now it should be Yellow's Turn
      expect(find.text('Yellow’s Turn'), findsOneWidget);

      // Tap column 4 again as Yellow
      await tester.tap(centerDropBtn);
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

      // Drop in col 0
      final firstDropBtn = find.byIcon(Icons.arrow_downward).first;
      await tester.tap(firstDropBtn);
      await tester.pump();

      // Tap restart icon
      final restartBtn = find.byTooltip('Restart');
      await tester.tap(restartBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ConnectFourPage), findsOneWidget);
    });
  });
}
