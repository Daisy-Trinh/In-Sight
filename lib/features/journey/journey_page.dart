import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/store/app_store.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/models/persona.dart';

class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final sessions = store.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hành trình'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {/* TODO: filter by persona/mood */},
          ),
        ],
      ),
      body: sessions.isEmpty
          ? _EmptyJourney()
          : ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.space16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return _SessionCard(session: sessions[index]);
              },
            ),
    );
  }
}

class _EmptyJourney extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: DesignTokens.space24),
            Text(
              'Hành trình của bạn',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'Mỗi cuộc trò chuyện sẽ được lưu lại ở đây như một nhật ký tâm hồn',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final JourneySession session;
  const _SessionCard({required this.session});

  String get _personaEmoji {
    switch (session.persona) {
      case Persona.lay:
        return '😎';
      case Persona.mentor:
        return '🧠';
      case Persona.soul:
        return '🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = DesignTokens.personaColor(session.persona.id);
    final container = DesignTokens.personaContainerColor(session.persona.id);
    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(session.date);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: container,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Center(
              child: Text(_personaEmoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      session.persona.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: color,
                          ),
                    ),
                    if (session.mood != null)
                      Text(
                        session.mood!.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                ),
                if (session.previewText.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    session.previewText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: DesignTokens.space8),
                Text(
                  '${session.messageCount} tin nhắn',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DesignTokens.textDisabled,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
