import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/main.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: authState.maybeWhen(
        authenticated: (user) => CustomScrollView(
          slivers: [
            // Dark expanding header
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient bg
                    Container(
                      color: cs.surface,
                    ),
                    Positioned(
                      top: -60,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 0.7,
                            colors: [cs.primary.withValues(alpha: 0.25), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Avatar + name
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          // Gradient avatar
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user.firstName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Account section
            _Section(
              title: 'Account',
              tiles: [
                _DarkTile(
                  icon: Icons.person_outline,
                  iconColor: cs.primary,
                  title: 'Personal Information',
                  subtitle: 'Update your name and phone',
                  onTap: () => context.push(Routes.editProfile),
                ),
                _DarkTile(
                  icon: Icons.lock_outline,
                  iconColor: cs.secondary,
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
                _DarkTile(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () => _showNotificationsSheet(context),
                ),
                _DarkTile(
                  icon: Icons.language_outlined,
                  iconColor: AppColors.info,
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
                _DarkTile(
                  icon: Icons.help_outline,
                  iconColor: AppColors.success,
                  title: 'Help & Support',
                  subtitle: 'Get help with FuelEase',
                  onTap: () => _showHelpSheet(context),
                ),
                _DarkTile(
                  icon: Icons.info_outline,
                  iconColor: Colors.white.withValues(alpha: 0.5),
                  title: 'About',
                  subtitle: ref.watch(_packageInfoProvider).whenOrNull(
                        data: (info) => 'Version ${info.version} (${info.buildNumber})',
                      ) ??
                      'App version and information',
                  onTap: () => _showAboutDialog(context, ref),
                ),
                _DarkTile(
                  icon: Icons.description_outlined,
                  iconColor: Colors.white.withValues(alpha: 0.5),
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
                child: GestureDetector(
                  onTap: () => _handleLogout(context, ref),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                      color: AppColors.error.withValues(alpha: 0.07),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        const Text(
                          'Log Out',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log Out',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to log out?',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Log Out',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(Routes.welcome);
    }
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    final info = ref.read(_packageInfoProvider).valueOrNull;
    final version = info != null ? '${info.version}+${info.buildNumber}' : '—';
    showAboutDialog(
      context: context,
      applicationName: 'FuelEase',
      applicationVersion: version,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.local_gas_station_rounded,
            color: Colors.white, size: 24),
      ),
      children: const [
        Text(
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
      ThemeMode.light => 'Milk (Light)',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };
    return _DarkTile(
      icon: Icons.dark_mode_outlined,
      iconColor: const Color(0xFF8B5CF6),
      title: 'Theme',
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

// ── Sheet openers ─────────────────────────────────────────────────────────

void _showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => const _NotificationsSheet(),
  );
}

void _showLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => const _LanguageSheet(),
  );
}

void _showThemeSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    backgroundColor: Theme.of(context).colorScheme.surface,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => const _HelpSheet(),
  );
}

void _showTermsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => const _TermsSheet(),
  );
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 2),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.2,
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

class _DarkTile extends StatelessWidget {
  const _DarkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.25),
              size: 18,
            ),
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
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _DarkToggle extends StatelessWidget {
  const _DarkToggle({
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: cs.primary,
            activeTrackColor: cs.primary.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }
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
          const Text(
            'Notifications',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose which notifications you receive',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
          const SizedBox(height: 20),
          _DarkToggle(
            title: 'Fuel Dispensing',
            subtitle: 'Approval, rejection, and completion alerts',
            value: _dispensing,
            onChanged: (v) => setState(() => _dispensing = v),
          ),
          _DarkToggle(
            title: 'Wallet Activity',
            subtitle: 'Top-ups, purchases, and balance alerts',
            value: _wallet,
            onChanged: (v) => setState(() => _wallet = v),
          ),
          _DarkToggle(
            title: 'Promotions',
            subtitle: 'Offers and announcements from FuelEase',
            value: _promotions,
            onChanged: (v) => setState(() => _promotions = v),
          ),
          const SizedBox(height: 8),
          GradientButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferences saved')),
              );
            },
            label: 'Save Preferences',
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
  static const _options = ['English', 'Swahili'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const Text(
            'Language',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ..._options.map(
            (lang) => GestureDetector(
              onTap: () => setState(() => _selected = lang),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _selected == lang
                      ? cs.primary.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selected == lang
                        ? cs.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lang,
                        style: TextStyle(
                          color: _selected == lang
                              ? cs.primary
                              : Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_selected == lang)
                      Icon(Icons.check_rounded,
                          color: cs.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GradientButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Apply',
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
    ('Milk (Light)', ThemeMode.light),
    ('Dark', ThemeMode.dark),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          Text(
            'Theme',
            style: TextStyle(
                color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your preferred appearance',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._options.map(
            ((String label, ThemeMode mode) opt) => GestureDetector(
              onTap: () async {
                ref.read(themeModeProvider.notifier).state = opt.$2;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('fe_theme', switch (opt.$2) {
                  ThemeMode.light => 'light',
                  ThemeMode.dark => 'dark',
                  ThemeMode.system => 'system',
                });
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: current == opt.$2
                      ? cs.primary.withValues(alpha: 0.12)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: current == opt.$2
                        ? cs.primary.withValues(alpha: 0.4)
                        : cs.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt.$1,
                        style: TextStyle(
                          color: current == opt.$2
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (current == opt.$2)
                      Icon(Icons.check_rounded,
                          color: cs.primary, size: 18),
                  ],
                ),
              ),
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
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            _SheetHandle(),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.help_outline,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Help & Support',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Email us at support@fuelease.co.tz\nor call +255 800 FUEL (3835)',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
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
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            _SheetHandle(),
            const Text(
              'Terms & Privacy Policy',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
            ),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── FAQ + Terms widgets ───────────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _open
              ? cs.surfaceContainerHighest
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _open
                ? cs.primary.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.q,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 10),
              Text(
                widget.a,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ],
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
