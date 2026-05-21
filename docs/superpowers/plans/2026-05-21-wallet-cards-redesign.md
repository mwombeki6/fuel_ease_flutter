# Wallet & Cards Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign wallet and cards screens with theme-aware surfaces, spending analytics, a flip-animated fuel card with EMV chip, and a card details screen with dispense session history and status timeline.

**Architecture:** New providers derive analytics data from existing `walletProvider` and `dispenseProvider` — no new API endpoints. Card visual is factored into a shared `CardFrontFace`/`CardBackFace`/`FlipFuelCard` widget hierarchy used by both the list item and details screen.

**Tech Stack:** Flutter 3, Riverpod 2 (`Provider`, `Provider.family`), `fl_chart ^0.69.2` (already in pubspec), `flutter_animate`, `CustomPainter` for EMV chip.

---

### Task 1: Spending + Card Sessions Providers

**Files:**
- Create: `lib/features/wallet/presentation/providers/spending_providers.dart`
- Create: `lib/features/cards/presentation/providers/card_sessions_provider.dart`
- Create: `test/features/wallet/presentation/providers/spending_providers_test.dart`
- Create: `test/features/cards/presentation/providers/card_sessions_provider_test.dart`

- [ ] **Step 1: Write failing test for `weeklySpendProvider`**

Create `test/features/wallet/presentation/providers/spending_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_summary.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/spending_providers.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';

WalletTransaction _tx(String type, int amountTzs, DateTime createdAt) =>
    WalletTransaction(
      id: 'tx-$amountTzs',
      walletId: 'w1',
      type: type,
      amountTzs: amountTzs,
      balanceAfterTzs: 0,
      createdAt: createdAt,
    );

Wallet _wallet() => Wallet(
      id: 'w1',
      balanceTzs: 100000,
      status: 'active',
      updatedAt: DateTime.now(),
    );

void main() {
  test('weeklySpendProvider sums debits within last 7 days', () {
    final now = DateTime.now();
    final txs = [
      _tx('debit', 5000, now.subtract(const Duration(days: 2))),   // in range
      _tx('debit', 3000, now.subtract(const Duration(days: 6))),   // in range
      _tx('debit', 9999, now.subtract(const Duration(days: 8))),   // out of range
      _tx('credit', 1000, now.subtract(const Duration(days: 1))),  // credit — ignored
    ];

    final container = ProviderContainer(
      overrides: [
        walletProvider.overrideWith(() => _FakeWalletNotifier(
              WalletSummary(wallet: _wallet(), recentTransactions: txs),
            )),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(weeklySpendProvider), 8000);
  });

  test('spendingChartDataProvider keys are 0–29, credits excluded', () {
    final now = DateTime.now();
    final txs = [
      _tx('debit', 2000, now),                                       // today = key 0
      _tx('debit', 4000, now.subtract(const Duration(days: 15))),    // key 15
      _tx('credit', 1000, now.subtract(const Duration(days: 1))),    // ignored
      _tx('debit', 500, now.subtract(const Duration(days: 31))),     // out of range
    ];

    final container = ProviderContainer(
      overrides: [
        walletProvider.overrideWith(() => _FakeWalletNotifier(
              WalletSummary(wallet: _wallet(), recentTransactions: txs),
            )),
      ],
    );
    addTearDown(container.dispose);

    final data = container.read(spendingChartDataProvider);
    expect(data[0], 2000);
    expect(data[15], 4000);
    expect(data.containsKey(31), isFalse);
    expect(data.values.every((v) => v > 0), isTrue);
  });
}

class _FakeWalletNotifier extends WalletNotifier {
  _FakeWalletNotifier(this._value);
  final WalletSummary _value;

  @override
  Future<WalletSummary> build() async => _value;
}
```

- [ ] **Step 2: Run test, confirm it fails**

```bash
cd /home/mwombeki/Desktop/fuel-card/fuel_ease_flutter
flutter test test/features/wallet/presentation/providers/spending_providers_test.dart
```

Expected: error — `spending_providers.dart` does not exist yet.

- [ ] **Step 3: Create `spending_providers.dart`**

Create `lib/features/wallet/presentation/providers/spending_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';

/// Sum of all debit transactions within the last 7 days (integer TZS).
final weeklySpendProvider = Provider<int>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(data: (summary) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (summary.recentTransactions ?? [])
        .where((t) => t.isDebit && (t.createdAt?.isAfter(cutoff) ?? false))
        .fold(0, (sum, t) => sum + t.amountTzs);
  }) ?? 0;
});

/// Days-ago (0 = today) → total debit TZS for the last 30 days.
/// Used by the wallet spending bar chart.
final spendingChartDataProvider = Provider<Map<int, int>>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(data: (summary) {
    final now = DateTime.now();
    final result = <int, int>{};
    for (final t in (summary.recentTransactions ?? [])) {
      if (!t.isDebit) continue;
      final date = t.createdAt;
      if (date == null) continue;
      final daysAgo = now.difference(date).inDays;
      if (daysAgo < 0 || daysAgo >= 30) continue;
      result[daysAgo] = (result[daysAgo] ?? 0) + t.amountTzs;
    }
    return result;
  }) ?? {};
});
```

- [ ] **Step 4: Run test, confirm it passes**

```bash
flutter test test/features/wallet/presentation/providers/spending_providers_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Write failing test for `cardSessionsProvider`**

Create `test/features/cards/presentation/providers/card_sessions_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/card_sessions_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';

DispenseRequest _req(String id, String cardId, DateTime createdAt) =>
    DispenseRequest(
      id: id,
      cardId: cardId,
      stationId: 'station-1',
      requestedLiters: 10.0,
      pricePerLiterTzs: 4000,
      status: 'completed',
      createdAt: createdAt,
    );

void main() {
  test('cardSessionsProvider filters by cardId and sorts most-recent first', () {
    final now = DateTime.now();
    final allRequests = [
      _req('r1', 'card-A', now.subtract(const Duration(hours: 5))),
      _req('r2', 'card-B', now.subtract(const Duration(hours: 2))),
      _req('r3', 'card-A', now.subtract(const Duration(hours: 1))),
    ];

    final container = ProviderContainer(
      overrides: [
        dispenseProvider.overrideWith(
          () => _FakeDispenseNotifier(allRequests),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sessions = container.read(cardSessionsProvider('card-A'));
    expect(sessions.length, 2);
    expect(sessions.first.id, 'r3'); // most recent first
    expect(sessions.last.id, 'r1');
  });

  test('cardSessionsProvider returns empty list when dispenseProvider loading', () {
    final container = ProviderContainer(
      overrides: [
        dispenseProvider.overrideWith(() => _LoadingDispenseNotifier()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(cardSessionsProvider('card-A')), isEmpty);
  });
}

class _FakeDispenseNotifier extends DispenseNotifier {
  _FakeDispenseNotifier(this._data);
  final List<DispenseRequest> _data;

  @override
  Future<List<DispenseRequest>> build() async => _data;
}

class _LoadingDispenseNotifier extends DispenseNotifier {
  @override
  Future<List<DispenseRequest>> build() => Completer<List<DispenseRequest>>().future;
}
```

Add `import 'dart:async';` to the top of that file.

- [ ] **Step 6: Run test, confirm it fails**

```bash
flutter test test/features/cards/presentation/providers/card_sessions_provider_test.dart
```

Expected: error — `card_sessions_provider.dart` does not exist yet.

- [ ] **Step 7: Create `card_sessions_provider.dart`**

Create `lib/features/cards/presentation/providers/card_sessions_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';

/// All dispense sessions for [cardId], sorted most-recent first.
final cardSessionsProvider =
    Provider.family<List<DispenseRequest>, String>((ref, cardId) {
  final dispenseState = ref.watch(dispenseProvider);
  return dispenseState.whenOrNull(data: (requests) {
    return [...requests.where((r) => r.cardId == cardId)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }) ?? [];
});
```

- [ ] **Step 8: Run tests, confirm both pass**

```bash
flutter test test/features/wallet/presentation/providers/spending_providers_test.dart test/features/cards/presentation/providers/card_sessions_provider_test.dart
```

Expected: All tests pass.

- [ ] **Step 9: Verify no analysis errors**

```bash
flutter analyze lib/features/wallet/presentation/providers/spending_providers.dart lib/features/cards/presentation/providers/card_sessions_provider.dart
```

Expected: No issues found.

- [ ] **Step 10: Commit**

```bash
git add lib/features/wallet/presentation/providers/spending_providers.dart \
        lib/features/cards/presentation/providers/card_sessions_provider.dart \
        test/features/wallet/ \
        test/features/cards/
git commit -m "feat: add spending analytics and card sessions providers"
```

---

### Task 2: FlipFuelCard Widget

**Files:**
- Create: `lib/features/cards/presentation/widgets/flip_fuel_card.dart`

- [ ] **Step 1: Create `flip_fuel_card.dart`**

Create `lib/features/cards/presentation/widgets/flip_fuel_card.dart`:

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

// ── EMV chip ────────────────────────────────────────────────────────────────

class ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shader = const LinearGradient(
      colors: [Color(0xFFD4AF37), Color(0xFFF5D97F), Color(0xFFD4AF37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fill = Paint()..shader = shader;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, fill);

    final line = Paint()
      ..color = const Color(0xFFB8962E).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), line);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _CardStatusBadge extends StatelessWidget {
  const _CardStatusBadge({required this.status});
  final String status;

  Color get _color => switch (status) {
        'active' => AppColors.success,
        'blocked' => AppColors.error,
        'expired' => AppColors.textSecondaryDark,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Front face ───────────────────────────────────────────────────────────────

Gradient _cardGradient(FuelCard card) {
  if (!card.isActive) {
    return const LinearGradient(
      colors: [Color(0xFF374151), Color(0xFF4B5563)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  return AppColors.fuelCardGradient;
}

class CardFrontFace extends StatelessWidget {
  const CardFrontFace({required this.card, super.key});
  final FuelCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: _cardGradient(card),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomPaint(size: const Size(36, 28), painter: ChipPainter()),
              _CardStatusBadge(status: card.status),
            ],
          ),
          const Spacer(),
          Text(
            '●●●● ●●●● ●●●● ${card.last4}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FUEL EASE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Expires ${card.expiresAt.month.toString().padLeft(2, '0')}/${card.expiresAt.year.toString().substring(2)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Back face ────────────────────────────────────────────────────────────────

class CardBackFace extends StatelessWidget {
  const CardBackFace({required this.card, super.key});
  final FuelCard card;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM/yy');
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: _cardGradient(card),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Magnetic stripe
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(color: Color(0xFF111827)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CVV',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(
                          card.cvv ?? '•••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('VALID THRU',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(card.expiresAt),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '●●●● ●●●● ●●●● ${card.last4}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flip card ────────────────────────────────────────────────────────────────

class FlipFuelCard extends StatefulWidget {
  const FlipFuelCard({required this.card, super.key});
  final FuelCard card;

  @override
  State<FlipFuelCard> createState() => _FlipFuelCardState();
}

class _FlipFuelCardState extends State<FlipFuelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFront = angle <= pi / 2;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? CardFrontFace(card: widget.card)
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: CardBackFace(card: widget.card),
                  ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/cards/presentation/widgets/flip_fuel_card.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/cards/presentation/widgets/flip_fuel_card.dart
git commit -m "feat: add FlipFuelCard widget with ChipPainter and card faces"
```

---

### Task 3: FuelCardItem Redesign

**Files:**
- Modify: `lib/features/cards/presentation/widgets/fuel_card_item.dart`

The current file has two problems: flat solid color background, and `maskedCardNumber` shown twice (lines 68–76 and 97–104). This task replaces the visual with `CardFrontFace` and removes the duplicate.

- [ ] **Step 1: Rewrite `fuel_card_item.dart`**

Replace the entire file content with:

```dart
import 'package:flutter/material.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/flip_fuel_card.dart';

class FuelCardItem extends StatelessWidget {
  const FuelCardItem({
    required this.card,
    this.onTap,
    super.key,
  });

  final FuelCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CardFrontFace(card: card),
      ),
    );
  }
}
```

Note: `_StatusBadge` from the old file is no longer needed here — it's now inside `flip_fuel_card.dart` as `_CardStatusBadge`. `_formatExpiryDate` is also no longer needed.

- [ ] **Step 2: Run analysis on modified file**

```bash
flutter analyze lib/features/cards/presentation/widgets/fuel_card_item.dart lib/features/cards/presentation/screens/cards_screen.dart
```

Expected: No issues. If `cards_screen.dart` still imports something removed, fix the import.

- [ ] **Step 3: Hot reload and visually confirm**

Start the app: `flutter run`
Navigate to Cards screen. Each card should now show the gradient `CardFrontFace` visual — blue gradient, EMV chip in top-left, status badge in top-right, card number with dots (`●●●● ●●●● ●●●● {last4}`), "FUEL EASE" label, expiry. No duplicate number.

- [ ] **Step 4: Commit**

```bash
git add lib/features/cards/presentation/widgets/fuel_card_item.dart
git commit -m "feat: redesign FuelCardItem with gradient CardFrontFace and fix duplicate card number"
```

---

### Task 4: Wallet Screen — Theme Fixes + Chips + Chart

**Files:**
- Modify: `lib/features/wallet/presentation/screens/wallet_screen.dart`

Changes:
1. Remove `backgroundColor: AppColors.midnight` from Scaffold
2. Change RefreshIndicator `backgroundColor` to `colorScheme.surface`
3. Update SliverAppBar to use `colorScheme.surface` background, `colorScheme.onSurface` text
4. Update all plain text colors (`Colors.white` → `colorScheme.onSurface`) except text inside the gradient `_BalanceCard` container
5. Replace "Active wallet" chip in `_BalanceCard` with two data chips (weekly spend + active cards)
6. Add `_SpendingChart` `SliverToBoxAdapter` between balance card and recent-transactions header

- [ ] **Step 1: Update imports at top of `wallet_screen.dart`**

The current imports are on lines 1–13. Replace with:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/spending_providers.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_detail_sheet.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';
```

- [ ] **Step 2: Fix Scaffold, RefreshIndicator, SliverAppBar**

In `build()` (line 26), change:

```dart
// OLD
return Scaffold(
  backgroundColor: AppColors.midnight,
  body: RefreshIndicator(
    color: AppColors.brand,
    backgroundColor: AppColors.surfaceDark,

// NEW
return Scaffold(
  body: RefreshIndicator(
    color: AppColors.brand,
    backgroundColor: Theme.of(context).colorScheme.surface,
```

In `_buildContent()`, update the `SliverAppBar` (lines 56–78):

```dart
SliverAppBar(
  pinned: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  surfaceTintColor: Colors.transparent,
  title: Text(
    'My Wallet',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
  ),
  actions: [
    IconButton(
      icon: Icon(
        Icons.history_rounded,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      onPressed: () => context.push(Routes.walletTransactions),
      tooltip: 'Transaction History',
    ),
  ],
),
```

- [ ] **Step 3: Update "Recent Transactions" header text colors**

In `_buildContent()`, around line 96:

```dart
// OLD
Text(
  'Recent Transactions',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white.withValues(alpha: 0.9),
  ),
),

// NEW
Text(
  'Recent Transactions',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  ),
),
```

- [ ] **Step 4: Update `_buildEmptyTransactions` and `_buildError` containers**

In `_buildEmptyTransactions` (around line 155):

```dart
// OLD
color: AppColors.surfaceElevatedDark,

// NEW
color: Theme.of(context).colorScheme.surfaceContainerHighest,
```

Change the icon and text colors from `Colors.white` to:

```dart
color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25), // icon
// text "No transactions yet":
style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
// subtext:
color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
```

Same pattern in `_buildError` for the error text colors (lines ~205–215).

- [ ] **Step 5: Update `_buildContent` to read providers and add spending chart section**

In `_buildContent`, add provider reads and pass to `_BalanceCard`:

```dart
Widget _buildContent(BuildContext context, WidgetRef ref, WalletSummary summary) {
  final wallet = summary.wallet;
  final recentTransactions = summary.recentTransactions ?? [];
  final weeklySpend = ref.watch(weeklySpendProvider);
  final activeCards = ref.watch(activeCardsCountProvider);
  final chartData = ref.watch(spendingChartDataProvider);

  return CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      // ... SliverAppBar (already updated above) ...

      // Gradient balance card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _BalanceCard(
            wallet: wallet,
            onTopUp: () => context.push(Routes.walletRecharge),
            weeklySpend: weeklySpend,
            activeCards: activeCards,
          ),
        ),
      ),

      // Spending chart
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _SpendingChart(data: chartData),
        ),
      ),

      // Recent transactions header
      // ... (existing, already theme-fixed above) ...
    ],
  );
}
```

- [ ] **Step 6: Update `_BalanceCard` to accept new params and render data chips**

Replace the `_BalanceCard` class (lines 230–317) with:

```dart
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.wallet,
    required this.onTopUp,
    required this.weeklySpend,
    required this.activeCards,
  });

  final Wallet wallet;
  final VoidCallback onTopUp;
  final int weeklySpend;
  final int activeCards;

  @override
  Widget build(BuildContext context) {
    final numberFmt = NumberFormat('#,##0');
    final compactFmt = NumberFormat.compact();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.brandGlow, blurRadius: 32, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: wallet.balanceTzs.toDouble(),
            formatter: (v) => 'TZS ${numberFmt.format(v.toInt())}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CardChip(icon: Icons.add_rounded, label: 'Top Up', onTap: onTopUp),
                const SizedBox(width: 8),
                _DataChip(
                  icon: Icons.trending_up_rounded,
                  label: 'TZS ${compactFmt.format(weeklySpend)}',
                  sublabel: 'this week',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _DataChip(
                  icon: Icons.credit_card_rounded,
                  label: '$activeCards active',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 350.ms);
  }
}
```

- [ ] **Step 7: Add `_DataChip` widget below `_CardChip`**

After the existing `_CardChip` class, add:

```dart
class _DataChip extends StatelessWidget {
  const _DataChip({
    required this.icon,
    required this.label,
    required this.color,
    this.sublabel,
  });

  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Add `_SpendingChart` widget at the bottom of `wallet_screen.dart`**

```dart
class _SpendingChart extends StatefulWidget {
  const _SpendingChart({required this.data});
  final Map<int, int> data;

  @override
  State<_SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<_SpendingChart> {
  bool _isDaily = true;

  List<BarChartGroupData> _buildGroups() {
    if (_isDaily) {
      return List.generate(30, (i) {
        final daysAgo = 29 - i; // i=0 is 29 days ago, i=29 is today
        final spend = (widget.data[daysAgo] ?? 0) / 1000.0;
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: spend,
              color: AppColors.primary,
              width: 5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        );
      });
    }
    // Weekly: 4 buckets, index 3 = most recent week
    return List.generate(4, (week) {
      var sum = 0;
      for (var d = week * 7; d < week * 7 + 7; d++) {
        sum += widget.data[d] ?? 0;
      }
      return BarChartGroupData(
        x: 3 - week, // x=3 is most recent week
        barRods: [
          BarChartRodData(
            toY: sum / 1000.0,
            color: AppColors.primary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = _buildGroups();
    final maxY = groups
        .map((g) => g.barRods.first.toY)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spending',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              Row(
                children: [
                  _ToggleChip(
                    label: 'Daily',
                    selected: _isDaily,
                    onTap: () => setState(() => _isDaily = true),
                  ),
                  const SizedBox(width: 6),
                  _ToggleChip(
                    label: 'Weekly',
                    selected: !_isDaily,
                    onTap: () => setState(() => _isDaily = false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 10 : maxY * 1.2,
                barGroups: groups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}K',
                        style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 9: Run analysis**

```bash
flutter analyze lib/features/wallet/presentation/screens/wallet_screen.dart
```

Expected: No issues. Fix any import errors.

- [ ] **Step 10: Hot reload and visually confirm**

1. Wallet screen scaffold background follows app theme
2. Balance card shows Top Up + weekly spend chip (e.g. "TZS 45K / this week") + active cards chip ("2 active")
3. Spending chart appears below balance card with Daily/Weekly toggle
4. Toggling Daily ↔ Weekly changes bar widths

- [ ] **Step 11: Commit**

```bash
git add lib/features/wallet/presentation/screens/wallet_screen.dart
git commit -m "feat: wallet screen theme fixes, spending chips, bar chart"
```

---

### Task 5: Cards Screen — Theme Fixes + FilterChip Rename

**Files:**
- Modify: `lib/features/cards/presentation/screens/cards_screen.dart`

- [ ] **Step 1: Remove hardcoded scaffold background and fix SliverAppBar**

Line 49: remove `backgroundColor: AppColors.midnight,` from the `Scaffold`.

Lines 54–65 (SliverAppBar):

```dart
SliverAppBar(
  pinned: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  surfaceTintColor: Colors.transparent,
  title: Text(
    'Fuel Cards',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
  ),
  // ... actions unchanged ...
),
```

- [ ] **Step 2: Fix empty state and error text colors**

In `_buildEmptyState` (lines ~225–268), change:
- Icon container: `AppColors.surfaceElevatedDark` → `Theme.of(context).colorScheme.surfaceContainerHighest`
- Icon color: `Colors.white.withValues(alpha: 0.06/0.25)` → `colorScheme.outline.withValues(alpha: 0.2)` / `colorScheme.onSurface.withValues(alpha: 0.25)`
- Text "No X cards": `Colors.white` → `colorScheme.onSurface`
- Subtext: `Colors.white.withValues(alpha: 0.4)` → `colorScheme.onSurface.withValues(alpha: 0.45)`

Same changes in `_buildError` (lines ~272–307).

- [ ] **Step 3: Rename `_DarkFilterChip` → `_FilterChip` and make it theme-aware**

Replace the entire `_DarkFilterChip` class (lines 312–362):

```dart
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = activeColor ?? AppColors.brand;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : cs.outline.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Update all `_DarkFilterChip` usages in `_buildContent` to `_FilterChip`**

Lines 141, 147, 154, 161 — change `_DarkFilterChip(` to `_FilterChip(` (4 occurrences).

- [ ] **Step 5: Run analysis**

```bash
flutter analyze lib/features/cards/presentation/screens/cards_screen.dart
```

Expected: No issues.

- [ ] **Step 6: Hot reload and visually confirm**

Cards screen background follows theme. Filter chips show correct theme colors in both light and dark mode.

- [ ] **Step 7: Commit**

```bash
git add lib/features/cards/presentation/screens/cards_screen.dart
git commit -m "feat: cards screen theme fixes and _FilterChip rename"
```

---

### Task 6: Card Details Screen — Theme Fixes + FlipFuelCard + Sessions + Timeline

**Files:**
- Modify: `lib/features/cards/presentation/screens/card_details_screen.dart`

- [ ] **Step 1: Update imports**

Replace the current imports (lines 1–9):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/card_sessions_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/flip_fuel_card.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
```

- [ ] **Step 2: Fix Scaffold and AppBar background**

In `build()`, update:

```dart
return Scaffold(
  // Remove: backgroundColor: AppColors.midnight,
  appBar: AppBar(
    title: const Text('Card Details'),
    elevation: 0,
    backgroundColor: Theme.of(context).colorScheme.surface,
    foregroundColor: Theme.of(context).colorScheme.onSurface,
  ),
  // ...
```

- [ ] **Step 3: Replace the static card container with `FlipFuelCard`**

First, update the `_buildContent` signature to use the concrete `FuelCard` type (line 39):

```dart
// OLD
Widget _buildContent(BuildContext context, WidgetRef ref, dynamic card) {
// NEW
Widget _buildContent(BuildContext context, WidgetRef ref, FuelCard card) {
```

Then replace the entire `Container(height: 220, ...)` block (lines 48–140) with:

```dart
FlipFuelCard(card: card),
```

Add a small hint text below it:

```dart
const SizedBox(height: 6),
Text(
  'Tap card to flip',
  style: TextStyle(
    fontSize: 11,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
  ),
  textAlign: TextAlign.center,
),
```

- [ ] **Step 4: Update `_InfoSection` and `_InfoRow` to use theme colors**

In `_InfoSection.build()`, replace:
- `AppColors.surfaceElevatedDark` → `Theme.of(context).colorScheme.surfaceContainerHighest`
- `AppColors.borderDark` → `Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)`
- `AppColors.textPrimaryDark` → `Theme.of(context).colorScheme.onSurface`

In `_InfoRow.build()`, replace:
- `AppColors.textSecondaryDark` → `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)`
- `AppColors.textPrimaryDark` → `Theme.of(context).colorScheme.onSurface`

- [ ] **Step 5: Update `_shareCard` bottom sheet colors**

In `_shareCard()`:
- `backgroundColor: AppColors.surfaceDark` → use the `context.colorScheme.surface`
- `AppColors.borderDark` drag handle → `colorScheme.outline.withValues(alpha: 0.3)`
- `AppColors.textSecondaryDark` in share-option subtitle → `colorScheme.onSurface.withValues(alpha: 0.55)`
- `_ShareOption` container: `AppColors.surfaceDark` → `colorScheme.surfaceContainerHighest`
- `AppColors.borderDark` border → `colorScheme.outline.withValues(alpha: 0.15)`
- Text colors: `AppColors.textPrimaryDark` → `colorScheme.onSurface`
- Chevron: `AppColors.textSecondaryDark` → `colorScheme.onSurface.withValues(alpha: 0.4)`

- [ ] **Step 6: Add sessions list section in `_buildContent`**

After the `_InfoSection` and before the cancel button, add:

```dart
const SizedBox(height: 24),
_SessionsSection(cardId: card.id),
```

Add the `_SessionsSection` widget to the file:

```dart
class _SessionsSection extends ConsumerWidget {
  const _SessionsSection({required this.cardId});
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(cardSessionsProvider(cardId));
    final pinsAsync = ref.watch(stationMapPinsProvider);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('MMM d, HH:mm');

    if (sessions.isEmpty) return const SizedBox.shrink();

    final stationNames = pinsAsync.whenOrNull(
          data: (pins) => {for (final p in pins) p.id: p.name},
        ) ??
        {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Sessions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
            itemBuilder: (context, i) {
              final session = sessions[i];
              final stationName = stationNames[session.stationId] ??
                  'Station …${session.stationId.substring(session.stationId.length - 8)}';
              final liters =
                  session.actualLiters ?? session.requestedLiters;
              final statusColor = session.isCompleted
                  ? AppColors.success
                  : session.isCancelled
                      ? cs.onSurface.withValues(alpha: 0.4)
                      : AppColors.warning;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_gas_station_rounded,
                          size: 18, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stationName,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            '${liters.toStringAsFixed(1)} L • ${dateFmt.format(session.createdAt)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        session.formattedStatus,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 7: Add status timeline stepper section in `_buildContent`**

After `_SessionsSection`, add:

```dart
const SizedBox(height: 24),
_StatusTimeline(card: card),
const SizedBox(height: 24),
```

Add the `_StatusTimeline` widget:

```dart
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.card});
  final FuelCard card;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('MMM d, yyyy');

    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Issued',
        date: dateFmt.format(card.createdAt),
        reached: true,
        isCurrent: card.status == 'pending',
        color: AppColors.primary,
      ),
      _TimelineStep(
        label: 'Active',
        date: null,
        reached: card.isActive || card.status == 'blocked' || card.isExpired,
        isCurrent: card.isActive,
        color: AppColors.success,
      ),
      if (card.status == 'blocked')
        _TimelineStep(
          label: 'Blocked',
          date: null,
          reached: true,
          isCurrent: true,
          color: AppColors.error,
        ),
      _TimelineStep(
        label: 'Expired',
        date: card.isExpired ? dateFmt.format(card.expiresAt) : null,
        reached: card.isExpired,
        isCurrent: card.isExpired && card.status != 'blocked',
        color: cs.onSurface.withValues(alpha: 0.4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Status',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface),
        ),
        const SizedBox(height: 16),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dot + vertical line
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.reached
                              ? step.color
                              : cs.outline.withValues(alpha: 0.3),
                          border: step.isCurrent
                              ? Border.all(
                                  color: step.color,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: step.isCurrent
                            ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: step.color,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1,
                            color: cs.outline.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: step.reached
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                      if (step.date != null)
                        Text(
                          step.date!,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.date,
    required this.reached,
    required this.isCurrent,
    required this.color,
  });

  final String label;
  final String? date;
  final bool reached;
  final bool isCurrent;
  final Color color;
}
```

- [ ] **Step 8: Run analysis**

```bash
flutter analyze lib/features/cards/presentation/screens/card_details_screen.dart
```

Expected: No issues. Fix any `dynamic` type warnings by using the proper `FuelCard` type throughout.

- [ ] **Step 9: Hot reload and visually confirm**

1. Navigate to any card in Cards screen → tap card to open Card Details
2. Top of screen shows `FlipFuelCard` — tap it → flip animation reveals back face with CVV (or `•••`)
3. Sessions list appears below action buttons (empty if no dispense history for this card)
4. Status timeline shows correct steps highlighted based on card status

- [ ] **Step 10: Commit**

```bash
git add lib/features/cards/presentation/screens/card_details_screen.dart
git commit -m "feat: card details theme fixes, FlipFuelCard, sessions list, status timeline"
```

---

### Final Check

- [ ] **Run full analysis**

```bash
flutter analyze lib/
```

Expected: No issues in any of the modified files.

- [ ] **Run all tests**

```bash
flutter test
```

Expected: All existing tests pass; new provider tests pass.
