import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/features/dispense/presentation/widgets/verification_explainer_sheet.dart';

// ---------------------------------------------------------------------------
// Guards the claim discipline documented in
// `.superpowers/sdd/task-6-brief.md` and in the doc comment on
// `showVerificationExplainer`: this sheet is the longest, most detailed
// piece of verification-related prose shipped to the pilot's customers, so
// it must stay scrupulously honest rather than reassuring. This test opens
// the real sheet (via its only public entry point) and asserts the rendered
// text contains the honest "tamper-evident" framing while never rendering
// any of the banned overclaims.
// ---------------------------------------------------------------------------

Future<void> _openExplainerSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showVerificationExplainer(context),
              child: const Text('Open explainer'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open explainer'));
  // The sheet has no unbounded/indefinite animations of its own (unlike the
  // panel's pulse/spinner), so pumpAndSettle is safe here.
  await tester.pumpAndSettle();
}

void main() {
  group('VerificationExplainerSheet — claim discipline', () {
    testWidgets('renders the honest tamper-evident framing', (tester) async {
      await _openExplainerSheet(tester);

      expect(find.textContaining('tamper-evident'), findsWidgets);
      expect(find.textContaining('How this verification works'),
          findsOneWidget);
    });

    testWidgets('never renders any of the banned overclaims', (tester) async {
      await _openExplainerSheet(tester);

      // These claims must be entirely absent from the rendered sheet,
      // regardless of context — unlike "tamper-proof", which legitimately
      // appears once in the negated form "not tamper-proof" and so isn't
      // asserted here.
      expect(find.textContaining('non-repudiable'), findsNothing);
      expect(find.textContaining('cannot be faked'), findsNothing);
      expect(find.textContaining('cryptographically guaranteed'), findsNothing);
    });
  });
}
