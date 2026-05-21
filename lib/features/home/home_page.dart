import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/store/app_store.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/models/persona.dart';

// ─────────────────────────────────────────
// SPLASH PAGE
// ─────────────────────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignTokens.durationXSlow,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    // Auto-navigate sau 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        final store = context.read<AppStore>();
        if (store.hasOnboarded) {
          context.go(AppRouter.chat);
        } else {
          context.go(AppRouter.personaSelect);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radius2xl),
                  ),
                  child: const Icon(
                    Icons.self_improvement_rounded,
                    size: 40,
                    color: DesignTokens.primary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space24),
                Text(
                  'In-Sight',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: DesignTokens.primary,
                      ),
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(
                  'người bạn đồng hành nội tâm',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                ),
                const SizedBox(height: DesignTokens.space48),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DesignTokens.primary.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PERSONA SELECT PAGE
// ─────────────────────────────────────────
class PersonaSelectPage extends StatelessWidget {
  const PersonaSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignTokens.space32),
              Text(
                'Chọn người bạn\nđồng hành của bạn',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: DesignTokens.space8),
              Text(
                'Mỗi người có một cách lắng nghe riêng',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
              ),
              const SizedBox(height: DesignTokens.space32),
              Expanded(
                child: ListView(
                  children: [
                    _PersonaCard(persona: Persona.lay),
                    const SizedBox(height: DesignTokens.space16),
                    _PersonaCard(persona: Persona.mentor),
                    const SizedBox(height: DesignTokens.space16),
                    _PersonaCard(persona: Persona.soul),
                    const SizedBox(height: DesignTokens.space32),
                    Text(
                      '✨ Bạn có thể đổi persona bất cứ lúc nào trong cài đặt',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final Persona persona;
  const _PersonaCard({required this.persona});

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

  String get _title {
    switch (persona) {
      case Persona.lay:
        return 'Lầy — Bạn thân Gen-Z';
      case Persona.mentor:
        return 'Mentor — Người dẫn đường';
      case Persona.soul:
        return 'Soul — Người lắng nghe';
    }
  }

  String get _description {
    switch (persona) {
      case Persona.lay:
        return 'Nói chuyện như bạn thân, roast nhẹ, đồng cảm thật, slang Gen-Z. Không phán xét.';
      case Persona.mentor:
        return 'Frameworks, Stoic wisdom, câu hỏi sắc bén. Giúp bạn nhìn thấy con đường.';
      case Persona.soul:
        return 'Lắng nghe sâu, phản chiếu cảm xúc, hiện diện trọn vẹn. Không rush.';
    }
  }

  Color get _color => DesignTokens.personaColor(persona.id);
  Color get _containerColor => DesignTokens.personaContainerColor(persona.id);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final store = context.read<AppStore>();
        store.setPersona(persona);
        store.markOnboarded();
        context.go(AppRouter.chat, extra: persona);
      },
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        padding: const EdgeInsets.all(DesignTokens.space20),
        decoration: BoxDecoration(
          color: _containerColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(color: _color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Center(
                child: Text(_emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: DesignTokens.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: DesignTokens.textPrimary,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    _description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _color,
            ),
          ],
        ),
      ),
    );
  }
}
