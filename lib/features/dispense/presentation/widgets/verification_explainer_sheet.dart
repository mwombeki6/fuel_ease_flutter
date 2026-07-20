import 'package:flutter/material.dart';

import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Shows a bottom sheet explaining, in plain language, what this fuel
/// session's two verification guarantees actually mean — and, just as
/// importantly, what they don't. Call via [showVerificationExplainer].
///
/// CLAIM DISCIPLINE (see `.superpowers/sdd/task-6-brief.md`): this is the
/// one place customers can go to read the full picture, so it must stay
/// scrupulously honest rather than reassuring:
/// - The hash-chain record is tamper-*evident* and written immediately —
///   never described as tamper-proof, "guaranteed", "non-repudiable", or
///   something that "cannot be faked".
/// - The independent checkpoint (anchor) is a *separate, stronger*
///   guarantee layered on top later — it does not retroactively make
///   earlier claims stronger than they were.
/// - Records written since the last checkpoint are explicitly called out as
///   *weaker* than an anchored record, not just "not yet done".
/// - This pilot's checkpoint is a tamper-evident HMAC anchor; asymmetric
///   device identity (each pump signing with its own private key) is named
///   as future work, not implied to already exist.
void showVerificationExplainer(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _VerificationExplainerSheet(),
  );
}

class _VerificationExplainerSheet extends StatelessWidget {
  const _VerificationExplainerSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'How this verification works',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              _ExplainerSection(
                icon: Icons.link_rounded,
                iconColor: cs.primary,
                title: 'Recorded on the ledger',
                body:
                    "As soon as the pump's signed reading reaches us, it's "
                    'written into a hash-chain ledger: each entry is bound '
                    'to the one before it, so any later edit or deletion '
                    'breaks the chain and is evident. This is tamper-'
                    'evident, not tamper-proof, and it happens immediately '
                    '— at the moment your session is recorded.',
              ),
              const SizedBox(height: 18),

              _ExplainerSection(
                icon: Icons.verified_rounded,
                iconColor: AppColors.success,
                title: 'Independent checkpoint (anchoring)',
                body:
                    'Periodically, a batch of ledger entries is '
                    'independently checkpointed with a tamper-evident HMAC '
                    'anchor. This is a separate, stronger guarantee than '
                    'recording alone: once a record is anchored, it can no '
                    'longer be altered undetectably, even by us.',
              ),
              const SizedBox(height: 18),

              _ExplainerSection(
                icon: Icons.hourglass_top_rounded,
                iconColor: AppColors.warning,
                title: 'Between checkpoints',
                body:
                    'Records written since the last checkpoint are still '
                    "tamper-evident, but haven't been independently "
                    'anchored yet — that unanchored tail is weaker than an '
                    'anchored record until the next checkpoint runs.',
              ),
              const SizedBox(height: 18),

              _ExplainerSection(
                icon: Icons.info_outline_rounded,
                iconColor: cs.onSurface.withValues(alpha: 0.6),
                title: 'What this pilot covers',
                body:
                    "This pilot's independent checkpoint is a tamper-"
                    'evident HMAC anchor. Asymmetric device identity — '
                    'each pump signing readings with its own private key — '
                    'is planned future work and is not part of this pilot '
                    'yet.',
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: cs.outlineVariant),
                    foregroundColor: cs.onSurface,
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplainerSection extends StatelessWidget {
  const _ExplainerSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: cs.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
