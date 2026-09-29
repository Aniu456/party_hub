import 'package:flutter/material.dart';

import 'app_style.dart';
import 'game_catalog.dart';
import 'local_game_page.dart';
import 'online/room_entry_page.dart';

class GameDetailPage extends StatelessWidget {
  const GameDetailPage({super.key, required this.game});
  final PartyGame game;
  @override
  Widget build(BuildContext context) {
    final look = gameLooks[game.id]!;
    return Scaffold(
      appBar: AppBar(title: Text(look.category)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LocalSetupPage(game: game),
                        ),
                      ),
                      child: const Text('同机开局', textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RoomEntryPage(game: game),
                        ),
                      ),
                      child: const Text('创建联机房间', textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageContent(
        children: [
          Row(
            children: [
              if (MediaQuery.textScalerOf(context).scale(16) < 24) ...[
                SizedBox(width: 76, child: GameArtwork(game: game, height: 80)),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      look.teaser,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playerCountLabel(game),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _DetailTag(Icons.wifi_rounded, '支持联机'),
              _DetailTag(Icons.smartphone_rounded, '可同机玩'),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SectionHeading('怎么玩'),
          Text(game.rules, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SectionHeading('开局须知'),
          Text(
            game.id == 'undercover'
                ? '至少 1 名主持人 + 3 名玩家才能开局。'
                : game.minPlayers == game.maxPlayers
                ? '需要 ${game.minPlayers} 名玩家对战。'
                : '至少 ${game.minPlayers} 名玩家才能开局。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (game.id == 'undercover') ...[
            const SizedBox(height: 8),
            const Text('主持人拥有上帝视角，能查看全部身份和词语，不参与拿词、发言和投票。'),
          ],
          const InfoNote('联机时每人使用自己的设备；同机时围坐一起，轮流传递手机。讨论和表演需要面对面或自行语音通话。'),
        ],
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  const _DetailTag(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}
