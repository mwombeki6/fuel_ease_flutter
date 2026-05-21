# Wallet & Cards Screen Redesign

**Date:** 2026-05-21  
**Status:** Approved — ready for implementation  
**Scope:** `wallet_screen.dart`, `cards_screen.dart`, `fuel_card_item.dart`, `card_details_screen.dart`

---

## 1. Theme Fixes

Replace all hardcoded dark-mode colors across the four screens with `colorScheme`/`AppColors` tokens so the UI is correct in both light and dark themes.

**Targets:**

| Location | Hardcoded value | Replace with |
|---|---|---|
| `wallet_screen.dart` Scaffold | `AppColors.midnight` | removed (inherits theme scaffold bg) |
| `wallet_screen.dart` RefreshIndicator | `AppColors.surfaceDark` | `colorScheme.surface` |
| `cards_screen.dart` Scaffold | `AppColors.midnight` | removed |
| `_DarkFilterChip` background | `AppColors.surfaceDark` | `colorScheme.surfaceContainerHighest` |
| `_DarkFilterChip` text | hardcoded `Colors.white70` | `colorScheme.onSurface.withValues(alpha: 0.7)` |
| `card_details_screen.dart` all surfaces | `AppColors.midnight`, `AppColors.surfaceElevatedDark` | `colorScheme.surface`, `colorScheme.surfaceContainerHighest` |

Rename `_DarkFilterChip` → `_FilterChip` to reflect its now theme-aware nature.

---

## 2. Balance Card Chips

Two data chips appear below the balance figure inside `_BalanceCard`:

### Chip A — Weekly Spend Velocity
- Label: `TZS {amount}` (formatted as `NumberFormat.compact()`) + subtitle "this week"
- Icon: `Icons.trending_up_rounded` or `Icons.trending_down_rounded` based on whether this week > last week
- Color: amber (`AppColors.warning`) for up, green (`AppColors.success`) for down/flat
- Data source: **`weeklySpendProvider`** (new Riverpod `Provider<int>`) — watches `walletTransactionProvider`, sums `amountTzs` of `type == 'debit'` records whose `createdAt` is within the last 7 days

### Chip B — Active Cards Count
- Label: `{n} active` where n = cards with `status == 'active'`
- Icon: `Icons.credit_card_rounded`
- Color: brand blue (`AppColors.primary`)
- Data source: `ref.watch(cardsProvider)` filtered client-side — no new provider needed

Both chips sit in a `Row` with `MainAxisAlignment.start`, spaced by 8px. Each is a small `Container` with `borderRadius: 20`, brand-tinted background (`color.withValues(alpha: 0.12)`), and 6px vertical / 10px horizontal padding.

---

## 3. Spending Chart

A `fl_chart` `BarChart` showing fuel spend across the last 30 days, placed below `_BalanceCard` in `wallet_screen.dart`.

### Data
**`spendingChartProvider`** — new `Provider<List<BarChartGroupData>>` that:
1. Watches `walletTransactionProvider`
2. Filters to `type == 'debit'` records within the last 30 days
3. Groups by `createdAt.day`, summing `amountTzs`
4. Returns one `BarChartGroupData` per day (x = day index 0–29, y = total spend in TZS, scaled to thousands for axis readability)

### Toggle
A two-chip toggle (`Daily` / `Weekly`) in the section header row. Weekly mode re-buckets the same data into 4 weekly sums. Toggle state lives in the widget (no provider needed — ephemeral).

### Visual
- Bar color: `AppColors.primary` with `AppColors.primary.withValues(alpha: 0.2)` for the inactive (non-selected) bars
- No gridlines; left axis shows `K` suffix (e.g. `150K`)
- Section header: `"Spending"` left-aligned with the Daily/Weekly toggle chips right-aligned
- Section wrapped in `Card` with `colorScheme.surfaceContainerHighest` background, 16px padding, 12px border radius

---

## 4. Fuel Card Visual Redesign + Flip Animation

### `FuelCardItem` — visual

Replace the flat solid-color `Container` with a `fuelCardGradient` (`LinearGradient` from `AppColors.fuelCardGradient`: `#1D4ED8 → #2563EB → #0891B2`, angle 135°).

**Layout (front face):**
```
┌─────────────────────────────────────────┐
│ ● EMV Chip (32×24, gold gradient)    ↗  │  ← chip left, brand logo or initials right
│                                          │
│   ●●●● ●●●● ●●●● {last4}               │  ← embossed style: letter-spacing 3, white, w700
│                                          │
│ {companyName}          Expires {MM/YY}  │
└─────────────────────────────────────────┘
```

- **Bug fix:** Remove the duplicate masked number — currently appears at lines 68–76 and 97–104. Keep only the bottom-left embossed number.
- **EMV chip:** `CustomPaint` with a `ChipPainter` — rounded rect, gold gradient (`#D4AF37 → #F5D97F`), horizontal center line, two vertical lines. Size: 32×24.
- **Status badge:** top-right pill showing `active / blocked / expired / pending` in matching color (success/error/surfaceVariant/warning)

### Flip Animation

`FlipFuelCard` — a `StatefulWidget` wrapping `FuelCardItem`'s front and back:
- `AnimationController(duration: 500ms, vsync: this)`
- `CurvedAnimation(curve: Curves.easeInOut)`
- Tapping the card calls `controller.forward()` or `controller.reverse()`
- `Transform` uses `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle)` for perspective
- Front hides when `angle > π/2` (opacity 0); back appears
- **Back face layout:**
  ```
  ┌─────────────────────────────────────────┐
  │ ███████████████████████████████████████ │  ← magnetic stripe (dark band)
  │                                          │
  │  CVV: {cvv ?? "•••"}     Valid thru     │
  │                          {MM/YY}        │
  │                                          │
  │  {last4 partial PAN}                    │
  └─────────────────────────────────────────┘
  ```
- CVV shown only if `card.cvv != null` (server only returns CVV for newly issued cards)

The `FlipFuelCard` widget is used in both `FuelCardItem` and `card_details_screen.dart`.

---

## 5. Card Details Screen — Sessions + Timeline

### Theme fixes
Replace all `AppColors.midnight` / `AppColors.surfaceElevatedDark` / `AppColors.surfaceDark` with `colorScheme` equivalents (same table as Section 1 but specific to `card_details_screen.dart`).

### Card visual at top
Replace the current static card display with `FlipFuelCard` (from Section 4) — starts on front, tap to flip and reveal CVV.

### Dispense Sessions list (`cardSessionsProvider`)
New `Provider.family<List<DispenseRequest>, String>(cardId)`:
- Watches `dispenseProvider` (already fetches all requests for the user)
- Filters: `request.cardId == cardId`
- Sorts: most recent first

Displayed as a `ListView` section titled `"Fuel Sessions"` below the action buttons. Each row:
- Left: fuel pump icon in a small circle (color = session status color)
- Center: station name (look up `stationId` in `stationMapPinsProvider`; if not found, display `"Station …{last8chars}"` as fallback), liters dispensed (`actualLiters ?? requestedLiters`), date
- Right: status chip (`completed` green / `pending` amber / `cancelled` grey)

### Status Timeline Stepper
Appears below the sessions list, title `"Card Status History"`. Uses a vertical custom stepper (not Flutter's built-in `Stepper` — too heavy):
- Steps (always shown, greyed if not reached): `Issued → Active → (Blocked?) → Expired`
- Current status highlighted in brand blue with a filled circle
- Each step shows step label + date where available: `Issued` shows `card.createdAt`; `Active/Blocked/Expired` steps show no date (the `FuelCard` model has no `updatedAt` — do not fabricate dates)
- Connecting line between steps: 1px `colorScheme.outlineVariant`

If the card is `blocked`, insert a `Blocked` step between `Active` and `Expired` with a red circle.

---

## Implementation Notes

- `weeklySpendProvider` and `spendingChartProvider` can both be added to `lib/features/wallet/presentation/providers/` (new file) to avoid bloating `wallet_screen.dart`
- `cardSessionsProvider` lives in `lib/features/cards/presentation/providers/card_sessions_provider.dart`
- `FlipFuelCard` + `ChipPainter` go in `lib/features/cards/presentation/widgets/flip_fuel_card.dart`
- `fl_chart` is already in `pubspec.yaml` — no new dependency needed
- `fuelCardGradient` is already defined in `AppColors` — no new token needed

## Files to Create

| File | Purpose |
|------|---------|
| `lib/features/wallet/presentation/providers/spending_providers.dart` | `weeklySpendProvider` + `spendingChartProvider` |
| `lib/features/cards/presentation/providers/card_sessions_provider.dart` | `cardSessionsProvider` family |
| `lib/features/cards/presentation/widgets/flip_fuel_card.dart` | `FlipFuelCard` widget + `ChipPainter` |

## Files to Modify

| File | Changes |
|------|---------|
| `lib/features/wallet/presentation/screens/wallet_screen.dart` | Theme fixes; balance card chips; spending chart section |
| `lib/features/cards/presentation/screens/cards_screen.dart` | Theme fixes; `_DarkFilterChip` → `_FilterChip`; use `FlipFuelCard` in list |
| `lib/features/cards/presentation/widgets/fuel_card_item.dart` | Full visual redesign — gradient, EMV chip, fix duplicate number |
| `lib/features/cards/presentation/screens/card_details_screen.dart` | Theme fixes; `FlipFuelCard` at top; sessions list; status timeline |
