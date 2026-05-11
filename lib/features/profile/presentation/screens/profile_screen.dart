import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/main.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: authState.maybeWhen(
        authenticated: (user) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: cs.surface,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: cs.primary,
                          child: Text(
                            user.firstName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Account section
            _Section(
              title: 'Account',
              tiles: [
                _Tile(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Update your name and phone',
                  onTap: () => context.push(Routes.editProfile),
                ),
                _Tile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => context.push(Routes.changePassword),
                ),
              ],
            ),

            // Preferences section
            _Section(
              title: 'Preferences',
              tiles: [
                _Tile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () => _showNotificationsSheet(context),
                ),
                _Tile(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => _showLanguageSheet(context),
                ),
                _ThemeTile(onTap: () => _showThemeSheet(context, ref)),
              ],
            ),

            // Support section
            _Section(
              title: 'Support',
              tiles: [
                _Tile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with FuelEase',
                  onTap: () => _showHelpSheet(context),
                ),
                _Tile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () => _showAboutDialog(context),
                ),
                _Tile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Privacy',
                  subtitle: 'Read our terms and privacy policy',
                  onTap: () => _showTermsSheet(context),
                ),
              ],
            ),

            // Logout
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: TextButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.error),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(Routes.welcome);
    }
  }

  void _showAboutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showAboutDialog(
      context: context,
      applicationName: 'FuelEase',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          'F',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      children: [
        const Text(
          'FuelEase is a digital fuel management platform that makes it easy '
          'to manage your fuel purchases, share fuel credits, and track your '
          'fuel usage.',
        ),
      ],
    );
  }
}

// ── Theme tile with live subtitle ─────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final subtitle = switch (mode) {
      ThemeMode.light => 'Light mode',
      ThemeMode.dark => 'Dark mode',
      ThemeMode.system => 'System default',
    };
    return _Tile(
      icon: Icons.dark_mode_outlined,
      title: 'Theme',
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

// ── Inline sheets ──────────────────────────────────────────────────────────

void _showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: AppColors.surface,
    builder: (ctx) => const _NotificationsSheet(),
  );
}

void _showLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: AppColors.surface,
    builder: (ctx) => const _LanguageSheet(),
  );
}

void _showThemeSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: const _ThemeSheet(),
    ),
  );
}

void _showHelpSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: AppColors.surface,
    builder: (ctx) => const _HelpSheet(),
  );
}

void _showTermsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: AppColors.surface,
    builder: (ctx) => const _TermsSheet(),
  );
}

// ── Sheet content widgets ──────────────────────────────────────────────────

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _dispensing = true;
  bool _wallet = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          Text('Notifications', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Choose which notifications you receive',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _Toggle(
            title: 'Fuel Dispensing',
            subtitle: 'Approval, rejection, and completion alerts',
            value: _dispensing,
            onChanged: (v) => setState(() => _dispensing = v),
          ),
          _Toggle(
            title: 'Wallet Activity',
            subtitle: 'Top-ups, purchases, and balance alerts',
            value: _wallet,
            onChanged: (v) => setState(() => _wallet = v),
          ),
          _Toggle(
            title: 'Promotions',
            subtitle: 'Offers and announcements from FuelEase',
            value: _promotions,
            onChanged: (v) => setState(() => _promotions = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences saved')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Preferences',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet();

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  String _selected = 'English';
  final _options = const ['English', 'Swahili'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          Text('Language', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          ..._options.map(
            (lang) => RadioListTile<String>(
              value: lang,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v!),
              title: Text(lang, style: AppTextStyles.bodyMedium),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet();

  static const _options = [
    ('System default', ThemeMode.system),
    ('Light', ThemeMode.light),
    ('Dark', ThemeMode.dark),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          Text('Theme', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Choose your preferred appearance',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ..._options.map(
            ((String label, ThemeMode mode) opt) => RadioListTile<ThemeMode>(
              value: opt.$2,
              groupValue: current,
              onChanged: (v) async {
                if (v == null) return;
                ref.read(themeModeProvider.notifier).state = v;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('fe_theme', switch (v) {
                  ThemeMode.light => 'light',
                  ThemeMode.dark => 'dark',
                  ThemeMode.system => 'system',
                });
                if (context.mounted) Navigator.of(context).pop();
              },
              title: Text(opt.$1, style: AppTextStyles.bodyMedium),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            _SheetHandle(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Text('Help & Support', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: 24),
            _FaqItem(
              q: 'How do I top up my wallet?',
              a: 'Go to Wallet → tap the "Top Up" button → enter the amount and your mobile money number → confirm the payment prompt on your phone.',
            ),
            _FaqItem(
              q: 'How does fuel dispensing work?',
              a: 'Create a request under "Fuel", select a station, enter the litres needed. Once approved, a PIN and QR code are shown — present these at the pump.',
            ),
            _FaqItem(
              q: 'Why was my request rejected?',
              a: 'Common reasons: insufficient wallet balance, fuel type not available at the chosen station, or the station is temporarily suspended.',
            ),
            _FaqItem(
              q: 'Can I cancel a pending request?',
              a: 'Yes. Open the request from the Fuel tab and tap "Cancel". Cancelled requests release any held funds immediately.',
            ),
            _FaqItem(
              q: 'My card is blocked — what do I do?',
              a: 'Contact your organisation\'s administrator or reach FuelEase support at support@fuelease.co.tz.',
            ),
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final cs = Theme.of(context).colorScheme;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Still need help?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Email us at support@fuelease.co.tz\nor call +255 800 FUEL (3835)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            _SheetHandle(),
            Text('Terms & Privacy Policy', style: AppTextStyles.titleMedium),
            const SizedBox(height: 20),
            _TermsSection(
              title: '1. Acceptance of Terms',
              body:
                  'By using the FuelEase application you agree to these Terms of Service. '
                  'If you do not agree, please discontinue use of the app immediately.',
            ),
            _TermsSection(
              title: '2. User Accounts',
              body:
                  'You are responsible for maintaining the confidentiality of your account '
                  'credentials. Notify us immediately if you suspect unauthorised access.',
            ),
            _TermsSection(
              title: '3. Wallet & Payments',
              body:
                  'Wallet top-ups are processed via AzamPay mobile-money integration. '
                  'FuelEase is not responsible for delays caused by mobile network operators '
                  'or payment gateways.',
            ),
            _TermsSection(
              title: '4. Fuel Dispensing',
              body:
                  'Dispensing requests are subject to station availability and sufficient '
                  'wallet balance. Approved requests generate a one-time PIN valid for a '
                  'limited period.',
            ),
            _TermsSection(
              title: '5. Privacy',
              body:
                  'We collect the minimum data required to deliver the service: name, email, '
                  'phone number (encrypted at rest), and transaction records. We do not sell '
                  'personal data to third parties.',
            ),
            _TermsSection(
              title: '6. Data Retention',
              body:
                  'Transaction and session data is retained for up to 7 years in accordance '
                  'with Tanzania financial regulations (BOT guidelines).',
            ),
            _TermsSection(
              title: '7. Contact',
              body:
                  'For privacy-related enquiries contact privacy@fuelease.co.tz. '
                  'For general support contact support@fuelease.co.tz.',
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: January 2025',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(
                title.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            ...tiles,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.q, required this.a});

  final String q;
  final String a;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.q,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 10),
                Text(
                  widget.a,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
