import 'dart:math';

/// Players in Connect Four.
enum Player {
  red,
  yellow;

  Player get opponent => this == red ? yellow : red;
}

/// Status of the Connect Four game.
enum ConnectFourStatus {
  playing,
  won,
  draw,
}

/// Pure-Dart Connect Four state engine.
class ConnectFourState {
  static const int rows = 6;
  static const int cols = 7;
  static const int totalSlots = rows * cols; // 42

  const ConnectFourState({
    required this.board,
    required this.current,
    required this.status,
    this.winner,
    this.winningLine,
    this.isAiOpponent = true,
    this.aiDepth = 4,
    this.winsRed = 0,
    this.winsYellow = 0,
    this.draws = 0,
  });

  /// Length 42 row-major grid: index = row * 7 + col.
  /// Row 0 is the top row, Row 5 is the bottom row.
  final List<Player?> board;
  final Player current;
  final ConnectFourStatus status;
  final Player? winner;
  final List<int>? winningLine;
  final bool isAiOpponent;
  final int aiDepth;
  final int winsRed;
  final int winsYellow;
  final int draws;

  /// Creates a clean initial state.
  factory ConnectFourState.initial({
    bool isAiOpponent = true,
    int aiDepth = 4,
    int winsRed = 0,
    int winsYellow = 0,
    int draws = 0,
  }) {
    return ConnectFourState(
      board: List<Player?>.filled(totalSlots, null),
      current: Player.red,
      status: ConnectFourStatus.playing,
      isAiOpponent: isAiOpponent,
      aiDepth: aiDepth,
      winsRed: winsRed,
      winsYellow: winsYellow,
      draws: draws,
    );
  }

  /// Creates a state from an existing board (useful for testing).
  factory ConnectFourState.fromBoard({
    required List<Player?> board,
    Player current = Player.red,
    ConnectFourStatus status = ConnectFourStatus.playing,
    Player? winner,
    List<int>? winningLine,
    bool isAiOpponent = true,
    int aiDepth = 4,
    int winsRed = 0,
    int winsYellow = 0,
    int draws = 0,
  }) {
    return ConnectFourState(
      board: List<Player?>.unmodifiable(board),
      current: current,
      status: status,
      winner: winner,
      winningLine: winningLine,
      isAiOpponent: isAiOpponent,
      aiDepth: aiDepth,
      winsRed: winsRed,
      winsYellow: winsYellow,
      draws: draws,
    );
  }

  static int indexAt(int row, int col) => row * cols + col;
  static int rowOf(int index) => index ~/ cols;
  static int colOf(int index) => index % cols;

  Player? cellAt(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return null;
    return board[row * cols + col];
  }

  /// Returns column indices (0..6) that are not full.
  List<int> validDrops() {
    final valid = <int>[];
    for (var col = 0; col < cols; col++) {
      if (!isColumnFull(col)) {
        valid.add(col);
      }
    }
    return valid;
  }

  /// Checks if a column is full (row 0 occupied).
  bool isColumnFull(int col) {
    if (col < 0 || col >= cols) return true;
    return board[col] != null;
  }

  /// Checks if all 42 slots are occupied.
  bool isFull() {
    for (var i = 0; i < totalSlots; i++) {
      if (board[i] == null) return false;
    }
    return true;
  }

  /// Finds the lowest available row in [col] (from 5 up to 0).
  /// Returns null if the column is full.
  int? lowestEmptyRow(int col) {
    if (col < 0 || col >= cols) return null;
    for (var r = rows - 1; r >= 0; r--) {
      if (board[r * cols + col] == null) {
        return r;
      }
    }
    return null;
  }

  /// Drops a token of the [current] player into [col].
  ConnectFourState drop(int col) {
    if (status != ConnectFourStatus.playing) return this;
    if (col < 0 || col >= cols || isColumnFull(col)) return this;

    final targetRow = lowestEmptyRow(col);
    if (targetRow == null) return this;

    final newBoard = List<Player?>.from(board);
    final placedIndex = targetRow * cols + col;
    newBoard[placedIndex] = current;

    // Check if this move created a 4-in-a-row
    final winLine = _checkWin(newBoard, targetRow, col, current);

    if (winLine != null) {
      return copyWith(
        board: newBoard,
        status: ConnectFourStatus.won,
        winner: current,
        winningLine: winLine,
        winsRed: current == Player.red ? winsRed + 1 : winsRed,
        winsYellow: current == Player.yellow ? winsYellow + 1 : winsYellow,
      );
    }

    // Check if board is full (Draw)
    var hasEmpty = false;
    for (var i = 0; i < totalSlots; i++) {
      if (newBoard[i] == null) {
        hasEmpty = true;
        break;
      }
    }

    if (!hasEmpty) {
      return copyWith(
        board: newBoard,
        status: ConnectFourStatus.draw,
        draws: draws + 1,
      );
    }

    // Switch turn
    return copyWith(
      board: newBoard,
      current: current.opponent,
    );
  }

  /// Executes AI move using Negamax search with alpha-beta pruning.
  ConnectFourState playAiTurn({int? depth, Random? random}) {
    if (status != ConnectFourStatus.playing) return this;
    final bestCol = ConnectFourAI.findBestMove(
      this,
      depth: depth ?? aiDepth,
      random: random,
    );
    return drop(bestCol);
  }

  /// Checks for 4-in-a-row passing through (row, col) with token [player].
  static List<int>? _checkWin(
    List<Player?> b,
    int row,
    int col,
    Player player,
  ) {
    // 4 directions: horizontal, vertical, diagonal down-right, diagonal up-right
    const directions = [
      [0, 1], // horizontal
      [1, 0], // vertical
      [1, 1], // diagonal \
      [-1, 1], // diagonal /
    ];

    for (final dir in directions) {
      final dr = dir[0];
      final dc = dir[1];
      final line = <int>[row * cols + col];

      // Forward direction
      for (var step = 1; step <= 3; step++) {
        final nr = row + dr * step;
        final nc = col + dc * step;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) break;
        if (b[nr * cols + nc] == player) {
          line.add(nr * cols + nc);
        } else {
          break;
        }
      }

      // Backward direction
      for (var step = 1; step <= 3; step++) {
        final nr = row - dr * step;
        final nc = col - dc * step;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) break;
        if (b[nr * cols + nc] == player) {
          line.add(nr * cols + nc);
        } else {
          break;
        }
      }

      if (line.length >= 4) {
        line.sort();
        return line.sublist(0, 4);
      }
    }
    return null;
  }

  /// Evaluates entire board to find any winning line.
  static List<int>? checkBoardWin(List<Player?> b) {
    // Horizontal
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c <= cols - 4; c++) {
        final p = b[r * cols + c];
        if (p != null &&
            b[r * cols + c + 1] == p &&
            b[r * cols + c + 2] == p &&
            b[r * cols + c + 3] == p) {
          return [
            r * cols + c,
            r * cols + c + 1,
            r * cols + c + 2,
            r * cols + c + 3,
          ];
        }
      }
    }

    // Vertical
    for (var c = 0; c < cols; c++) {
      for (var r = 0; r <= rows - 4; r++) {
        final p = b[r * cols + c];
        if (p != null &&
            b[(r + 1) * cols + c] == p &&
            b[(r + 2) * cols + c] == p &&
            b[(r + 3) * cols + c] == p) {
          return [
            r * cols + c,
            (r + 1) * cols + c,
            (r + 2) * cols + c,
            (r + 3) * cols + c,
          ];
        }
      }
    }

    // Diagonal \
    for (var r = 0; r <= rows - 4; r++) {
      for (var c = 0; c <= cols - 4; c++) {
        final p = b[r * cols + c];
        if (p != null &&
            b[(r + 1) * cols + c + 1] == p &&
            b[(r + 2) * cols + c + 2] == p &&
            b[(r + 3) * cols + c + 3] == p) {
          return [
            r * cols + c,
            (r + 1) * cols + c + 1,
            (r + 2) * cols + c + 2,
            (r + 3) * cols + c + 3,
          ];
        }
      }
    }

    // Diagonal /
    for (var r = 3; r < rows; r++) {
      for (var c = 0; c <= cols - 4; c++) {
        final p = b[r * cols + c];
        if (p != null &&
            b[(r - 1) * cols + c + 1] == p &&
            b[(r - 2) * cols + c + 2] == p &&
            b[(r - 3) * cols + c + 3] == p) {
          return [
            r * cols + c,
            (r - 1) * cols + c + 1,
            (r - 2) * cols + c + 2,
            (r - 3) * cols + c + 3,
          ];
        }
      }
    }

    return null;
  }

  /// Resets board for a new round while preserving win counts.
  ConnectFourState reset({bool? isAiOpponent, int? aiDepth}) {
    return ConnectFourState.initial(
      isAiOpponent: isAiOpponent ?? this.isAiOpponent,
      aiDepth: aiDepth ?? this.aiDepth,
      winsRed: winsRed,
      winsYellow: winsYellow,
      draws: draws,
    );
  }

  ConnectFourState copyWith({
    List<Player?>? board,
    Player? current,
    ConnectFourStatus? status,
    Player? winner,
    List<int>? winningLine,
    bool? isAiOpponent,
    int? aiDepth,
    int? winsRed,
    int? winsYellow,
    int? draws,
  }) {
    return ConnectFourState(
      board: board ?? this.board,
      current: current ?? this.current,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      winningLine: winningLine ?? this.winningLine,
      isAiOpponent: isAiOpponent ?? this.isAiOpponent,
      aiDepth: aiDepth ?? this.aiDepth,
      winsRed: winsRed ?? this.winsRed,
      winsYellow: winsYellow ?? this.winsYellow,
      draws: draws ?? this.draws,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConnectFourState) return false;
    if (other.current != current ||
        other.status != status ||
        other.winner != winner ||
        other.isAiOpponent != isAiOpponent ||
        other.aiDepth != aiDepth ||
        other.winsRed != winsRed ||
        other.winsYellow != winsYellow ||
        other.draws != draws ||
        other.board.length != board.length) {
      return false;
    }
    for (var i = 0; i < board.length; i++) {
      if (board[i] != other.board[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(board),
        current,
        status,
        winner,
        isAiOpponent,
        aiDepth,
        winsRed,
        winsYellow,
        draws,
      );
}

/// Negamax & Minimax AI engine with alpha-beta pruning for Connect Four.
class ConnectFourAI {
  const ConnectFourAI._();

  /// Center-outward column preference order for move ordering.
  static const List<int> columnOrder = [3, 2, 4, 1, 5, 0, 6];

  /// Finds the optimal column drop for the current player in [state].
  static int findBestMove(
    ConnectFourState state, {
    int depth = 4,
    Random? random,
  }) {
    final validMoves = state.validDrops();
    if (validMoves.isEmpty) return 0;
    if (validMoves.length == 1) return validMoves.first;

    final aiPlayer = state.current;
    final opponent = aiPlayer.opponent;

    // 1. Immediate tactical win detection in 1 move
    for (final col in validMoves) {
      final nextState = state.drop(col);
      if (nextState.status == ConnectFourStatus.won &&
          nextState.winner == aiPlayer) {
        return col;
      }
    }

    // 2. Immediate tactical block detection (prevent opponent win in 1 move)
    for (final col in validMoves) {
      // Simulate opponent dropping in this col
      final testOpponentState = ConnectFourState(
        board: state.board,
        current: opponent,
        status: ConnectFourStatus.playing,
      ).drop(col);
      if (testOpponentState.status == ConnectFourStatus.won &&
          testOpponentState.winner == opponent) {
        return col;
      }
    }

    // 3. Minimax with alpha-beta pruning
    final ordered = orderMoves(validMoves);
    var bestScore = -999999999;
    var bestMove = ordered.first;

    for (final col in ordered) {
      final nextState = state.drop(col);
      final score = minimax(
        nextState,
        depth - 1,
        -999999999,
        999999999,
        false,
        aiPlayer,
      );

      if (score > bestScore) {
        bestScore = score;
        bestMove = col;
      }
    }

    return bestMove;
  }

  /// Sorts moves with center column preference.
  static List<int> orderMoves(List<int> validMoves) {
    final ordered = <int>[];
    for (final c in columnOrder) {
      if (validMoves.contains(c)) {
        ordered.add(c);
      }
    }
    return ordered;
  }

  /// Minimax search with alpha-beta pruning.
  static int minimax(
    ConnectFourState state,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
    Player aiPlayer,
  ) {
    if (state.status == ConnectFourStatus.won) {
      return state.winner == aiPlayer
          ? (1000000 + depth * 100)
          : (-1000000 - depth * 100);
    }
    if (state.status == ConnectFourStatus.draw) {
      return 0;
    }
    if (depth <= 0) {
      return evaluateBoard(state, aiPlayer);
    }

    final validMoves = orderMoves(state.validDrops());
    if (validMoves.isEmpty) {
      return 0;
    }

    if (isMaximizing) {
      var maxEval = -999999999;
      for (final col in validMoves) {
        final eval = minimax(
          state.drop(col),
          depth - 1,
          alpha,
          beta,
          false,
          aiPlayer,
        );
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      var minEval = 999999999;
      for (final col in validMoves) {
        final eval = minimax(
          state.drop(col),
          depth - 1,
          alpha,
          beta,
          true,
          aiPlayer,
        );
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  /// Static board evaluation heuristic.
  static int evaluateBoard(ConnectFourState state, Player aiPlayer) {
    final opponent = aiPlayer.opponent;
    var score = 0;

    // Center column bias (pieces in center are strategically dominant)
    for (var r = 0; r < ConnectFourState.rows; r++) {
      final centerPiece = state.board[r * ConnectFourState.cols + 3];
      if (centerPiece == aiPlayer) {
        score += 6;
      } else if (centerPiece == opponent) {
        score -= 6;
      }
      final col2Piece = state.board[r * ConnectFourState.cols + 2];
      if (col2Piece == aiPlayer) {
        score += 3;
      } else if (col2Piece == opponent) {
        score -= 3;
      }
      final col4Piece = state.board[r * ConnectFourState.cols + 4];
      if (col4Piece == aiPlayer) {
        score += 3;
      } else if (col4Piece == opponent) {
        score -= 3;
      }
    }

    // Evaluate all 4-slot windows
    // Horizontal
    for (var r = 0; r < ConnectFourState.rows; r++) {
      for (var c = 0; c <= ConnectFourState.cols - 4; c++) {
        score += scoreWindow([
          state.board[r * ConnectFourState.cols + c],
          state.board[r * ConnectFourState.cols + c + 1],
          state.board[r * ConnectFourState.cols + c + 2],
          state.board[r * ConnectFourState.cols + c + 3],
        ], aiPlayer);
      }
    }

    // Vertical
    for (var c = 0; c < ConnectFourState.cols; c++) {
      for (var r = 0; r <= ConnectFourState.rows - 4; r++) {
        score += scoreWindow([
          state.board[r * ConnectFourState.cols + c],
          state.board[(r + 1) * ConnectFourState.cols + c],
          state.board[(r + 2) * ConnectFourState.cols + c],
          state.board[(r + 3) * ConnectFourState.cols + c],
        ], aiPlayer);
      }
    }

    // Diagonal \
    for (var r = 0; r <= ConnectFourState.rows - 4; r++) {
      for (var c = 0; c <= ConnectFourState.cols - 4; c++) {
        score += scoreWindow([
          state.board[r * ConnectFourState.cols + c],
          state.board[(r + 1) * ConnectFourState.cols + c + 1],
          state.board[(r + 2) * ConnectFourState.cols + c + 2],
          state.board[(r + 3) * ConnectFourState.cols + c + 3],
        ], aiPlayer);
      }
    }

    // Diagonal /
    for (var r = 3; r < ConnectFourState.rows; r++) {
      for (var c = 0; c <= ConnectFourState.cols - 4; c++) {
        score += scoreWindow([
          state.board[r * ConnectFourState.cols + c],
          state.board[(r - 1) * ConnectFourState.cols + c + 1],
          state.board[(r - 2) * ConnectFourState.cols + c + 2],
          state.board[(r - 3) * ConnectFourState.cols + c + 3],
        ], aiPlayer);
      }
    }

    return score;
  }

  /// Scores a 4-token window for [aiPlayer].
  static int scoreWindow(List<Player?> window, Player aiPlayer) {
    final opponent = aiPlayer.opponent;
    var aiCount = 0;
    var oppCount = 0;
    var emptyCount = 0;

    for (final slot in window) {
      if (slot == aiPlayer) {
        aiCount++;
      } else if (slot == opponent) {
        oppCount++;
      } else {
        emptyCount++;
      }
    }

    if (aiCount > 0 && oppCount > 0) return 0;

    if (aiCount == 4) return 100000;
    if (aiCount == 3 && emptyCount == 1) return 120;
    if (aiCount == 2 && emptyCount == 2) return 10;

    if (oppCount == 4) return -100000;
    if (oppCount == 3 && emptyCount == 1) return -150;
    if (oppCount == 2 && emptyCount == 2) return -10;

    return 0;
  }
}
