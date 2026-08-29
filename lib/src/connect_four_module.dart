import 'package:flutter/material.dart';
import 'package:game_module/game_module.dart';

import 'connect_four_page.dart';

GameModule get connectFourModule => const _ConnectFourModule();

class _ConnectFourModule implements GameModule {
  const _ConnectFourModule();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'connect_four',
        name: 'Connect Four',
        description: 'Drop tokens, line up four.',
        icon: Icons.adjust_outlined,
        color: Color(0xFF1E3A8A),
        build: _buildPage,
      );

  static Widget _buildPage(BuildContext context) => const ConnectFourPage();
}
