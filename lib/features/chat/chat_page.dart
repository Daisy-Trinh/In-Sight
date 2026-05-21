import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/store/app_store.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/models/persona.dart';
import '../personas/persona_engine.dart';

class ChatPage extends StatefulWidget {
  final Persona? initialPersona;
  const ChatPage({super.key, this.initialPersona});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _streamingText = '';
  bool _showTopics = true;
  Timer? _topicTimer;
  int _topicCountdown = 10;
  late Persona _persona;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _persona = widget.initialPersona ?? store.currentPersona;
    _startTopicTimer();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _topicTimer?.cancel();
    super.dispose();
  }

  void _startTopicTimer() {
    _topicCountdown = 10;
    _topicTimer?.cancel();
    _topicTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _topicCountdown--;
        if (_topicCountdown <= 0) {
          _showTopics = false;
          t.cancel();
        }
      });
    });
  }

  // ─────────────────────────────────────────
  // SEND MESSAGE
  // ─────────────────────────────────────────
  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _textCtrl.text).trim();
    if (text.isEmpty || _isTyping) return;

    final store = context.read<AppStore>();

    // Quota check
    if (!store.quota.isPremium && store.quota.isEmpty) {
      _showQuotaEmpty();
      return;
    }

    // SOS detection
    if (PersonaEngine.detectSOS(text)) {
      _addMessage(text, isUser: true);
      await Future.delayed(const Duration(milliseconds: 800));
      _addMessage(PersonaEngine.sosResponse(), isUser: false);
      return;
    }

    // Consume token
    store.consumeToken();

    // Add user message
    _addMessage(text, isUser: true);
    _textCtrl.clear();
    setState(() {
      _isTyping = true;
      _showTopics = false;
      _topicTimer?.cancel();
      _streamingText = '';
    });

    // Simulate streaming response
    final responses = PersonaEngine.generateResponse(_persona, text);
    for (final response in responses) {
      await _streamResponse(response);
      if (responses.indexOf(response) < responses.length - 1) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  Future<void> _streamResponse(String fullText) async {
    setState(() {
      _streamingText = '';
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
    });

    // Stream character by character with haptic
    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 18));
      if (!mounted) return;
      setState(() {
        _streamingText = fullText.substring(0, i + 1);
        _messages.last = _messages.last.copyWith(
          content: _streamingText,
          isStreaming: i < fullText.length - 1,
        );
      });
      if (i == 0) HapticFeedback.lightImpact();
      _scrollToBottom();
    }

    // Finalize
    setState(() {
      _messages.last = _messages.last.copyWith(isStreaming: false);
      _streamingText = '';
    });
    HapticFeedback.selectionClick();
  }

  void _addMessage(String content, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        content: content,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: DesignTokens.durationNormal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuotaEmpty() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuotaEmptySheet(
        onWatchAd: () {
          Navigator.pop(ctx);
          _simulateAdReward();
        },
      ),
    );
  }

  void _simulateAdReward() async {
    // Production: gọi AdMob Rewarded Ad + API /quota/reward
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.read<AppStore>().grantAdReward();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Bạn đã nhận thêm 10 token!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final personaColor = DesignTokens.personaColor(_persona.id);
    final personaContainer = DesignTokens.personaContainerColor(_persona.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _PersonaAvatar(persona: _persona),
            const SizedBox(width: DesignTokens.space12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _persona.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'đang online',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DesignTokens.success,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quota indicator
          Padding(
            padding:
                const EdgeInsets.only(right: DesignTokens.space16),
            child: _QuotaChip(quota: store.quota),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quota bar
          _QuotaBar(quota: store.quota, personaColor: personaColor),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChat(
                    persona: _persona,
                    showTopics: _showTopics,
                    countdown: _topicCountdown,
                    onTopicTap: (topic) => _sendMessage(topic),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(DesignTokens.space16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _MessageBubble(
                        message: msg,
                        personaColor: personaColor,
                        personaContainer: personaContainer,
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (_isTyping) _TypingIndicator(personaColor: personaColor),

          // Input bar
          _InputBar(
            controller: _textCtrl,
            onSend: () => _sendMessage(),
            personaColor: personaColor,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────

class _PersonaAvatar extends StatelessWidget {
  final Persona persona;
  const _PersonaAvatar({required this.persona});

  String get _emoji {
    switch (persona) {
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
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: DesignTokens.personaContainerColor(persona.id),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 20))),
    );
  }
}

class _QuotaChip extends StatelessWidget {
  final QuotaStatus quota;
  const _QuotaChip({required this.quota});

  Color get _color {
    if (quota.isEmpty) return DesignTokens.error;
    if (quota.isLow) return DesignTokens.warning;
    return DesignTokens.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            '${quota.tokensRemaining}',
            style: TextStyle(
              fontSize: DesignTokens.fontSm,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaBar extends StatelessWidget {
  final QuotaStatus quota;
  final Color personaColor;
  const _QuotaBar({required this.quota, required this.personaColor});

  @override
  Widget build(BuildContext context) {
    if (quota.isPremium) return const SizedBox.shrink();
    final color = quota.isEmpty
        ? DesignTokens.error
        : quota.isLow
            ? DesignTokens.warning
            : personaColor;

    return LinearProgressIndicator(
      value: quota.percentRemaining,
      backgroundColor: color.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation<Color>(color),
      minHeight: 2,
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final Persona persona;
  final bool showTopics;
  final int countdown;
  final ValueChanged<String> onTopicTap;

  const _EmptyChat({
    required this.persona,
    required this.showTopics,
    required this.countdown,
    required this.onTopicTap,
  });

  String get _greeting {
    switch (persona) {
      case Persona.lay:
        return 'hey! có chuyện gì không? 👀';
      case Persona.mentor:
        return 'Chào bạn. Hôm nay bạn muốn khám phá điều gì?';
      case Persona.soul:
        return 'Tôi ở đây. Cứ chia sẻ khi bạn sẵn sàng 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = PersonaEngine.topicSuggestions(persona);
    final personaColor = DesignTokens.personaColor(persona.id);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _greeting,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DesignTokens.textSecondary,
                    fontStyle: persona == Persona.soul
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
            ),
            if (showTopics) ...[
              const SizedBox(height: DesignTokens.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gợi ý chủ đề',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                  ),
                  Text(
                    '$countdown',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DesignTokens.textDisabled,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space8),
              ...topics.map((topic) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: DesignTokens.space8),
                    child: GestureDetector(
                      onTap: () => onTopicTap(topic),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space16,
                          vertical: DesignTokens.space12,
                        ),
                        decoration: BoxDecoration(
                          color: personaColor.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                          border: Border.all(
                              color: personaColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          topic,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DesignTokens.textPrimary,
                                  ),
                        ),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color personaColor;
  final Color personaContainer;

  const _MessageBubble({
    required this.message,
    required this.personaColor,
    required this.personaContainer,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: personaContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Center(
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 16,
                  color: personaColor,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
              decoration: BoxDecoration(
                color: isUser ? DesignTokens.primary : personaContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(DesignTokens.radiusLg),
                  topRight: const Radius.circular(DesignTokens.radiusLg),
                  bottomLeft: Radius.circular(
                      isUser ? DesignTokens.radiusLg : DesignTokens.radiusXs),
                  bottomRight: Radius.circular(
                      isUser ? DesignTokens.radiusXs : DesignTokens.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? DesignTokens.onPrimary
                              : DesignTokens.textPrimary,
                        ),
                  ),
                  if (message.isStreaming) ...[
                    const SizedBox(height: 4),
                    _StreamingCursor(color: personaColor),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: DesignTokens.space32),
        ],
      ),
    );
  }
}

class _StreamingCursor extends StatefulWidget {
  final Color color;
  const _StreamingCursor({required this.color});

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8,
        height: 2,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final Color personaColor;
  const _TypingIndicator({required this.personaColor});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(
          reverse: true,
          period: Duration(milliseconds: 400 + i * 150),
        ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space8,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space16,
              vertical: DesignTokens.space12,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controllers[i],
                  builder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Transform.translate(
                      offset: Offset(0, -4 * _controllers[i].value),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.personaColor.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color personaColor;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.personaColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: DesignTokens.space16,
        right: DesignTokens.space16,
        top: DesignTokens.space12,
        bottom: DesignTokens.space12 +
            MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: DesignTokens.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Nhắn gì đó...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space16,
                  vertical: DesignTokens.space12,
                ),
                filled: true,
                fillColor: DesignTokens.surfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: personaColor,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaEmptySheet extends StatelessWidget {
  final VoidCallback onWatchAd;
  const _QuotaEmptySheet({required this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'Hết token hôm nay rồi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Xem 1 video ngắn để nhận thêm 10 token miễn phí',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.textSecondary,
                ),
          ),
          const SizedBox(height: DesignTokens.space24),
          FilledButton.icon(
            onPressed: onWatchAd,
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Xem video (+10 token)'),
          ),
          const SizedBox(height: DesignTokens.space12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để mai vậy'),
          ),
        ],
      ),
    );
  }
}
