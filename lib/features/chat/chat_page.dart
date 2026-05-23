import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/router/app_router.dart';
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

  final List<ChatMessage> _messages = [];
  bool _isThinking = false; // true while waiting for first response chunk
  bool _isStreaming = false; // true while a message is being typed out
  bool _showTopics = true;
  Timer? _topicTimer;
  int _topicCountdown = 10;
  late Persona _persona;
  // Unique session ID for this chat window — sent as session_id to the API
  late final String _sessionId;

  // Tracks IDs of the most-recent failed send so _retryLastMessage can remove them
  String? _lastUserMsgId;
  String? _lastErrorBubbleId;

  // WEB-12: Energy Closure (US-L05) — Lay only
  bool _energyClosure = false; // disables input for 5s after energy msg
  Timer? _energyTimer;

  static const _energyKeywords = [
    'mệt mỏi', 'muốn nghỉ', 'muốn ngủ', 'đi ngủ', 'nghỉ ngơi',
    'kiệt sức', 'muốn dừng', 'chán rồi', 'burnout', 'mệt lắm',
    'cần ngủ', 'muốn nghỉ ngơi', 'thấy mệt', 'quá mệt',
  ];

  bool _detectEnergy(String text) {
    if (_persona != Persona.lay) return false;
    final lower = text.toLowerCase();
    return _energyKeywords.any((k) => lower.contains(k));
  }

  bool get _isBusy => _isThinking || _isStreaming || _energyClosure;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _persona = widget.initialPersona ?? store.currentPersona;
    _sessionId = const Uuid().v4();
    _startTopicTimer();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _topicTimer?.cancel();
    _energyTimer?.cancel();
    super.dispose();
  }

  void _startTopicTimer() {
    _topicCountdown = 10;
    _topicTimer?.cancel();
    _topicTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
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
    if (text.isEmpty || _isBusy) return;

    final store = context.read<AppStore>();

    // Quota check
    if (!store.quota.isPremium && store.quota.isEmpty) {
      _showQuotaEmpty();
      return;
    }

    // WEB-12: detect energy closure keywords before sending
    final isEnergyMsg = _detectEnergy(text);

    // Pre-consume token — refunded in all catch blocks below
    store.consumeToken();

    // Add user message + clear input; remember ID for potential retry
    _textCtrl.clear();
    final userMsgId = _uuid.v4();
    _lastUserMsgId = userMsgId;
    setState(() {
      _messages.add(ChatMessage(
        id: userMsgId,
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isThinking = true;
      _showTopics = false;
      _topicTimer?.cancel();
    });

    // Build history for the API (all messages except the one just added)
    final history = _messages
        .sublist(0, _messages.length - 1)
        .map((m) => <String, String>{
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    final api = context.read<ApiClient>();

    try {
      await _streamFromApi(api, text, history);
      // ── Success ───────────────────────────────────────────────────────────
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _isStreaming = false;
      });
      _scrollToBottom();
      // WEB-12: trigger energy closure after Lay responds to a tired message
      if (isEnergyMsg) _triggerEnergyClosure();
    } on ApiException catch (e) {
      if (!mounted) return;
      _resetBusyState();
      if (e.isQuotaEmpty) {
        store.refundToken();
        _showQuotaEmpty();
      } else {
        debugPrint('[Chat] API error ${e.code}: ${e.message}');
        store.refundToken();
        _showApiError(text);
      }
    } catch (e) {
      if (!mounted) return;
      _resetBusyState();
      debugPrint('[Chat] API unreachable: $e');
      store.refundToken();
      _showApiError(text);
    }
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  /// Reset thinking/streaming flags and finalize any partial bot bubble.
  void _resetBusyState() {
    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _isStreaming = false;
      // Finalize any partial streaming bubble left by a failed stream
      final partialIdx = _messages.lastIndexWhere((m) => !m.isUser && m.isStreaming);
      if (partialIdx >= 0) {
        _messages[partialIdx] = _messages[partialIdx].copyWith(isStreaming: false);
      }
    });
  }

  /// Show an inline error bubble + SnackBar with a retry action.
  void _showApiError(String failedText) {
    if (!mounted) return;

    final errorId = _uuid.v4();
    _lastErrorBubbleId = errorId;

    setState(() {
      _messages.add(ChatMessage(
        id: errorId,
        content: '⚡ AI đang bận, tin nhắn chưa đến được. Nhấn "Thử lại" để gửi lại.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Không kết nối được với AI'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: () => _retryLastMessage(failedText),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
  }

  /// Remove the error bubble + the failed user message, then re-send.
  void _retryLastMessage(String failedText) {
    if (_isBusy) return;
    setState(() {
      // Remove error bubble
      if (_lastErrorBubbleId != null) {
        _messages.removeWhere((m) => m.id == _lastErrorBubbleId);
        _lastErrorBubbleId = null;
      }
      // Remove the failed user message
      if (_lastUserMsgId != null) {
        _messages.removeWhere((m) => m.id == _lastUserMsgId);
        _lastUserMsgId = null;
      }
    });
    _sendMessage(failedText);
  }

  // ─────────────────────────────────────────
  // STREAM FROM API (real backend SSE)
  // ─────────────────────────────────────────
  Future<void> _streamFromApi(
    ApiClient api,
    String text,
    List<Map<String, String>> history,
  ) async {
    final msgId = _uuid.v4();
    bool messageCreated = false;
    int deltaCount = 0;

    try {
      await for (final event in api.sendChatMessage(
        persona: _persona,
        message: text,
        sessionId: _sessionId,
        history: history,
      )) {
        if (!mounted) return;

        if (event.isChunk) {
          final delta = event.delta ?? '';
          if (delta.isEmpty) continue;

          if (!messageCreated) {
            // First chunk → transition thinking → streaming, create bubble
            setState(() {
              _isThinking = false;
              _isStreaming = true;
              _messages.add(ChatMessage(
                id: msgId,
                content: delta,
                isUser: false,
                timestamp: DateTime.now(),
                isStreaming: true,
              ));
            });
            messageCreated = true;
            if (!kIsWeb) HapticFeedback.lightImpact();
            _scrollToBottom();
          } else {
            // Subsequent chunks — append delta to existing bubble
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == msgId);
              if (idx >= 0) {
                _messages[idx] = _messages[idx].copyWith(
                  content: _messages[idx].content + delta,
                );
              }
            });
            deltaCount++;
            // Scroll at most every ~15 deltas to avoid scroll storm
            if (deltaCount % 15 == 0) _scrollToBottom();
          }
        } else if (event.isDone) {
          if (!mounted) return;
          setState(() {
            _isStreaming = false;
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(isStreaming: false);
            }
          });
          // WEB-10: split Lay roast into 3 bubbles on ||| separator
          _splitRoastBubbles(msgId);
          if (!kIsWeb) HapticFeedback.selectionClick();
          _scrollToBottom(animated: true);
        }
      }

      // Guard: stream ended without a 'done' event (e.g. server closed early)
      if (mounted && (_isThinking || _isStreaming)) {
        setState(() {
          _isThinking = false;
          _isStreaming = false;
          final idx = _messages.indexWhere((m) => m.id == msgId);
          if (idx >= 0) {
            _messages[idx] = _messages[idx].copyWith(isStreaming: false);
          }
        });
      }
    } catch (e) {
      // Stream threw (network error, timeout, DNS failure, etc.).
      // Clean up any partial bubble so _showApiError can show a clean error.
      if (mounted) {
        setState(() {
          _isThinking = false;
          _isStreaming = false;
          _messages.removeWhere((m) => m.id == msgId);
        });
      }
      rethrow; // propagate to _sendMessage catch block
    }
  }

  // ─────────────────────────────────────────
  // WEB-12: ENERGY CLOSURE (US-L05)
  // ─────────────────────────────────────────
  void _triggerEnergyClosure() {
    setState(() => _energyClosure = true);
    _energyTimer?.cancel();
    _energyTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _energyClosure = false);
      _showEnergyClosureDialog();
    });
  }

  void _showEnergyClosureDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 52)),
            const SizedBox(height: DesignTokens.space12),
            Text(
              'oke bạn đi nghỉ đi nha',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'cơ thể cần nghỉ ngơi lắm rồi đó 🛌\nmình hẹn lại lần sau nha!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRouter.chat);
            },
            child: const Text('Ngủ ngon 🌙'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // WEB-10: ROAST BUBBLE SPLIT
  // ─────────────────────────────────────────
  /// After a stream completes, if the bot message contains "||| " separators
  /// (Lay persona roast format), replace it with multiple individual bubbles.
  void _splitRoastBubbles(String msgId) {
    final idx = _messages.indexWhere((m) => m.id == msgId);
    if (idx < 0) return;

    final raw = _messages[idx].content;
    if (!raw.contains('|||')) return;

    final parts = raw
        .split('|||')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length <= 1) return;

    setState(() {
      // Replace original with first part, insert rest after it
      _messages[idx] = _messages[idx].copyWith(content: parts[0]);
      for (int i = 1; i < parts.length; i++) {
        _messages.insert(
          idx + i,
          ChatMessage(
            id: _uuid.v4(),
            content: parts[i],
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: false,
          ),
        );
      }
    });
  }

  /// FIX: use jumpTo during streaming (no animation = no competing animateTo
  /// calls stacking up). Only animate on explicit user-facing scrolls.
  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (animated) {
        _scrollCtrl.animateTo(
          max,
          duration: DesignTokens.durationNormal,
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(max);
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
                  _isThinking
                      ? 'đang suy nghĩ...'
                      : _isStreaming
                          ? 'đang gõ...'
                          : 'đang online',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (_isThinking || _isStreaming)
                            ? personaColor
                            : DesignTokens.success,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: DesignTokens.space16),
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

          // Typing indicator — only shown while thinking, not while streaming
          // (streaming message already shows the bubble being typed)
          if (_isThinking)
            _TypingIndicator(personaColor: personaColor),

          // Input bar
          _InputBar(
            controller: _textCtrl,
            onSend: () => _sendMessage(),
            isBusy: _isBusy,
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
      case Persona.lay:    return '😎';
      case Persona.mentor: return '🧠';
      case Persona.soul:   return '🌙';
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
    if (quota.isLow)   return DesignTokens.warning;
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
      case Persona.lay:    return 'hey! có chuyện gì không? 👀';
      case Persona.mentor: return 'Chào bạn. Hôm nay bạn muốn khám phá điều gì?';
      case Persona.soul:   return 'Tôi ở đây. Cứ chia sẻ khi bạn sẵn sàng 🌙';
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
                    padding: const EdgeInsets.only(bottom: DesignTokens.space8),
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: DesignTokens.textPrimary),
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
                child: Icon(Icons.smart_toy_outlined,
                    size: 16, color: personaColor),
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
                  topLeft:
                      const Radius.circular(DesignTokens.radiusLg),
                  topRight:
                      const Radius.circular(DesignTokens.radiusLg),
                  bottomLeft: Radius.circular(
                      isUser ? DesignTokens.radiusLg : DesignTokens.radiusXs),
                  bottomRight: Radius.circular(
                      isUser ? DesignTokens.radiusXs : DesignTokens.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Empty streaming bubble shows cursor only
                  if (message.content.isEmpty && message.isStreaming)
                    _StreamingCursor(color: personaColor)
                  // WEB-11: completed bot message → inline markdown renderer
                  else if (!isUser && !message.isStreaming)
                    _BotText(
                      text: message.content,
                      baseStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: DesignTokens.textPrimary),
                    )
                  // User messages + streaming bot messages → plain text
                  else
                    Text(
                      message.content,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: isUser
                                ? DesignTokens.onPrimary
                                : DesignTokens.textPrimary,
                          ),
                    ),
                  if (message.content.isNotEmpty && message.isStreaming) ...[
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
    for (final c in _controllers) c.dispose();
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
  final bool isBusy;
  final Color personaColor;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isBusy,
    required this.personaColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: DesignTokens.space16,
        right: DesignTokens.space16,
        top: DesignTokens.space12,
        bottom: DesignTokens.space12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: DesignTokens.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              enabled: !isBusy,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: isBusy ? null : (_) => onSend(),
              decoration: InputDecoration(
                hintText: isBusy ? 'Đang trả lời...' : 'Nhắn gì đó...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
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
            onTap: isBusy ? null : onSend,
            child: AnimatedContainer(
              duration: DesignTokens.durationNormal,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isBusy
                    ? personaColor.withOpacity(0.4)
                    : personaColor,
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Center(
                child: isBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// WEB-11: INLINE MARKDOWN RENDERER
// Handles **bold**, *italic*, ### headers, - bullets, 1. numbered lists.
// Zero dependencies — works identically on web and native.
// ─────────────────────────────────────────
class _BotText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const _BotText({required this.text, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) widgets.add(const SizedBox(height: 4));

      if (line.startsWith('### ')) {
        widgets.add(Text(line.substring(4),
            style: base.copyWith(fontWeight: FontWeight.bold, fontSize: (base.fontSize ?? 14) + 2)));
      } else if (line.startsWith('## ')) {
        widgets.add(Text(line.substring(3),
            style: base.copyWith(fontWeight: FontWeight.bold, fontSize: (base.fontSize ?? 14) + 4)));
      } else if (line.startsWith('# ')) {
        widgets.add(Text(line.substring(2),
            style: base.copyWith(fontWeight: FontWeight.bold, fontSize: (base.fontSize ?? 14) + 6)));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: base),
            Expanded(child: RichText(text: TextSpan(children: _parseInline(line.substring(2), base)))),
          ],
        ));
      } else if (_isNumberedList(line)) {
        final dotIdx = line.indexOf('. ');
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${line.substring(0, dotIdx + 1)}  ', style: base.copyWith(fontWeight: FontWeight.w600)),
            Expanded(child: RichText(text: TextSpan(children: _parseInline(line.substring(dotIdx + 2), base)))),
          ],
        ));
      } else if (line.isEmpty) {
        widgets.add(const SizedBox(height: 4));
      } else {
        widgets.add(RichText(text: TextSpan(children: _parseInline(line, base))));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: widgets);
  }

  bool _isNumberedList(String line) {
    final match = RegExp(r'^\d+\. ').firstMatch(line);
    return match != null;
  }

  List<InlineSpan> _parseInline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    // Match **bold** or *italic* or _italic_
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|_(.+?)_');
    int lastEnd = 0;

    for (final m in pattern.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: base));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: base.copyWith(fontWeight: FontWeight.bold)));
      } else {
        spans.add(TextSpan(text: m.group(2) ?? m.group(3), style: base.copyWith(fontStyle: FontStyle.italic)));
      }
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: base));
    }
    return spans.isEmpty ? [TextSpan(text: text, style: base)] : spans;
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
