import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game_assets/game_assets.dart';

import 'connect_four_state.dart';

class ConnectFourPage extends StatefulWidget {
  const ConnectFourPage({super.key});

  @override
  State<ConnectFourPage> createState() => _ConnectFourPageState();
}

class _ConnectFourPageState extends State<ConnectFourPage>
    with SingleTickerProviderStateMixin {
  late ConnectFourState _state;
  bool _isAiThinking = false;
  bool _dialogShown = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _state = ConnectFourState.initial();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _restart() {
    _dialogShown = false;
    _isAiThinking = false;
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _state = _state.reset();
    });
  }

  void _onDrop(int col) {
    if (_state.status != ConnectFourStatus.playing) return;
    if (_isAiThinking) return;
    if (_state.isColumnFull(col)) return;

    final newState = _state.drop(col);
    if (newState == _state) return;

    setState(() {
      _state = newState;
    });

    SfxPlayer.instance.play('tap');

    if (_state.status == ConnectFourStatus.won) {
      _pulseController.repeat(reverse: true);
      SfxPlayer.instance.play('win');
      _checkShowEndDialog();
      return;
    } else if (_state.status == ConnectFourStatus.draw) {
      _checkShowEndDialog();
      return;
    }

    // Trigger AI turn if 1P mode
    if (_state.isAiOpponent && _state.current == Player.yellow) {
      _triggerAiMove();
    }
  }

  void _triggerAiMove() {
    setState(() {
      _isAiThinking = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (_state.status != ConnectFourStatus.playing) {
        setState(() {
          _isAiThinking = false;
        });
        return;
      }

      final newState = _state.playAiTurn();
      setState(() {
        _state = newState;
        _isAiThinking = false;
      });

      SfxPlayer.instance.play('tap');

      if (_state.status == ConnectFourStatus.won) {
        _pulseController.repeat(reverse: true);
        SfxPlayer.instance.play('win');
        _checkShowEndDialog();
      } else if (_state.status == ConnectFourStatus.draw) {
        _checkShowEndDialog();
      }
    });
  }

  void _checkShowEndDialog() {
    if (_dialogShown) return;
    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isWin = _state.status == ConnectFourStatus.won;
          final title = isWin
              ? (_state.winner == Player.red ? 'Red Wins!' : 'Yellow Wins!')
              : 'Game Drawn!';
          final iconColor = isWin
              ? (_state.winner == Player.red
                  ? Colors.redAccent
                  : Colors.amber)
              : Colors.blueGrey;

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.emoji_events, color: iconColor, size: 28),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(
              isWin
                  ? 'Congratulations to player ${_state.winner?.name.toUpperCase()}!\n\nScore — Red: ${_state.winsRed} | Yellow: ${_state.winsYellow}'
                  : 'All 42 slots filled with no winner.\n\nDraws: ${_state.draws}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _restart();
                },
                child: const Text('Play Again'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildGameTheme(Brightness.light),
      child: Scaffold(
        appBar: GameAppBar(
          title: 'Connect Four',
          score: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'R: ${_state.winsRed}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Yellow score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Y: ${_state.winsYellow}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          onRestart: () => _restart(),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Game Mode Selector & AI Depth
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('vs AI'),
                          icon: Icon(Icons.smart_toy_outlined),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('2 Player'),
                          icon: Icon(Icons.people_outline),
                        ),
                      ],
                      selected: {_state.isAiOpponent},
                      onSelectionChanged: (selected) {
                        if (selected.isNotEmpty) {
                          setState(() {
                            _state = _state.copyWith(
                              isAiOpponent: selected.first,
                            );
                          });
                        }
                      },
                    ),
                    if (_state.isAiOpponent) ...[
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _state.aiDepth,
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('Easy')),
                          DropdownMenuItem(value: 4, child: Text('Medium')),
                          DropdownMenuItem(value: 6, child: Text('Hard')),
                        ],
                        onChanged: (depth) {
                          if (depth != null) {
                            setState(() {
                              _state = _state.copyWith(aiDepth: depth);
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Turn Indicator Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _state.current == Player.red
                      ? Colors.red.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _state.current == Player.red
                        ? Colors.redAccent
                        : Colors.amber.shade700,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _state.current == Player.red
                            ? Colors.red
                            : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAiThinking
                          ? 'AI is thinking…'
                          : (_state.status == ConnectFourStatus.playing
                              ? (_state.current == Player.red
                                  ? 'Red’s Turn'
                                  : (_state.isAiOpponent
                                      ? 'Yellow’s Turn (AI)'
                                      : 'Yellow’s Turn'))
                              : (_state.status == ConnectFourStatus.won
                                  ? '${_state.winner?.name.toUpperCase()} Won!'
                                  : 'Game Drawn')),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _state.current == Player.red
                            ? Colors.red.shade900
                            : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Board Container with Drop Target Row
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AspectRatio(
                      aspectRatio: 7 / 7.2,
                      child: Column(
                        children: [
                          // Drop Column Buttons
                          Row(
                            children: List.generate(
                              ConnectFourState.cols,
                              (col) => Expanded(
                                child: Semantics(
                                  button: true,
                                  label: 'Drop token in column ${col + 1}',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_downward,
                                      color: _state.isColumnFull(col) ||
                                              _isAiThinking ||
                                              _state.status !=
                                                  ConnectFourStatus.playing
                                          ? Colors.grey.shade300
                                          : (_state.current == Player.red
                                              ? Colors.redAccent
                                              : Colors.amber.shade700),
                                    ),
                                    onPressed: _state.isColumnFull(col) ||
                                            _isAiThinking ||
                                            _state.status !=
                                                ConnectFourStatus.playing
                                        ? null
                                        : () => _onDrop(col),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 7x6 Board Grid
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final slotWidth =
                                    constraints.maxWidth / ConnectFourState.cols;
                                final slotHeight = constraints.maxHeight /
                                    ConnectFourState.rows;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A), // Blue cabinet
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: ConnectFourState.totalSlots,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: ConnectFourState.cols,
                                      mainAxisSpacing: 4,
                                      crossAxisSpacing: 4,
                                      childAspectRatio: 1,
                                    ),
                                    itemBuilder: (context, index) {
                                      return _buildSlot(
                                        index,
                                        slotWidth,
                                        slotHeight,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(int index, double width, double height) {
    final player = _state.board[index];
    final isWinningPiece = _state.winningLine?.contains(index) ?? false;

    Widget pieceContent;
    if (player == null) {
      // Empty dark cutout slot
      pieceContent = Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0F172A), // Dark cutout
        ),
      );
    } else {
      String svgName;
      if (player == Player.red) {
        svgName =
            isWinningPiece ? 'piece_red_winner.svg' : 'piece_red.svg';
      } else {
        svgName = isWinningPiece
            ? 'piece_yellow_winner.svg'
            : 'piece_yellow.svg';
      }

      final pieceWidget = SvgPicture.asset(
        'assets/svg/connect_four/$svgName',
        package: 'game_assets',
        fit: BoxFit.contain,
      );

      if (isWinningPiece) {
        pieceContent = ScaleTransition(
          scale: _pulseAnimation,
          child: pieceWidget,
        );
      } else {
        pieceContent = pieceWidget;
      }
    }

    final col = ConnectFourState.colOf(index);
    return GestureDetector(
      onTap: () => _onDrop(col),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0F172A),
        ),
        padding: const EdgeInsets.all(2),
        child: pieceContent,
      ),
    );
  }
}
