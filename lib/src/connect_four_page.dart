import 'dart:async';
import 'package:flutter/material.dart';
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
      data: buildGameTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        appBar: GameAppBar(
          title: 'Connect Four',
          score: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildScoreBadge('RED', '${_state.winsRed}', const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _buildScoreBadge('YELLOW', '${_state.winsYellow}', const Color(0xFFF59E0B)),
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF030712),
                        borderRadius: BorderRadius.circular(GameTokens.radiusLg),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeTab('vs AI', Icons.smart_toy_outlined, _state.isAiOpponent, () {
                            setState(() => _state = _state.copyWith(isAiOpponent: true));
                          }),
                          _buildModeTab('2 Player', Icons.people_outline, !_state.isAiOpponent, () {
                            setState(() => _state = _state.copyWith(isAiOpponent: false));
                          }),
                        ],
                      ),
                    ),
                    if (_state.isAiOpponent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF030712),
                          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: DropdownButton<int>(
                          value: _state.aiDepth,
                          underline: const SizedBox.shrink(),
                          dropdownColor: const Color(0xFF0F172A),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text('Easy', style: TextStyle(fontSize: 12, color: Colors.white))),
                            DropdownMenuItem(value: 4, child: Text('Medium', style: TextStyle(fontSize: 12, color: Colors.white))),
                            DropdownMenuItem(value: 6, child: Text('Hard', style: TextStyle(fontSize: 12, color: Colors.white))),
                          ],
                          onChanged: (depth) {
                            if (depth != null) {
                              setState(() => _state = _state.copyWith(aiDepth: depth));
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Turn Indicator Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF030712),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _state.current == Player.red
                        ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_state.current == Player.red ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _state.current == Player.red ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        boxShadow: [
                          BoxShadow(
                            color: (_state.current == Player.red ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAiThinking
                          ? 'AI is thinking…'
                          : (_state.status == ConnectFourStatus.playing
                              ? (_state.current == Player.red
                                  ? 'Red’s Turn'
                                  : (_state.isAiOpponent ? 'Yellow’s Turn (AI)' : 'Yellow’s Turn'))
                              : (_state.status == ConnectFourStatus.won
                                  ? '${_state.winner?.name.toUpperCase()} Won!'
                                  : 'Game Drawn')),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _state.current == Player.red ? const Color(0xFFF87171) : const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Board Container with direct Column Tap Area
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AspectRatio(
                      aspectRatio: 7 / 6.2,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final slotWidth = constraints.maxWidth / ConnectFourState.cols;
                          final slotHeight = constraints.maxHeight / ConnectFourState.rows;

                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: ConnectFourState.totalSlots,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: ConnectFourState.cols,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                return _buildSlot(index, slotWidth, slotHeight);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? GameTokens.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GameTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSlot(int index, double width, double height) {
    final player = _state.board[index];
    final isWinningPiece = _state.winningLine?.contains(index) ?? false;
    final col = ConnectFourState.colOf(index);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onDrop(col),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0B1120),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: player == null
            ? const SizedBox.shrink()
            : (isWinningPiece
                ? ScaleTransition(
                    scale: _pulseAnimation,
                    child: _buildPieceToken(player, isWinningPiece),
                  )
                : _buildPieceToken(player, isWinningPiece)),
      ),
    );
  }

  Widget _buildPieceToken(Player player, bool isWinningPiece) {
    final isRed = player == Player.red;
    final primaryColor = isRed ? const Color(0xFFEF4444) : const Color(0xFFFBBF24);
    final darkColor = isRed ? const Color(0xFFB91C1C) : const Color(0xFFD97706);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [primaryColor, darkColor],
        ),
        border: isWinningPiece
            ? Border.all(color: Colors.white, width: 2.5)
            : Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isWinningPiece ? 0.8 : 0.4),
            blurRadius: isWinningPiece ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isWinningPiece
          ? const Center(
              child: Icon(Icons.star_rounded, color: Colors.white, size: 20),
            )
          : Align(
              alignment: const Alignment(-0.4, -0.4),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
    );
  }
}
