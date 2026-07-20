import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/session_verification.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/verification_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/widgets/verification_panel.dart';

const _requestId = 'req-1';

// ---------------------------------------------------------------------------
// Fake notifier — must extend VerificationController so overrideWith
// type-checks. Mirrors the pattern in
// test/features/dispense/presentation/screens/dispense_history_screen_test.dart
// (_FakeDispenseNotifier), skipping the real REST/realtime wiring entirely
// so the panel can be pumped with an exact, hand-built SessionVerification.
// ---------------------------------------------------------------------------

class _FakeVerificationController extends VerificationController {
  _FakeVerificationController(this._value);

  final SessionVerification _value;

  @override
  Future<SessionVerification> build(String requestId) async => _value;
}

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

Future<void> pumpPanel(
  WidgetTester tester,
  SessionVerification verification,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Family-level override: `verificationProvider(id)` has no
        // `.overrideWith` of its own (that method lives on the family, not
        // on the per-arg provider it returns) — the factory below is used
        // for whichever arg is watched, which in these tests is always
        // `_requestId`.
        verificationProvider
            .overrideWith(() => _FakeVerificationController(verification)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: VerificationPanel(requestId: _requestId)),
      ),
    ),
  );
  // Not pumpAndSettle: the pending state's live-pulse indicator and the
  // awaiting state's spinner both animate indefinitely, which would hang.
  // A single zero-duration pump() (no explicit Duration) leaves
  // flutter_animate's internal `Future.delayed(widget.delay, _play)` still
  // pending at test teardown, which flutter_test flags as a leaked timer —
  // an explicit (even zero) Duration makes pump() advance the fake clock
  // far enough to fire it.
  await tester.pump();
  await tester.pump(Duration.zero);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('VerificationPanel — pending (recorded, not yet anchored)', () {
    testWidgets(
      'shows Guarantee 1 satisfied, Guarantee 2 pending, no overclaim',
      (tester) async {
        await pumpPanel(
          tester,
          const SessionVerification(
            linked: true,
            classification: 'authorized',
            startSeq: 142,
            endSeq: 147,
            anchored: false,
          ),
        );

        expect(find.textContaining('Recorded on'), findsOneWidget);
        expect(find.textContaining('#142'), findsOneWidget);
        expect(
          find.textContaining('awaiting independent anchor'),
          findsOneWidget,
        );
        // Never overclaim.
        expect(find.textContaining('non-repudiable'), findsNothing);
        expect(find.textContaining('cannot be faked'), findsNothing);
        expect(find.textContaining('guaranteed'), findsNothing);
      },
    );
  });

  group('VerificationPanel — anchored', () {
    testWidgets('shows independently anchored', (tester) async {
      await pumpPanel(
        tester,
        const SessionVerification(
          linked: true,
          anchored: true,
          anchoredSeq: 150,
          startSeq: 142,
          endSeq: 147,
        ),
      );

      expect(find.textContaining('Independently'), findsOneWidget);
      expect(find.textContaining('anchored'), findsOneWidget);
      // Still no overclaim once anchored.
      expect(find.textContaining('non-repudiable'), findsNothing);
      expect(find.textContaining('cannot be faked'), findsNothing);
      expect(find.textContaining('guaranteed'), findsNothing);
    });
  });

  group('VerificationPanel — not linked', () {
    testWidgets('shows awaiting session, never an error card', (tester) async {
      await pumpPanel(
        tester,
        const SessionVerification(linked: false, anchored: false),
      );

      expect(find.textContaining('Waiting for the pump'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);
    });
  });
}
