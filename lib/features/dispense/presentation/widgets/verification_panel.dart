import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/session_verification.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/verification_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/widgets/verification_explainer_sheet.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

/// Customer-facing panel on the dispense-complete screen, showing the two
/// *distinct* verification guarantees for this fuel session. Watches
/// `verificationProvider(requestId)`, which merges the initial REST
/// snapshot with live `session.recorded`/`session.anchored` realtime
/// events — so this panel updates itself with no polling.
///
/// - **Guarantee 1** ("recorded"): the pump's signed reading has been
///   written to the tamper-evident hash-chain ledger. Shown as soon as the
///   session is linked to this request (`linked == true`) — immediate.
/// - **Guarantee 2** ("independently checkpointed" / "anchored"): a
///   separate, *stronger* guarantee that the record can no longer be
///   altered undetectably, even by us. This lags recording by design
///   (checkpoints run on an interval), so it starts out `pending` and only
///   reads as satisfied once `anchored == true` — animated via
///   [AnimatedSwitcher] so the flip is visibly live, not a silent refresh.
///
/// CLAIM DISCIPLINE (see `.superpowers/sdd/task-6-brief.md`): this ships to
/// a regulator pilot's customers, so the copy here must never say
/// "guaranteed", "cryptographically guaranteed", "non-repudiable", or
/// "cannot be faked" — the ledger is tamper-*evident*, not tamper-proof,
/// and a pending (unanchored) record is weaker than an anchored one. Do
/// not strengthen this wording without updating the brief.
class VerificationPanel extends ConsumerWidget {
  const VerificationPanel({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationAsync = ref.watch(verificationProvider(requestId));
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: verificationAsync.when(
        data: (verification) => verification.linked
            ? _LinkedGuarantees(verification: verification)
            : const _AwaitingRow(),
        loading: () => const _AwaitingRow(),
        // A transient fetch failure for this *supplementary* verification
        // panel must never read as an error about the dispense itself
        // (which has already succeeded) — and per the brief, the
        // not-linked/awaiting state specifically must never render as an
        // error card either. Both get the same calm, non-alarming
        // treatment rather than a red error banner.
        error: (_, _) => const _UnavailableRow(),
      ),
    );
  }
}

// ── Awaiting (not yet linked, or initial fetch in flight) ──────────────────

class _AwaitingRow extends StatelessWidget {
  const _AwaitingRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Waiting for the pump's signed reading…",
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Unavailable (fetch error — quiet, never alarming) ───────────────────────

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Verification status unavailable right now.',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Linked: both guarantee rows ─────────────────────────────────────────────

class _LinkedGuarantees extends StatelessWidget {
  const _LinkedGuarantees({required this.verification});

  final SessionVerification verification;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guarantee 1 — recorded on the ledger. True as soon as linked and
        // does not change when Guarantee 2 flips, so it stays outside the
        // AnimatedSwitcher below.
        Text(
          '✓ Recorded on the tamper-evident fuel ledger — position '
          '#${verification.startSeq}–${verification.endSeq}, bound to your '
          'authorization.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
        const SizedBox(height: 14),

        // Guarantee 2 — animates between "pending" and "anchored" whenever
        // `anchored` flips true (live, via the realtime `session.anchored`
        // event merged in `verificationProvider`).
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: verification.anchored
              ? const _AnchoredGuarantee(key: ValueKey('anchored'))
              : const _PendingGuarantee(key: ValueKey('pending')),
        ),
      ],
    );
  }
}

// ── Guarantee 2: pending ─────────────────────────────────────────────────

class _PendingGuarantee extends StatelessWidget {
  const _PendingGuarantee({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: PulsingDot(color: AppColors.warning, size: 8, pulseSize: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
                  children: const [
                    TextSpan(text: 'Independent checkpoint: '),
                    TextSpan(
                      text: 'pending',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                    TextSpan(text: ' — recorded, awaiting independent anchor'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _ExplainerButton(),
      ],
    );
  }
}

// ── Guarantee 2: anchored ────────────────────────────────────────────────

class _AnchoredGuarantee extends StatelessWidget {
  const _AnchoredGuarantee({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.verified_rounded,
                  size: 16, color: AppColors.success),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
                  children: const [
                    TextSpan(text: 'Independent checkpoint: '),
                    TextSpan(
                      text: 'anchored',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            '✓ Independently checkpointed — this record can no longer be '
            'altered undetectably, even by us.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.92),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 26),
          child: _ExplainerButton(),
        ),
      ],
    );
  }
}

// ── "What does this mean?" ───────────────────────────────────────────────

class _ExplainerButton extends StatelessWidget {
  const _ExplainerButton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: cs.primary,
        ),
        onPressed: () => showVerificationExplainer(context),
        child: const Text(
          'What does this mean?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
