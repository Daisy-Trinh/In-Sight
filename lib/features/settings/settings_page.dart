import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/store/app_store.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/models/persona.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        children: [
          // Quota section
          _SectionHeader(label: 'Quota hôm nay'),
          _QuotaCard(store: store),
          const SizedBox(height: DesignTokens.space24),

          // Persona section
          _SectionHeader(label: 'Người bạn đồng hành'),
          _PersonaSwitcher(store: store),
          const SizedBox(height: DesignTokens.space24),

          // Display
          _SectionHeader(label: 'Giao diện'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            trailing: Switch(
              value: store.isDarkMode,
              onChanged: (_) => store.toggleTheme(),
              activeColor: DesignTokens.primary,
            ),
          ),
          const SizedBox(height: DesignTokens.space24),

          // Privacy
          _SectionHeader(label: 'Riêng tư & Dữ liệu'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Chính sách bảo mật',
            onTap: () {/* TODO: open policy page */},
          ),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            label: 'Xóa toàn bộ dữ liệu',
            labelColor: DesignTokens.error,
            iconColor: DesignTokens.error,
            onTap: () => _showCascadeWipe(context, store),
          ),
          const SizedBox(height: DesignTokens.space24),

          // App info
          _SectionHeader(label: 'Về ứng dụng'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Phiên bản 1.0.0',
          ),
          const SizedBox(height: DesignTokens.space48),
        ],
      ),
    );
  }

  void _showCascadeWipe(BuildContext context, AppStore store) {
    showDialog(
      context: context,
      builder: (ctx) => _CascadeWipeDialog(
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await store.cascadeWipe();
          if (context.mounted) {
            context.go(AppRouter.personaSelect);
          }
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

// ─────────────────────────────────────────
// QUOTA CARD
// ─────────────────────────────────────────
class _QuotaCard extends StatelessWidget {
  final AppStore store;
  const _QuotaCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final quota = store.quota;
    final color = quota.isEmpty
        ? DesignTokens.error
        : quota.isLow
            ? DesignTokens.warning
            : DesignTokens.primary;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: color, size: 20),
                  const SizedBox(width: DesignTokens.space8),
                  Text(
                    '${quota.tokensRemaining} / ${quota.tokensGranted} token',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                        ),
                  ),
                ],
              ),
              Text(
                quota.isPremium ? 'Premium ✨' : 'Free',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: LinearProgressIndicator(
              value: quota.percentRemaining,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          if (!quota.isPremium && quota.isEmpty) ...[
            const SizedBox(height: DesignTokens.space12),
            FilledButton.icon(
              onPressed: () {/* TODO: show rewarded ad */},
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Xem video → +10 token'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PERSONA SWITCHER
// ─────────────────────────────────────────
class _PersonaSwitcher extends StatelessWidget {
  final AppStore store;
  const _PersonaSwitcher({required this.store});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Persona.values.map((persona) {
        final isSelected = store.currentPersona == persona;
        final color = DesignTokens.personaColor(persona.id);
        final container = DesignTokens.personaContainerColor(persona.id);
        final emoji = persona == Persona.lay
            ? '😎'
            : persona == Persona.mentor
                ? '🧠'
                : '🌙';

        return Expanded(
          child: GestureDetector(
            onTap: () => store.setPersona(persona),
            child: AnimatedContainer(
              duration: DesignTokens.durationNormal,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
              decoration: BoxDecoration(
                color: isSelected ? container : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(
                  color: isSelected ? color : DesignTokens.outline,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    persona.displayName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              isSelected ? color : DesignTokens.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DesignTokens.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.space8),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: DesignTokens.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? DesignTokens.textSecondary,
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: labelColor,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: DesignTokens.textDisabled,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CASCADE WIPE DIALOG — 2-step confirmation
// ─────────────────────────────────────────
class _CascadeWipeDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _CascadeWipeDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_CascadeWipeDialog> createState() => _CascadeWipeDialogState();
}

class _CascadeWipeDialogState extends State<_CascadeWipeDialog> {
  int _step = 1; // Step 1: warning, Step 2: final confirm

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        title: const Text('⚠️ Xóa toàn bộ dữ liệu?'),
        content: Text(
          'Hành động này sẽ xóa toàn bộ lịch sử trò chuyện, cài đặt, và bộ nhớ AI của bạn. '
          'Dữ liệu sẽ không thể khôi phục.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.textSecondary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => setState(() => _step = 2),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.error,
            ),
            child: const Text('Tiếp tục'),
          ),
        ],
      );
    }

    // Step 2 — final confirm
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      title: const Text('🗑️ Xác nhận lần cuối'),
      content: Text(
        'Bạn có CHẮC CHẮN muốn xóa tất cả? '
        'Sau khi xóa, bạn sẽ bắt đầu lại từ đầu.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DesignTokens.textSecondary,
            ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Không, giữ lại'),
        ),
        FilledButton(
          onPressed: widget.onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.error,
          ),
          child: const Text('Xóa tất cả'),
        ),
      ],
    );
  }
}

// Hack: DesignTokens.space14 doesn't exist — patch
extension _SpacePatch on DesignTokens {
  static const double space14 = 14.0;
}
