import 'package:flutter_test/flutter_test.dart';
import 'package:connect_four/connect_four.dart';

void main() {
  group('ConnectFourState & ConnectFourAI Unit Tests', () {
    test('Initial state: 42 empty slots, Red first, status playing', () {
      final state = ConnectFourState.initial();
      expect(state.board.length, 42);
      expect(state.board.every((slot) => slot == null), isTrue);
      expect(state.current, Player.red);
      expect(state.status, ConnectFourStatus.playing);
      expect(state.winner, isNull);
      expect(state.winningLine, isNull);
      expect(state.winsRed, 0);
      expect(state.winsYellow, 0);
      expect(state.draws, 0);
      expect(state.validDrops(), [0, 1, 2, 3, 4, 5, 6]);
      expect(state.isFull(), isFalse);
    });

    test('Player opponent getter', () {
      expect(Player.red.opponent, Player.yellow);
      expect(Player.yellow.opponent, Player.red);
    });

    test('Helper coordinate converters (indexAt, rowOf, colOf)', () {
      expect(ConnectFourState.indexAt(2, 3), 17);
      expect(ConnectFourState.rowOf(17), 2);
      expect(ConnectFourState.colOf(17), 3);
    });

    test('validDrops and isColumnFull correctly track column capacity', () {
      var state = ConnectFourState.initial();
      for (var i = 0; i < 6; i++) {
        expect(state.isColumnFull(0), isFalse);
        state = state.drop(0);
      }
      expect(state.isColumnFull(0), isTrue);
      expect(state.validDrops().contains(0), isFalse);
      expect(state.validDrops(), [1, 2, 3, 4, 5, 6]);

      // Dropping into full column 0 should be a no-op
      final noOpState = state.drop(0);
      expect(noOpState, equals(state));
    });

    test('drop places token at lowest available row in column', () {
      var state = ConnectFourState.initial();
      // Drop in col 3 (lowest row is 5: index 5 * 7 + 3 = 38)
      state = state.drop(3);
      expect(state.board[38], Player.red);
      expect(state.current, Player.yellow);

      // Drop again in col 3 (row 4: index 4 * 7 + 3 = 31)
      state = state.drop(3);
      expect(state.board[31], Player.yellow);
      expect(state.current, Player.red);
    });

    test('Horizontal win detection', () {
      var state = ConnectFourState.initial(isAiOpponent: false);
      state = state.drop(0); // R (5,0)
      state = state.drop(0); // Y (4,0)
      state = state.drop(1); // R (5,1)
      state = state.drop(1); // Y (4,1)
      state = state.drop(2); // R (5,2)
      state = state.drop(2); // Y (4,2)
      state = state.drop(3); // R (5,3)

      expect(state.status, ConnectFourStatus.won);
      expect(state.winner, Player.red);
      expect(state.winsRed, 1);
      expect(state.winningLine, [35, 36, 37, 38]); // indices for row 5, cols 0..3
    });

    test('Vertical win detection', () {
      var state = ConnectFourState.initial(isAiOpponent: false);
      state = state.drop(0); // R (5,0)
      state = state.drop(1); // Y (5,1)
      state = state.drop(0); // R (4,0)
      state = state.drop(1); // Y (4,1)
      state = state.drop(0); // R (3,0)
      state = state.drop(1); // Y (3,1)
      state = state.drop(0); // R (2,0) -> WIN

      expect(state.status, ConnectFourStatus.won);
      expect(state.winner, Player.red);
      expect(state.winsRed, 1);
      expect(state.winningLine, [14, 21, 28, 35]); // indices for rows 2..5, col 0
    });

    test('Diagonal \\ win detection (down-right)', () {
      var state = ConnectFourState.initial(isAiOpponent: false);
      state = state.drop(3); // R: (5,3)
      state = state.drop(2); // Y: (5,2)
      state = state.drop(2); // R: (4,2)
      state = state.drop(1); // Y: (5,1)
      state = state.drop(0); // R: (5,0)
      state = state.drop(1); // Y: (4,1)
      state = state.drop(1); // R: (3,1)
      state = state.drop(0); // Y: (4,0)
      state = state.drop(0); // R: (3,0)
      state = state.drop(4); // Y: (5,4)
      state = state.drop(0); // R: (2,0) -> WIN!

      expect(state.status, ConnectFourStatus.won);
      expect(state.winner, Player.red);
      expect(state.winningLine, [14, 22, 30, 38]); // (2,0), (3,1), (4,2), (5,3)
    });

    test('Diagonal / win detection (up-right / down-left)', () {
      var state = ConnectFourState.initial(isAiOpponent: false);
      state = state.drop(0); // R: (5,0)
      state = state.drop(1); // Y: (5,1)
      state = state.drop(1); // R: (4,1)
      state = state.drop(2); // Y: (5,2)
      state = state.drop(3); // R: (5,3)
      state = state.drop(2); // Y: (4,2)
      state = state.drop(2); // R: (3,2)
      state = state.drop(3); // Y: (4,3)
      state = state.drop(3); // R: (3,3)
      state = state.drop(4); // Y: (5,4)
      state = state.drop(3); // R: (2,3) -> WIN!

      expect(state.status, ConnectFourStatus.won);
      expect(state.winner, Player.red);
      expect(state.winningLine, [17, 23, 29, 35]); // (2,3), (3,2), (4,1), (5,0)
    });

    test('Draw when board is full with no 4-in-a-row', () {
      final board = <Player?>[
        Player.red, Player.red, Player.yellow, Player.yellow, Player.red, Player.red, null,
        Player.yellow, Player.yellow, Player.red, Player.red, Player.yellow, Player.yellow, Player.red,
        Player.red, Player.red, Player.yellow, Player.yellow, Player.red, Player.red, Player.yellow,
        Player.yellow, Player.yellow, Player.red, Player.red, Player.yellow, Player.yellow, Player.red,
        Player.red, Player.red, Player.yellow, Player.yellow, Player.red, Player.red, Player.yellow,
        Player.yellow, Player.yellow, Player.red, Player.red, Player.yellow, Player.yellow, Player.red,
      ];

      var state = ConnectFourState.fromBoard(
        board: board,
        current: Player.red,
      );

      expect(state.isFull(), isFalse);
      expect(state.validDrops(), [6]);

      // Drop in the final slot (col 6)
      state = state.drop(6);
      expect(state.isFull(), isTrue);
      expect(state.status, ConnectFourStatus.draw);
      expect(state.draws, 1);
    });

    test('AI finds immediate forced win in 1 move', () {
      final board = List<Player?>.filled(42, null);
      board[5 * 7 + 2] = Player.yellow;
      board[4 * 7 + 2] = Player.yellow;
      board[3 * 7 + 2] = Player.yellow;

      final state = ConnectFourState.fromBoard(
        board: board,
        current: Player.yellow,
      );

      final bestCol = ConnectFourAI.findBestMove(state, depth: 2);
      expect(bestCol, 2);

      final nextState = state.drop(bestCol);
      expect(nextState.status, ConnectFourStatus.won);
      expect(nextState.winner, Player.yellow);
    });

    test('AI blocks opponent forced win in 1 move', () {
      final board = List<Player?>.filled(42, null);
      board[5 * 7 + 0] = Player.red;
      board[5 * 7 + 1] = Player.red;
      board[5 * 7 + 2] = Player.red;

      final state = ConnectFourState.fromBoard(
        board: board,
        current: Player.yellow,
      );

      final bestCol = ConnectFourAI.findBestMove(state, depth: 2);
      expect(bestCol, 3);
    });

    test('AI returns the single valid move when only 1 column is available', () {
      // Fill columns 0..5, leaving column 6 open
      final board = List<Player?>.filled(42, null);
      for (var col = 0; col < 6; col++) {
        for (var r = 0; r < 6; r++) {
          board[r * 7 + col] = (r + col) % 2 == 0 ? Player.red : Player.yellow;
        }
      }

      final state = ConnectFourState.fromBoard(
        board: board,
        current: Player.yellow,
      );
      expect(state.validDrops(), [6]);

      final move = ConnectFourAI.findBestMove(state, depth: 2);
      expect(move, 6);
    });

    test('playAiTurn executes AI move properly', () {
      var state = ConnectFourState.initial(isAiOpponent: true, aiDepth: 2);
      state = state.drop(3); // Human (Red) drops center
      expect(state.current, Player.yellow);

      state = state.playAiTurn();
      expect(state.current, Player.red);
      expect(state.board.where((c) => c != null).length, 2);
    });

    test('checkBoardWin utility checks all directional wins on static board', () {
      final emptyBoard = List<Player?>.filled(42, null);
      expect(ConnectFourState.checkBoardWin(emptyBoard), isNull);

      // Horizontal
      final hBoard = List<Player?>.filled(42, null);
      hBoard[0] = Player.red;
      hBoard[1] = Player.red;
      hBoard[2] = Player.red;
      hBoard[3] = Player.red;
      expect(ConnectFourState.checkBoardWin(hBoard), [0, 1, 2, 3]);

      // Vertical
      final vBoard = List<Player?>.filled(42, null);
      vBoard[0 * 7 + 2] = Player.yellow;
      vBoard[1 * 7 + 2] = Player.yellow;
      vBoard[2 * 7 + 2] = Player.yellow;
      vBoard[3 * 7 + 2] = Player.yellow;
      expect(ConnectFourState.checkBoardWin(vBoard), [2, 9, 16, 23]);

      // Diagonal \
      final d1Board = List<Player?>.filled(42, null);
      d1Board[0 * 7 + 0] = Player.red;
      d1Board[1 * 7 + 1] = Player.red;
      d1Board[2 * 7 + 2] = Player.red;
      d1Board[3 * 7 + 3] = Player.red;
      expect(ConnectFourState.checkBoardWin(d1Board), [0, 8, 16, 24]);

      // Diagonal /
      final d2Board = List<Player?>.filled(42, null);
      d2Board[3 * 7 + 0] = Player.yellow;
      d2Board[2 * 7 + 1] = Player.yellow;
      d2Board[1 * 7 + 2] = Player.yellow;
      d2Board[0 * 7 + 3] = Player.yellow;
      expect(ConnectFourState.checkBoardWin(d2Board), [21, 15, 9, 3]);
    });

    test('Reset preserves win/draw statistics', () {
      var state = ConnectFourState.initial(winsRed: 3, winsYellow: 2, draws: 1);
      state = state.drop(0);
      expect(state.board[35], Player.red);

      final resetState = state.reset();
      expect(resetState.board.every((s) => s == null), isTrue);
      expect(resetState.winsRed, 3);
      expect(resetState.winsYellow, 2);
      expect(resetState.draws, 1);
      expect(resetState.current, Player.red);
      expect(resetState.status, ConnectFourStatus.playing);
    });

    test('Edge cases: out of bounds drops and post-game drops', () {
      var state = ConnectFourState.initial();
      expect(state.drop(-1), equals(state));
      expect(state.drop(7), equals(state));
      expect(state.isColumnFull(-1), isTrue);
      expect(state.isColumnFull(7), isTrue);
      expect(state.lowestEmptyRow(-1), isNull);
      expect(state.lowestEmptyRow(7), isNull);
      expect(state.cellAt(-1, 0), isNull);
      expect(state.cellAt(0, 7), isNull);
      expect(state.cellAt(6, 0), isNull);
      expect(state.cellAt(0, -1), isNull);

      // Post-game won
      final wonState = state.copyWith(status: ConnectFourStatus.won);
      expect(wonState.drop(0), equals(wonState));
      expect(wonState.playAiTurn(), equals(wonState));

      // Post-game draw
      final drawState = state.copyWith(status: ConnectFourStatus.draw);
      expect(drawState.drop(0), equals(drawState));
    });

    test('State equality and copyWith', () {
      final state1 = ConnectFourState.initial();
      final state2 = state1.copyWith();
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1 == Object(), isFalse);

      final stateDifferentBoard = state1.copyWith(
        board: List<Player?>.filled(42, Player.red),
      );
      expect(state1 == stateDifferentBoard, isFalse);
    });

    test('ConnectFourAI evaluateBoard and scoreWindow edge cases', () {
      final state = ConnectFourState.initial();
      final eval = ConnectFourAI.evaluateBoard(state, Player.red);
      expect(eval, 0);

      // Score window tests
      expect(ConnectFourAI.scoreWindow([Player.red, Player.red, Player.red, Player.red], Player.red), 100000);
      expect(ConnectFourAI.scoreWindow([Player.red, Player.red, Player.red, null], Player.red), 120);
      expect(ConnectFourAI.scoreWindow([Player.red, Player.red, null, null], Player.red), 10);
      expect(ConnectFourAI.scoreWindow([Player.yellow, Player.yellow, Player.yellow, Player.yellow], Player.red), -100000);
      expect(ConnectFourAI.scoreWindow([Player.yellow, Player.yellow, Player.yellow, null], Player.red), -150);
      expect(ConnectFourAI.scoreWindow([Player.yellow, Player.yellow, null, null], Player.red), -10);
      expect(ConnectFourAI.scoreWindow([Player.red, Player.yellow, null, null], Player.red), 0);
    });
  });
}
