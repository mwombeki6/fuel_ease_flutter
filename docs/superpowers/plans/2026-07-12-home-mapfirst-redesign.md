# Home Map-First Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the "Pump & Go" visual identity (design tokens + theme) app-wide, rebuild the bottom navigation and Home screen around a full-screen map with a persistent draggable station sheet, and correct the fueling-flow copy to match what the backend actually does (pump-side PIN/QR confirmation, never an attendant).

**Architecture:** New color tokens live in `AppColors`/`AppTheme` and are consumed everywhere through `Theme.of(context).colorScheme` — no screen should reference a raw hardcoded `AppColors.<oldToken>` after this plan. Home becomes a `Column` of (header → conditional alert → `Expanded` map zone containing `_MapLayer` + floating search + a docked `StationSheet`) → nav bar, replacing the old single 1,310-line widget. Two new providers (`nearestOrSelectedStationProvider`, `pendingActionsProvider`) supply Home's dynamic data; everything else reuses existing providers/screens.

**Tech Stack:** Flutter 3, Riverpod 2 (`Provider`, `Provider.autoDispose`), `flutter_map ^7.0.2` + `flutter_map_marker_cluster ^1.3.1` (unchanged), `google_fonts` Sora (unchanged), Flutter SDK `DraggableScrollableSheet` (no new bottom-sheet package), `go_router` (unchanged), `flutter_test` + `mocktail` for provider tests (this codebase does not widget-test pure visual widgets — see `docs/superpowers/plans/2026-05-21-wallet-cards-redesign.md` precedent, which only unit-tests providers and verifies visual widgets via `flutter analyze`).

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-07-12-home-mapfirst-redesign-design.md` — every task below implements a section of it; read the relevant section before starting a task if anything here is ambiguous.
- **Color tokens (exact values), light:** `background #FAF8F4`, `surface #FFFFFF`, `surfaceMuted #F0EEE8`, `border #EDEAE1`, `textPrimary #211F1A`, `textSecondary #8A8578`, `evergreen #1F4D3A`, `brightGreen #3FAE5C`, `amber text #A3760F` / `amber surface #FDF2E3`, `errorDot #D9534F`, `mapCanvas #E9EDE2`, `mapRoad #D3DCC3`, `mapAreaFill #DFE4D5`, `mapLabel #8A9179`.
- **Color tokens (exact values), dark:** `backgroundDark #161513`, `surfaceDark #211F1C`, `surfaceMutedDark #2A2825`, `borderDark #3A3733`, `textPrimaryDark #F2F0EA`, `textSecondaryDark #A8A296`, `evergreenDark #2A5C46`, `brightGreenDark #4BC470`, `amberDark text #F0CB80` / `amberDark surface #332A17`, `errorDotDark #E8837E`, `mapCanvasDark #1C1A17`, `mapRoadDark #28261F`, `mapLabelDark #8F897C` (area) / `#C9C2AE` (road, higher contrast), `unavailableMarkerDark #4A463D`, `unavailableMarkerLight #B9B3A3`.
- **Kept tokens (repoint value only, no call-site changes needed anywhere):** `success #10B981`/`successDim`, `error #EF4444`/`errorDim`, `warning #F59E0B`/`warningDim`, `info #06B6D4`/`infoDim`, `fuelCardGradient` (unchanged, `#1D4ED8→#2563EB→#0891B2`), `successGradient` (unchanged), `shadow #40000000` (unchanged), `overlay #99000000` (unchanged), `scrim #CC000000` (unchanged), `premiumColor #8B5CF6` (unchanged — distinct fuel-type indicator, not part of brand identity). `petrolColor` repoints to `evergreen`, `dieselColor` repoints to `warning` — no call-site changes for either since they're referenced by name, not by old hex.
- **Removed tokens, zero call sites found (delete outright in Task 1, nothing to migrate):** `cardGradient`, `brandShadow`, `chartColors`, `statusActive`, `statusPending`, `statusError`.
- **Removed tokens WITH call sites (must be migrated per the mapping table below before deletion):** `brand`, `brandDark`, `brandLight`, `brandCyan`, `brandGlow`, `brandGradient`, `primary`, `primaryDark`, `primaryLight`, `primarySoft`, `primaryDarkMode`, `primarySoftDark`, `accent`, `midnight`, `navy`, `backgroundDark`, `surfaceDark`, `surfaceElevatedDark`, `surfaceVariantDark`, `border`, `borderDark`, `borderStrong`, `borderSubtleDark`, `background`, `surface`, `surfaceVariant`, `surfaceStrong`, `textPrimary`, `textSecondary`, `textTertiary`, `textDisabled`, `textPrimaryDark`, `textSecondaryDark`, `textTertiaryDark`, `statusInactive`, `nightGradient`.
- **The migration mapping table** (used by Tasks 13, 14, 15, 16, 17, 18 — apply mechanically, same old token always maps to the same new expression):

  | Old `AppColors.<token>` | Replace with |
  |---|---|
  | `brand`, `brandDark`, `brandLight`, `primary`, `primaryDark`, `primaryLight`, `primaryDarkMode` | `Theme.of(context).colorScheme.primary` |
  | `primarySoft`, `primarySoftDark` | `Theme.of(context).colorScheme.primaryContainer` |
  | `brandCyan`, `accent` | `Theme.of(context).colorScheme.secondary` |
  | `brandGlow` | `Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)` |
  | `brandGradient` | `AppColors.brandGradient` (kept — redefined in Task 1 as `evergreen → brightGreen`, still a plain static gradient, no call-site logic change) |
  | `midnight`, `navy`, `backgroundDark` | If it's a bare `Scaffold`/`Container` background color: **remove the property entirely** so it inherits the theme default. If it's an explicit surface that needs a color: `Theme.of(context).colorScheme.surface` |
  | `surfaceDark`, `surface`, `background` | `Theme.of(context).colorScheme.surface` |
  | `surfaceElevatedDark`, `surfaceVariantDark`, `surfaceVariant`, `surfaceStrong` | `Theme.of(context).colorScheme.surfaceContainerHighest` |
  | `border`, `borderDark`, `borderSubtleDark` | `Theme.of(context).colorScheme.outlineVariant` |
  | `borderStrong` | `Theme.of(context).colorScheme.outline` |
  | `textPrimary`, `textPrimaryDark` | `Theme.of(context).colorScheme.onSurface` |
  | `textSecondary`, `textSecondaryDark` | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)` |
  | `textTertiary`, `textTertiaryDark` | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)` |
  | `textDisabled` | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
  | `statusInactive` | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)` |
  | `nightGradient` | Remove the gradient decoration; use a flat `Theme.of(context).colorScheme.surface` background instead (matches the approved direction's "avoid heavy gradients") |

- **Migration procedure, identical for every migration task (13-18):** for each file, (1) add `final colorScheme = Theme.of(context).colorScheme;` near the top of each `build()` method that doesn't already have an equivalent local, (2) replace every `AppColors.<oldToken>` occurrence using the table above, (3) if the file no longer references `AppColors` at all afterward (check for any *kept* token from the Global Constraints list first — `success`/`error`/`warning`/`info`/etc. usage is common and means the import stays), remove the now-unused `import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';`, (4) run `flutter analyze <file>`, expect no issues, (5) commit.
- **Fueling copy (Section 7 of the spec), exact strings:** station-sheet button `Start fueling`; code-generation action `Generate fuel code`; once the code exists `Enter this PIN at the pump, or let the pump scan the QR code`; waiting state `Waiting for pump confirmation`. Never the word "scan" from the customer's perspective, never "attendant"/"staff".
- **This codebase's test convention:** provider/logic files get real `flutter_test` unit tests with `ProviderContainer` overrides (see `test/features/wallet/presentation/providers/spending_providers_test.dart` for the exact pattern). Pure visual widgets and screens are verified with `flutter analyze` only, no widget tests — this matches every task in the precedent plan and this plan follows the same convention.

---

### Task 1: `AppColors` — Add Pump & Go Tokens, Prune Dead Tokens

**Files:**
- Modify: `lib/shared/theme/app_colors.dart`

**Interfaces:**
- Produces: every token named in Global Constraints' "Color tokens" and "Kept tokens" lists, available as `AppColors.<name>` static `Color`/`Gradient` constants. Task 2 and every widget task below consume these by name.

- [ ] **Step 1: Read the current file**

Read `lib/shared/theme/app_colors.dart` in full so the edit preserves its exact existing structure (class declaration, doc comments, ordering) — only the content changes below.

- [ ] **Step 2: Replace the file contents**

Rewrite `lib/shared/theme/app_colors.dart` to:

```dart
import 'package:flutter/material.dart';

/// Pump & Go — FuelEase mobile app color tokens.
class AppColors {
  AppColors._();

  // ── Light theme ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0EEE8);
  static const Color border = Color(0xFFEDEAE1);
  static const Color textPrimary = Color(0xFF211F1A);
  static const Color textSecondary = Color(0xFF8A8578);
  static const Color evergreen = Color(0xFF1F4D3A);
  static const Color brightGreen = Color(0xFF3FAE5C);
  static const Color amberText = Color(0xFFA3760F);
  static const Color amberSurface = Color(0xFFFDF2E3);
  static const Color errorDot = Color(0xFFD9534F);
  static const Color mapCanvas = Color(0xFFE9EDE2);
  static const Color mapRoad = Color(0xFFD3DCC3);
  static const Color mapAreaFill = Color(0xFFDFE4D5);
  static const Color mapLabel = Color(0xFF8A9179);
  static const Color unavailableMarkerLight = Color(0xFFB9B3A3);

  // ── Dark theme ───────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF161513);
  static const Color surfaceDark = Color(0xFF211F1C);
  static const Color surfaceMutedDark = Color(0xFF2A2825);
  static const Color borderDark = Color(0xFF3A3733);
  static const Color textPrimaryDark = Color(0xFFF2F0EA);
  static const Color textSecondaryDark = Color(0xFFA8A296);
  static const Color evergreenDark = Color(0xFF2A5C46);
  static const Color brightGreenDark = Color(0xFF4BC470);
  static const Color amberTextDark = Color(0xFFF0CB80);
  static const Color amberSurfaceDark = Color(0xFF332A17);
  static const Color errorDotDark = Color(0xFFE8837E);
  static const Color mapCanvasDark = Color(0xFF1C1A17);
  static const Color mapRoadDark = Color(0xFF28261F);
  static const Color mapLabelDark = Color(0xFF8F897C);
  static const Color mapRoadLabelDark = Color(0xFFC9C2AE);
  static const Color unavailableMarkerDark = Color(0xFF4A463D);

  // ── Semantic (kept, repointed) ──────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successDim = Color(0xFF047857);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDim = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDim = Color(0xFFB45309);
  static const Color info = Color(0xFF06B6D4);
  static const Color infoDim = Color(0xFF0E7490);

  // ── Fuel type (kept, repointed) ─────────────────────────────────────────
  static const Color petrolColor = evergreen;
  static const Color dieselColor = warning;
  static const Color premiumColor = Color(0xFF8B5CF6);

  // ── Neutral overlays (kept, unchanged) ──────────────────────────────────
  static const Color shadow = Color(0x40000000);
  static const Color overlay = Color(0x99000000);
  static const Color scrim = Color(0xCC000000);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [evergreen, brightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient fuelCardGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0891B2)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

- [ ] **Step 3: Verify no analysis errors in this file**

```bash
flutter analyze lib/shared/theme/app_colors.dart
```

Expected: No issues found. (Other files will show errors referencing removed tokens like `AppColors.brand` — that's expected and resolved by Tasks 2-18; ignore those for this step, only this file must be clean.)

- [ ] **Step 4: Commit**

```bash
git add lib/shared/theme/app_colors.dart
git commit -m "feat: replace AppColors with Pump & Go token set"
```

---

### Task 2: `AppTheme` — Repoint ColorScheme and Component Themes

**Files:**
- Modify: `lib/shared/theme/app_theme.dart`

**Interfaces:**
- Consumes: every `AppColors` token from Task 1.
- Produces: `Theme.of(context).colorScheme.{primary, secondary, primaryContainer, surface, surfaceContainerHighest, outline, outlineVariant, onSurface, error}` resolving to the new palette in both `AppTheme.lightTheme` and `AppTheme.darkTheme` — every migration task (3, 13-18) and every new widget task (6-11) depends on this.

- [ ] **Step 1: Read the current file in full**

Read `lib/shared/theme/app_theme.dart` end to end — this file defines `AppTheme.lightTheme`/`darkTheme` via a private `_build(Brightness)` that constructs `ColorScheme.light(...)`/`ColorScheme.dark(...)` manually from `AppColors` fields, wires `textTheme` from `AppTextStyles`, and defines component themes (`appBarTheme`, `cardTheme`, `inputDecorationTheme`, button themes, `floatingActionButtonTheme`, `bottomSheetTheme`, `dialogTheme`, `snackBarTheme`, `chipTheme`, `dividerTheme`, `iconTheme`, `listTileTheme`, `progressIndicatorTheme`, `radioTheme`, `checkboxTheme`, `switchTheme`, `navigationBarTheme`, `tabBarTheme`). Do not restructure this shape — only change the values below.

- [ ] **Step 2: Repoint every `ColorScheme` field to the new tokens**

Apply this exact field mapping inside `ColorScheme.light(...)`:

```dart
ColorScheme.light(
  primary: AppColors.evergreen,
  onPrimary: Colors.white,
  primaryContainer: AppColors.surfaceMuted,
  onPrimaryContainer: AppColors.evergreen,
  secondary: AppColors.brightGreen,
  onSecondary: Colors.white,
  surface: AppColors.background,
  onSurface: AppColors.textPrimary,
  surfaceContainerHighest: AppColors.surface,
  onSurfaceVariant: AppColors.textSecondary,
  outline: AppColors.border,
  outlineVariant: AppColors.border,
  error: AppColors.error,
  onError: Colors.white,
  errorContainer: AppColors.errorDim,
)
```

And inside `ColorScheme.dark(...)`:

```dart
ColorScheme.dark(
  primary: AppColors.brightGreenDark,
  onPrimary: Color(0xFF0D1F14),
  primaryContainer: AppColors.surfaceMutedDark,
  onPrimaryContainer: AppColors.brightGreenDark,
  secondary: AppColors.evergreenDark,
  onSecondary: Colors.white,
  surface: AppColors.backgroundDark,
  onSurface: AppColors.textPrimaryDark,
  surfaceContainerHighest: AppColors.surfaceDark,
  onSurfaceVariant: AppColors.textSecondaryDark,
  outline: AppColors.borderDark,
  outlineVariant: AppColors.borderDark,
  error: AppColors.error,
  onError: Colors.white,
  errorContainer: AppColors.errorDim,
)
```

Keep every other named parameter that already exists on those constructors (e.g. `brightness:`) — only change the ones listed above. If the current file passes additional fields not listed here (e.g. `tertiary`), leave them as they are unless they reference a token Task 1 removed, in which case point them at `primary`/`secondary` per the closest semantic fit.

- [ ] **Step 3: Update component-theme radii and shapes**

Apply these radius changes wherever the corresponding component theme currently sets a `BorderRadius`/`RoundedRectangleBorder` radius, per the spec's Section 3-4 requirements:

- `inputDecorationTheme`: border radius `14` → `16` (matches the 48px-tall search field treatment)
- `filledButtonTheme`/`elevatedButtonTheme`/`outlinedButtonTheme`: radius stays `14` (already matches the Directions/Start fueling button treatment) — no change needed unless the current value differs from 14, in which case set it to `14`
- `bottomSheetTheme`: top radius `24` → `26` (matches the station sheet), keep `showDragHandle: true`
- `cardTheme`: radius `16` → `16` (unchanged — already matches)

- [ ] **Step 4: Verify no analysis errors**

```bash
flutter analyze lib/shared/theme/app_theme.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/theme/app_theme.dart
git commit -m "feat: repoint ColorScheme and component radii to Pump & Go tokens"
```

---

### Task 3: Shared Widgets — Migrate `fe_widgets.dart`, Delete Dead Dashboard Widgets

**Files:**
- Modify: `lib/shared/widgets/fe_widgets.dart`
- Delete: `lib/features/dashboard/presentation/widgets/quick_action_button.dart`
- Delete: `lib/features/dashboard/presentation/widgets/quick_stat_card.dart`

**Interfaces:**
- Consumes: `Theme.of(context).colorScheme` (Task 2), migration mapping table (Global Constraints).

- [ ] **Step 1: Confirm the two dashboard widgets are genuinely unused**

```bash
grep -rn "QuickActionButton\|QuickStatCard" lib/ --include="*.dart"
```

Expected: only the two files' own definitions match (no import or usage elsewhere — confirmed during spec/plan research; re-verify here in case something changed). If any real usage now exists, stop and treat this as a blocker — do not delete a widget that's in use.

- [ ] **Step 2: Delete the two dead files**

```bash
git rm lib/features/dashboard/presentation/widgets/quick_action_button.dart
git rm lib/features/dashboard/presentation/widgets/quick_stat_card.dart
```

- [ ] **Step 3: Migrate `fe_widgets.dart`**

This file references `AppColors.brandGlow`, `.brandGradient`, `.primary`, `.shadow` (kept, no change), `.surface`, `.surfaceElevatedDark`, `.surfaceVariant`, `.surfaceVariantDark`, `.textDisabled`. Apply the migration procedure from Global Constraints: add `final colorScheme = Theme.of(context).colorScheme;` in each relevant `build()`, replace every occurrence per the mapping table (`AppColors.shadow` stays as-is, it's a kept token), remove the `AppColors` import only if no kept-token usage remains after migration (check for `shadow` first — it likely stays, so the import likely stays too).

- [ ] **Step 4: Verify no analysis errors**

```bash
flutter analyze lib/shared/widgets/fe_widgets.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/fe_widgets.dart
git commit -m "refactor: migrate fe_widgets.dart to colorScheme, delete dead dashboard widgets"
```

---

### Task 4: `nearestOrSelectedStationProvider`

**Files:**
- Create: `lib/features/dashboard/presentation/providers/nearest_station_provider.dart`
- Create: `test/features/dashboard/presentation/providers/nearest_station_provider_test.dart`

**Interfaces:**
- Consumes: `stationMapPinsProvider` (existing, `lib/features/stations/presentation/providers/station_map_provider.dart`, `FutureProvider.autoDispose<List<StationMapPin>>`); `StationMapPin` fields `id`, `name`, `lat`, `lng`, `status`, `region`, `district`, `activePumps`, `hasSuspension` (existing, `lib/features/stations/data/models/station_map_pin.dart`).
- Produces: `nearestOrSelectedStationProvider` — `StateProvider<String?>` holding the user-selected station ID (null = none selected), and `nearestOrSelectedStationValueProvider` — `Provider.autoDispose<StationMapPin?>` resolving to the selected pin if set, else the nearest pin by distance from a given user location. Task 11 (Home rebuild) and Task 7 (station sheet) consume `nearestOrSelectedStationValueProvider`; the map's pin-tap handler writes to `nearestOrSelectedStationProvider`.

- [ ] **Step 1: Write the failing test**

Create `test/features/dashboard/presentation/providers/nearest_station_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/nearest_station_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';

StationMapPin _pin(String id, double lat, double lng) => StationMapPin(
      id: id,
      name: 'Station $id',
      lat: lat,
      lng: lng,
      status: 'active',
      region: 'Dar es Salaam',
      district: 'Kinondoni',
      activePumps: 4,
      hasSuspension: false,
    );

void main() {
  final userLocation = const LatLng(-6.7924, 39.2083);
  final near = _pin('near', -6.7930, 39.2090); // ~0.1km away
  final far = _pin('far', -6.9000, 39.3000); // ~15km away

  test('resolves to the nearest pin when nothing is selected', () {
    final container = ProviderContainer(
      overrides: [
        stationMapPinsProvider.overrideWith((ref) async => [far, near]),
        userLocationProvider.overrideWithValue(userLocation),
      ],
    );
    addTearDown(container.dispose);

    final result = container.read(nearestOrSelectedStationValueProvider);
    expect(result?.id, 'near');
  });

  test('resolves to the selected pin even if a nearer one exists', () {
    final container = ProviderContainer(
      overrides: [
        stationMapPinsProvider.overrideWith((ref) async => [far, near]),
        userLocationProvider.overrideWithValue(userLocation),
      ],
    );
    addTearDown(container.dispose);

    container.read(nearestOrSelectedStationProvider.notifier).state = 'far';

    final result = container.read(nearestOrSelectedStationValueProvider);
    expect(result?.id, 'far');
  });

  test('returns null when the station list has not loaded yet', () {
    final container = ProviderContainer(
      overrides: [
        stationMapPinsProvider.overrideWith(
          (ref) => Completer<List<StationMapPin>>().future,
        ),
        userLocationProvider.overrideWithValue(userLocation),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(nearestOrSelectedStationValueProvider), isNull);
  });
}
```

Add the `dart:async` import for `Completer` at the top of the test file.

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/features/dashboard/presentation/providers/nearest_station_provider_test.dart
```

Expected: FAIL — `nearest_station_provider.dart` does not exist yet, and `userLocationProvider` is referenced but undefined.

- [ ] **Step 3: Locate the existing distance-math logic to extract**

```bash
grep -n "_metersTo\|_distanceLabel\|userLocationProvider\|LocationFab\|geolocator" lib/features/dashboard/presentation/screens/home_screen.dart
```

Read the matched sections of `home_screen.dart` — the current file already computes the user's location (via `geolocator`) and a `_metersTo(a, b)`/`_distanceLabel(meters)` pair using `latlong2`'s `Distance`. Find whichever provider or local state currently exposes the resolved `LatLng` user location (it may be a local `State` field rather than a `Provider` today).

- [ ] **Step 4: Implement `nearest_station_provider.dart`**

Create `lib/features/dashboard/presentation/providers/nearest_station_provider.dart`. If Step 3 found the user's location only as local widget state (not a provider), add a minimal `userLocationProvider` here too (a `StateProvider<LatLng?>` that `_MapLayer`/the location-permission flow sets once resolved — do not build new permission-request logic, only a place to store the already-resolved value):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';

/// Resolved user location, set once geolocation succeeds. Null until then
/// or if permission was denied — consumers must handle the null case.
final userLocationProvider = StateProvider<LatLng?>((ref) => null);

/// Station ID the user explicitly tapped on the map this session.
/// Null means "no explicit selection — fall back to nearest."
final nearestOrSelectedStationProvider = StateProvider<String?>((ref) => null);

double _metersBetween(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Meter, a, b);

/// The station the Home station sheet should display: the user's tapped
/// pin if one is selected, otherwise the nearest pin to their location.
final nearestOrSelectedStationValueProvider =
    Provider.autoDispose<StationMapPin?>((ref) {
  final pinsAsync = ref.watch(stationMapPinsProvider);
  final pins = pinsAsync.valueOrNull;
  if (pins == null || pins.isEmpty) return null;

  final selectedId = ref.watch(nearestOrSelectedStationProvider);
  if (selectedId != null) {
    for (final pin in pins) {
      if (pin.id == selectedId) return pin;
    }
  }

  final userLocation = ref.watch(userLocationProvider);
  if (userLocation == null) return pins.first;

  StationMapPin? nearest;
  double? nearestDistance;
  for (final pin in pins) {
    final distance = _metersBetween(userLocation, LatLng(pin.lat, pin.lng));
    if (nearestDistance == null || distance < nearestDistance) {
      nearest = pin;
      nearestDistance = distance;
    }
  }
  return nearest;
});
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
flutter test test/features/dashboard/presentation/providers/nearest_station_provider_test.dart
```

Expected: PASS — 3/3 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/dashboard/presentation/providers/nearest_station_provider.dart test/features/dashboard/presentation/providers/nearest_station_provider_test.dart
git commit -m "feat: add nearestOrSelectedStationProvider"
```

---

### Task 5: `pendingActionsProvider`

**Files:**
- Create: `lib/features/dashboard/presentation/providers/pending_actions_provider.dart`
- Create: `test/features/dashboard/presentation/providers/pending_actions_provider_test.dart`

**Interfaces:**
- Consumes: whatever provider currently exposes the user's active `FuelSession`(s) — locate it in Step 1 below (do not assume a name).
- Produces: `PendingAction` (a small model: `{String label, String route}`), `pendingActionsProvider` — `Provider.autoDispose<PendingAction?>`. Task 11 (Home rebuild) watches this to show/hide the alert banner.

- [ ] **Step 1: Locate the active-dispense-session signal**

```bash
grep -rn "FuelSession\|dispenseProvider\|isActive" lib/features/wallet/data/models/fuel_session.dart lib/features/dispense/presentation/providers/
```

Read the matched files. Confirm: (a) the exact provider that exposes the current user's in-progress `FuelSession`(s), (b) the exact station-name field available on it or on the linked dispense request (needed for the `"Fueling in progress at {stationName}"` label from the spec).

**If a provider exposing "PIN generated, not yet validated by the pump" (the backend's `pending` `DispensingRequest.Status`, distinct from `active`) is also found in this step, implement both branches below. If not found — the Flutter-side `FuelSession.status` getters (`isActive`/`isCompleted`/`isExpired`) may not expose this distinction yet — implement only the `isActive` branch and add a `// TODO(pending-confirmation-state): wire once the app exposes the backend's "pending" DispensingRequest status — see docs/superpowers/specs/2026-07-12-home-mapfirst-redesign-design.md Known Gaps` comment at the relevant spot. Do not fabricate a status check against a field that doesn't exist.**

- [ ] **Step 2: Write the failing test**

Create `test/features/dashboard/presentation/providers/pending_actions_provider_test.dart` (adjust the override target to match whatever provider Step 1 actually found — replace `activeFuelSessionsProvider` below with the real name):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/pending_actions_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/fuel_session.dart';

void main() {
  test('returns a fueling-in-progress action when a session is active', () {
    final session = FuelSession(
      id: 's1',
      dispenseReqId: 'r1',
      deviceId: 'd1',
      startedAt: DateTime.now(),
      litersDispensed: 3.2,
      status: 'active',
      stationName: 'Mwenge Fuel Point',
    );

    final container = ProviderContainer(
      overrides: [
        activeFuelSessionsProvider.overrideWith((ref) async => [session]),
      ],
    );
    addTearDown(container.dispose);

    final action = container.read(pendingActionsProvider);
    expect(action?.label, 'Fueling in progress at Mwenge Fuel Point');
  });

  test('returns null when there are no active sessions', () {
    final container = ProviderContainer(
      overrides: [
        activeFuelSessionsProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(pendingActionsProvider), isNull);
  });
}
```

Note: this test file's imports/overrides must be corrected to match the real provider name and `FuelSession` constructor found in Step 1 — the names above are illustrative of the *shape* of the test, not guaranteed exact.

- [ ] **Step 3: Run the test to verify it fails**

```bash
flutter test test/features/dashboard/presentation/providers/pending_actions_provider_test.dart
```

Expected: FAIL — `pending_actions_provider.dart` does not exist yet.

- [ ] **Step 4: Implement `pending_actions_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingAction {
  const PendingAction({required this.label, required this.route});
  final String label;
  final String route;
}

final pendingActionsProvider = Provider.autoDispose<PendingAction?>((ref) {
  // Replace `activeFuelSessionsProvider` below with the real provider found
  // in Task 5 Step 1, and adjust the field access to match its actual
  // FuelSession/station-name shape.
  final sessionsAsync = ref.watch(activeFuelSessionsProvider);
  final sessions = sessionsAsync.valueOrNull;
  if (sessions != null && sessions.isNotEmpty) {
    final session = sessions.first;
    return PendingAction(
      label: 'Fueling in progress at ${session.stationName}',
      route: '/fuel/live/${session.dispenseReqId}',
    );
  }

  // See Task 5 Step 1: only wire a "Waiting for pump confirmation" branch
  // here once a real backend-`pending`-status signal is confirmed to exist
  // on the Flutter side. Do not add it speculatively.

  return null;
});
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
flutter test test/features/dashboard/presentation/providers/pending_actions_provider_test.dart
```

Expected: PASS — 2/2 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/dashboard/presentation/providers/pending_actions_provider.dart test/features/dashboard/presentation/providers/pending_actions_provider_test.dart
git commit -m "feat: add pendingActionsProvider (active-dispense-session banner)"
```

---

### Task 6: `HeaderWalletChip` Widget

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/header_wallet_chip.dart`

**Interfaces:**
- Consumes: `availableBalanceProvider` (existing, `Provider<double?>`, `lib/features/wallet/presentation/providers/wallet_provider.dart`), `Routes.wallet` (existing, `lib/core/routing/routes.dart`).
- Produces: `HeaderWalletChip` — a `ConsumerWidget`, no constructor parameters. Task 11 (Home rebuild) places it in the header row.

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';

class HeaderWalletChip extends ConsumerWidget {
  const HeaderWalletChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = ref.watch(availableBalanceProvider);
    final formatted = balance == null
        ? '—'
        : NumberFormat.decimalPattern('en_US').format(balance.round());

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(Routes.wallet),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          'TZS $formatted',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
```

Add `import 'dart:ui';` at the top for `FontFeature` if `package:flutter/material.dart` does not already re-export it in this SDK version — check by running analyze in Step 2 first; add the import only if analyze flags `FontFeature` as undefined.

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/dashboard/presentation/widgets/header_wallet_chip.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/header_wallet_chip.dart
git commit -m "feat: add HeaderWalletChip widget"
```

---

### Task 7: `StationSheet` Widget — Two States

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/station_sheet.dart`

**Interfaces:**
- Consumes: `StationMapPin` (existing model, Task 4), `nearestOrSelectedStationValueProvider` (Task 4), `Routes.createDispensingRequest` (existing).
- Produces: `StationSheet` — a `ConsumerWidget`, no constructor parameters (reads the station internally via the provider). Task 11 (Home rebuild) places it docked at the bottom of the map zone.

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/nearest_station_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';

bool _isOpen(StationMapPin pin) => pin.status == 'active' && !pin.hasSuspension;

class StationSheet extends ConsumerStatefulWidget {
  const StationSheet({super.key});

  @override
  ConsumerState<StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends ConsumerState<StationSheet> {
  final _controller = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final station = ref.watch(nearestOrSelectedStationValueProvider);
    if (station == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.22,
      minChildSize: 0.22,
      maxChildSize: 0.6,
      snap: true,
      snapSizes: const [0.22, 0.6],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    station.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _isOpen(station) ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isOpen(station)
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${station.region} · ${station.district}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${station.activePumps} pumps available',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {}, // TODO(directions): wire to a maps deep-link once specced
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => context.push(
                        Routes.createDispensingRequest,
                        extra: station.id,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Start fueling'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Confirm `Routes.createDispensingRequest` accepts a station-id `extra`**

```bash
grep -n "createDispensingRequest" lib/core/routing/app_router.dart lib/features/dispense/presentation/screens/create_dispense_screen.dart
```

If `CreateDispenseScreen` does not yet read a `preselectedStationId` from `extra`, note this as a dependency on Task 12 (which adds it) — `StationSheet`'s `Start fueling` button already passes `extra: station.id` per the spec regardless of whether Task 12 has landed yet; the two tasks are safe to do in either order since this widget only calls `context.push`, it doesn't require `CreateDispenseScreen` to exist in a finished state to compile.

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/features/dashboard/presentation/widgets/station_sheet.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/station_sheet.dart
git commit -m "feat: add StationSheet widget (collapsed/expanded states)"
```

---

### Task 8: Bottom Navigation Shell Rebuild

**Files:**
- Modify: `lib/core/navigation/main_navigation.dart`

**Interfaces:**
- Consumes: `Theme.of(context).colorScheme` (Task 2), `GoRouterState`/`context.push` (existing `go_router` usage).
- Produces: a 5-item docked nav bar (`Home · Stations · Pay · Activity · Cards`) with no floating FAB — Task 9 (routing) wires which route each tab activates.

- [ ] **Step 1: Read the current file in full**

Read `lib/core/navigation/main_navigation.dart` — note the existing `_FeNavBar`/`_NavItem`/`_CenterFuelButton` structure and how `MainNavigation` receives its `child` from the `ShellRoute` builder, so the replacement preserves that outer contract (`MainNavigation({required Widget child})` → `Scaffold(extendBody: true, body: Stack([child, ..., _FeNavBar]))`).

- [ ] **Step 2: Replace `_FeNavBar` and remove `_CenterFuelButton`**

Replace the nav bar portion of the file with:

```dart
class _FeNavBar extends StatelessWidget {
  const _FeNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex; // 0=Home,1=Stations,2=(unused, Pay is not a tab),3=Activity,4=Cards
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.location_on_rounded,
              label: 'Stations',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _PayNavItem(onTap: () => onTap(2)),
            _NavItem(
              icon: Icons.schedule_rounded,
              label: 'Activity',
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.credit_card_rounded,
              label: 'Cards',
              active: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: active
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayNavItem extends StatelessWidget {
  const _PayNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                'Pay',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Delete `_CenterFuelButton` and any code in the enclosing `MainNavigation`/`_FeNavBar` build path that positioned it as a raised overlay — the nav bar is now one flat `Row`, no `Stack`-based floating element.

- [ ] **Step 3: Wire `MainNavigation` to compute `currentIndex` and handle taps**

In `MainNavigation`'s build method, compute which of the 4 real tabs (Home/Stations/Activity/Cards — Pay is index 2 but never "active") is current from the shell's route, and handle taps: indices 0/1/3/4 call `context.go(...)` to the corresponding tab route (Task 9 defines the exact paths), index 2 (Pay) calls `context.push(Routes.createDispensingRequest)` without changing the shell's active tab. Keep the existing pattern this file already uses for shell-aware navigation (e.g. `GoRouterState.of(context).uri` or the location the `ShellRoute` builder already exposes) — read how the current 4-tab version does this before replacing it, and preserve that mechanism rather than introducing a new one.

- [ ] **Step 4: Verify no analysis errors**

```bash
flutter analyze lib/core/navigation/main_navigation.dart
```

Expected: No issues found (route constants referenced here are finalized in Task 9 — if `Routes.activity`-equivalent doesn't exist yet at this point, this task may need to land after or together with Task 9; sequence them adjacently).

- [ ] **Step 5: Commit**

```bash
git add lib/core/navigation/main_navigation.dart
git commit -m "feat: rebuild bottom nav as single docked 5-item bar, remove floating FAB"
```

---

### Task 9: Routing — Shell Tab Wiring

**Files:**
- Modify: `lib/core/routing/app_router.dart`

**Interfaces:**
- Consumes: `Routes.home`, `Routes.stations`, `Routes.walletTransactions`, `Routes.cards`, `Routes.createDispensingRequest` (all existing, `lib/core/routing/routes.dart` — no new route constants needed).

- [ ] **Step 1: Read the current `ShellRoute` registration**

```bash
grep -n "ShellRoute\|Routes.home\|Routes.cards\|Routes.wallet\|Routes.profile" lib/core/routing/app_router.dart
```

Read the matched section in full.

- [ ] **Step 2: Update the shell's tab set**

Change the `ShellRoute`'s child routes from `{home, cards, wallet, profile}` to `{home, stations, walletTransactions, cards}` (4 real tabs; Pay is not a shell tab per Task 8):

- `Routes.home` → `HomeScreen` (unchanged registration, screen itself rebuilt in Task 11)
- `Routes.stations` → `StationsScreen` (existing, add to the shell if not already present — check first, it's currently registered outside the shell per prior research)
- `Routes.walletTransactions` → `TransactionHistoryScreen` (existing, move inside the shell if not already there — this is the Activity tab's destination, no new screen)
- `Routes.cards` → `CardsScreen` (unchanged registration)

Remove `Routes.wallet` and `Routes.profile` from the shell's tab set (they remain valid standalone routes reachable via `context.push` from the wallet chip and the new Home header profile icon — Task 11 — just no longer shell tabs).

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/core/routing/app_router.dart
```

Expected: No issues found.

- [ ] **Step 4: Manual verification**

Run the app (`flutter run`) and confirm all 4 shell tabs (Home, Stations, Activity, Cards) load without a routing exception, and that navigating away and back preserves each tab's scroll/state per go_router's normal `ShellRoute` behavior.

- [ ] **Step 5: Commit**

```bash
git add lib/core/routing/app_router.dart
git commit -m "feat: wire Stations/Activity into the shell, drop Wallet/Profile as tabs"
```

---

### Task 10: `map_config.dart` — Remove Style Picker, Restyle Markers, Migrate Tokens

**Files:**
- Modify: `lib/shared/map/map_config.dart`

**Interfaces:**
- Consumes: `Theme.of(context).colorScheme` (Task 2), `AppColors.{unavailableMarkerLight, unavailableMarkerDark}` (Task 1).
- Produces: restyled `StationClusterMarker`, marker color logic matching the spec's semantics (available / selected / unavailable / cluster). Task 11 (Home rebuild) consumes these through `_MapLayer`.

- [ ] **Step 1: Read the current file in full**

Read `lib/shared/map/map_config.dart` — it defines `enum MapStyle`, `MapStyleX` extension (`label`/`icon`/`mapBackground`/`tileUrl()`), `MapStylePicker` widget, `StationClusterMarker`, `LiveDispensePulse`.

- [ ] **Step 2: Confirm `MapStylePicker`'s only usage is in Home**

```bash
grep -rn "MapStylePicker" lib/ --include="*.dart"
```

If `home_screen.dart` is the only usage (expected, per spec research), the widget becomes unused once Task 11 removes it from Home. Delete the `MapStylePicker` class from this file in this task (its removal from `home_screen.dart`'s widget tree happens in Task 11, but deleting the now-dead class here avoids a two-step dangling-reference problem — if Task 11 lands first this analyzer warning briefly exists until this task lands; sequence Task 10 before Task 11 to avoid that entirely). Keep `MapStyle`/`MapStyleX`/`StationClusterMarker`/`LiveDispensePulse` — confirm each is still referenced elsewhere before removing (`LiveDispensePulse` is likely used by `live_dispense_screen.dart` — check with `grep -rn "LiveDispensePulse" lib/`).

- [ ] **Step 3: Reduce `MapStyle` to one value per theme, restyle `StationClusterMarker`**

Per the spec's Section 3, Home no longer supports switching between day/night/satellite/fuelEase styles — one style per `ThemeMode`. Simplify `MapStyleX.tileUrl()`/`mapBackground` so callers pick the style from `Theme.of(context).brightness` rather than a user-facing picker (`_MapLayer` in Task 11 does this). Restyle `StationClusterMarker`'s marker colors to match the spec's marker semantics:

```dart
Color availableMarkerColor(ColorScheme colorScheme) => colorScheme.primary;
Color selectedMarkerColor(ColorScheme colorScheme) => colorScheme.secondary;
Color unavailableMarkerColor(Brightness brightness) => brightness == Brightness.dark
    ? AppColors.unavailableMarkerDark
    : AppColors.unavailableMarkerLight;
Color clusterBadgeColor(ColorScheme colorScheme) => colorScheme.primary;
```

Wire these into `StationClusterMarker`'s existing paint/build logic in place of whatever `AppColors.primary`/`AppColors.success` it currently uses (its 2 occurrences per the token-usage inventory).

- [ ] **Step 4: Verify no analysis errors**

```bash
flutter analyze lib/shared/map/map_config.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/map/map_config.dart
git commit -m "refactor: remove MapStylePicker, restyle markers to Pump & Go semantics"
```

---

### Task 11: Home Screen — Full Rebuild

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/home_screen.dart` (full rewrite — do not attempt to patch the existing 1,310-line file incrementally)

**Interfaces:**
- Consumes: `HeaderWalletChip` (Task 6), `StationSheet` (Task 7), `nearestOrSelectedStationValueProvider`/`nearestOrSelectedStationProvider`/`userLocationProvider` (Task 4), `pendingActionsProvider` (Task 5), `stationMapPinsProvider` (existing), `Routes.profile` (existing), restyled map markers (Task 10).
- Produces: the rebuilt `HomeScreen` — the map-first layout from spec Section 3.

- [ ] **Step 1: Read the current file's `_MapLayer`, `_TopSearchBar`, `_LocationFab` implementations, and the greeting/location text logic, in full**

```bash
sed -n '1,50p' lib/features/dashboard/presentation/screens/home_screen.dart
grep -n "class _MapLayer\|class _TopSearchBar\|class _LocationFab\|Good morning\|Good afternoon\|Good evening\|authProvider" lib/features/dashboard/presentation/screens/home_screen.dart
```

Read each matched class fully — `_MapLayer`, `_TopSearchBar`, `_LocationFab` are kept (restyled, not rewritten from scratch) because they already correctly integrate `flutter_map`, `MapboxGeocodingService`, and the existing location-permission flow. The current file also already computes a time-of-day greeting and the user's display name (via `authProvider`, confirmed watched by the current file per prior research) somewhere near its header — find and note the exact expression it uses for both (do not guess the `authProvider` field shape; use whatever expression is actually there). Everything else in the file (`_DashboardSheet`, `_StationDetailPanel`, `MapStylePicker` usage, the old bottom-sheet balance/transactions UI) is deleted.

- [ ] **Step 1b: Locate the current pin-tap handler and resolved user-location value**

```bash
grep -n "onTap\|_selectedStation\|Marker(\|_userLocation\|Geolocator\|LatLng" lib/features/dashboard/presentation/screens/home_screen.dart
```

The current file's map already has a pin-tap callback (today it likely sets local `State` used by the old `_StationDetailPanel`) and already resolves the user's `LatLng` somewhere in its location-permission flow (today likely also local `State`, used to center/follow the map). Note both exact locations — Step 2 rewires them to write into the new providers instead of local state.

- [ ] **Step 2: Rewrite the file**

Structure (per spec Section 3):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/nearest_station_provider.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/pending_actions_provider.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/widgets/header_wallet_chip.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/widgets/station_sheet.dart';

// Keep _MapLayer, _TopSearchBar, _LocationFab from the current file here,
// restyled per Task 10's marker colors and this task's Step 1 findings —
// do not change their public behavior EXCEPT for two rewires, both found
// in Step 1b:
//   1. The existing pin-tap callback must call
//      `ref.read(nearestOrSelectedStationProvider.notifier).state = pin.id`
//      instead of (or in addition to, if still needed for the map's own
//      camera-follow behavior) whatever local State it currently sets.
//   2. Once the existing location-permission flow resolves a LatLng, it
//      must call
//      `ref.read(userLocationProvider.notifier).state = resolvedLatLng`
//      instead of (or in addition to) whatever local State it currently sets.
// Both providers are ConsumerWidget/ConsumerState-compatible — _MapLayer
// must become a ConsumerWidget/ConsumerStatefulWidget if it is not already.

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingAction = ref.watch(pendingActionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(colorScheme: colorScheme),
            if (pendingAction != null)
              _PendingActionBanner(action: pendingAction, colorScheme: colorScheme),
            Expanded(
              child: Stack(
                children: [
                  const _MapLayer(),
                  const Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _TopSearchBar(),
                  ),
                  const Positioned(
                    right: 12,
                    bottom: 172,
                    child: _LocationFab(),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: StationSheet(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _GreetingBlock(),
          Row(
            children: [
              const HeaderWalletChip(),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.push(Routes.profile),
                tooltip: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreetingBlock extends ConsumerWidget {
  const _GreetingBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // REPLACE THE TWO LINES BELOW with the exact greeting-string and
    // area-name expressions found in Task 11 Step 1 (this file already
    // computes a time-of-day greeting + the user's name via authProvider,
    // and an area name from the location flow, elsewhere in the current
    // home_screen.dart) — port that logic verbatim into this widget's
    // build method. Do not invent a different authProvider field shape
    // than whatever is actually there; this is the one line in this task
    // that must come from reading the real file, not from this plan.
    final String greetingText = 'Good evening'; // placeholder value — replace
    final String? areaNameText = null; // placeholder value — replace

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (areaNameText != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 10, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                areaNameText,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        Text(
          greetingText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PendingActionBanner extends StatelessWidget {
  const _PendingActionBanner({required this.action, required this.colorScheme});
  final PendingAction action;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.amberSurfaceDark
            : AppColors.amberSurface,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.amberTextDark
                    : AppColors.amberText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push(action.route),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
```

**`_GreetingBlock`'s two marked lines (`greetingText`/`areaNameText`) must be replaced with the real expressions from Step 1 before this task is done — the reviewer must reject this task if the literal comment text "placeholder value — replace" is still present in the final diff.** Add the `import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';` for `AppColors.amberSurface`/etc.

- [ ] **Step 3: Verify no analysis errors and no leftover placeholder markers**

```bash
flutter analyze lib/features/dashboard/presentation/screens/home_screen.dart
grep -n "placeholder value" lib/features/dashboard/presentation/screens/home_screen.dart
```

Expected: `flutter analyze` reports no issues; the `grep` finds nothing (empty output — both placeholder lines have been replaced with the real ported expressions).

- [ ] **Step 4: Manual verification**

Run the app, open Home in both light and dark mode, confirm: the map fills the space between header and nav, the search bar and recenter control float correctly, tapping a pin or nothing shows the correct station in the sheet (nearest by default), dragging the sheet between collapsed/expanded works, and the pending-action banner appears only when `pendingActionsProvider` returns non-null (simulate by temporarily overriding it, then revert the override).

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/screens/home_screen.dart
git commit -m "feat: rebuild Home as full-screen map-first layout"
```

---

### Task 12: Dispense Flow — Correct Copy, Accept `preselectedStationId`

**Files:**
- Modify: `lib/features/dispense/presentation/screens/create_dispense_screen.dart`
- Modify: `lib/features/dispense/presentation/screens/pin_qr_screen.dart`

**Interfaces:**
- Consumes: migration mapping table (Global Constraints), fueling copy table (Global Constraints).

- [ ] **Step 1: Read both files in full**

Confirm whether `CreateDispenseScreen` already has a `preselectedStationId` constructor parameter (per earlier research it does, per its screen list description "also takes `preselectedStationId`" — verify by reading the constructor) and locate every customer-facing string that says or implies "scan" or "attendant"/"staff".

- [ ] **Step 2: Correct customer-facing copy**

Apply the exact copy table from Global Constraints. Do not touch any string that isn't customer-facing (e.g. internal log messages, analytics event names) — only UI text.

- [ ] **Step 3: Migrate `AppColors` usage in both files**

Per the migration procedure in Global Constraints, using each file's known token inventory:
- `create_dispense_screen.dart`: `brand`, `brandGradient`, `error` (kept), `midnight`, `surfaceElevatedDark`
- `pin_qr_screen.dart`: `brand`, `brandCyan`, `brandGlow`, `brandGradient`, `error` (kept), `info` (kept), `midnight`, `nightGradient`, `success` (kept), `surfaceElevatedDark`

- [ ] **Step 4: Verify no analysis errors**

```bash
flutter analyze lib/features/dispense/presentation/screens/create_dispense_screen.dart lib/features/dispense/presentation/screens/pin_qr_screen.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dispense/presentation/screens/create_dispense_screen.dart lib/features/dispense/presentation/screens/pin_qr_screen.dart
git commit -m "fix: correct fueling-flow copy to pump-confirms, not attendant; migrate tokens"
```

---

### Task 13: Migrate Auth Screens

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart` (`brand`, `brandGlow`, `error` kept, `midnight`, `nightGradient`, `surfaceDark`)
- Modify: `lib/features/auth/presentation/screens/register_screen.dart` (`brand`, `brandGlow`, `brandGradient`, `error` kept, `midnight`, `nightGradient`, `surfaceDark`)
- Modify: `lib/features/auth/presentation/screens/splash_screen.dart` (`brand`, `brandGlow`, `brandGradient`, `nightGradient`)
- Modify: `lib/features/auth/presentation/screens/welcome_screen.dart` (`brandCyan`, `brandGlow`, `brandGradient`, `midnight`, `nightGradient`)

Apply the migration procedure from Global Constraints to each file using its listed token inventory above.

- [ ] **Step 1: Migrate all four files** per the procedure.
- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/auth/
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/
git commit -m "refactor: migrate auth screens to colorScheme"
```

---

### Task 14: Migrate Cards Screens (Residual)

**Files:**
- Modify: `lib/features/cards/presentation/screens/card_details_screen.dart` (`error`/`success`/`warning` kept, `primary`)
- Modify: `lib/features/cards/presentation/screens/card_pending_screen.dart` (`error`/`warning` kept, `midnight`, `textPrimaryDark`, `textSecondaryDark`, `textTertiaryDark`)
- Modify: `lib/features/cards/presentation/screens/cards_screen.dart` (`brand`, `brandGlow`, `brandGradient`, `error`/`info`/`success` kept)
- Modify: `lib/features/cards/presentation/screens/create_card_screen.dart` (`error` kept, `primary`, `surfaceDark`, `textPrimaryDark`, `textSecondaryDark`, `textTertiary`)
- Modify: `lib/features/cards/presentation/widgets/cards_stats_card.dart` (`accent` — 2 occurrences)

Apply the migration procedure to each file using its listed token inventory above. `card_details_screen.dart` and `cards_screen.dart` were already migrated for dark-mode-surface hardcoding in the prior wallet/cards redesign (`docs/superpowers/specs/2026-05-21-wallet-cards-redesign-design.md`) — this task only touches their remaining brand-color references (`primary`, `brand`/`brandGlow`/`brandGradient`), not their surfaces.

- [ ] **Step 1: Migrate all five files** per the procedure.
- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/cards/
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/cards/presentation/screens/ lib/features/cards/presentation/widgets/cards_stats_card.dart
git commit -m "refactor: migrate cards screens' remaining brand-color references to colorScheme"
```

---

### Task 15: Migrate Dispense Screens (Residual)

**Files:**
- Modify: `lib/features/dispense/presentation/screens/dispense_complete_screen.dart` (`brand`, `brandCyan`, `midnight`, `nightGradient`, `success` kept, `surfaceElevatedDark`)
- Modify: `lib/features/dispense/presentation/screens/dispense_history_screen.dart` (`borderDark`, `error`/`info`/`success` kept, `midnight`, `surfaceDark`, `surfaceElevatedDark`, `surfaceVariantDark`, `textPrimaryDark`, `textSecondaryDark`)
- Modify: `lib/features/dispense/presentation/screens/live_dispense_screen.dart` (`brand`, `brandGradient`, `error` kept, `midnight`, `nightGradient`, `success` kept, `surfaceElevatedDark`)

(`create_dispense_screen.dart` and `pin_qr_screen.dart` were already migrated in Task 12.)

- [ ] **Step 1: Migrate all three files** per the procedure.
- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/dispense/
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dispense/presentation/screens/dispense_complete_screen.dart lib/features/dispense/presentation/screens/dispense_history_screen.dart lib/features/dispense/presentation/screens/live_dispense_screen.dart
git commit -m "refactor: migrate remaining dispense screens to colorScheme"
```

---

### Task 16: Migrate Profile Screens

**Files:**
- Modify: `lib/features/profile/presentation/screens/change_password_screen.dart` (`borderDark`, `brandLight`, `error`/`info`/`success` kept, `midnight`, `primary`, `surfaceVariantDark`, `textPrimaryDark`, `textSecondaryDark`)
- Modify: `lib/features/profile/presentation/screens/edit_profile_screen.dart` (`borderDark`, `brandLight`, `error` kept, `midnight`, `primary`, `success` kept, `surfaceVariantDark`, `textPrimaryDark`, `textSecondaryDark`)
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart` (`brand`, `brandCyan`, `brandGlow`, `brandGradient`, `error`/`info`/`success` kept, `nightGradient`, `surfaceDark`, `surfaceElevatedDark`)

- [ ] **Step 1: Migrate all three files** per the procedure.
- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/profile/
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/screens/
git commit -m "refactor: migrate profile screens to colorScheme"
```

---

### Task 17: Migrate Stations Screens

**Files:**
- Modify: `lib/features/stations/presentation/screens/station_details_screen.dart` (`accent`, `borderDark`, `dieselColor` kept, `error`/`info`/`success`/`warning` kept, `midnight`, `petrolColor` kept, `premiumColor` kept, `primary`, `shadow` kept, `surfaceElevatedDark`, `surfaceVariantDark`, `textPrimaryDark`, `textSecondaryDark`)
- Modify: `lib/features/stations/presentation/screens/station_map_screen.dart` (`brand`, `error`/`success` kept, `primary`, `statusInactive`)
- Modify: `lib/features/stations/presentation/screens/stations_screen.dart` (`borderDark`, `error`/`success` kept, `textSecondaryDark`)

- [ ] **Step 1: Migrate all three files** per the procedure.
- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/stations/
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/stations/presentation/screens/
git commit -m "refactor: migrate stations screens to colorScheme"
```

---

### Task 18: Migrate Wallet Screens (Residual)

**Files:**
- Modify: `lib/features/wallet/presentation/screens/recharge_screen.dart` (`borderDark`, `error`/`info`/`success` kept, `midnight`, `primary`, `surfaceDark`, `textPrimaryDark`, `textSecondaryDark`)
- Modify: `lib/features/wallet/presentation/screens/transaction_history_screen.dart` (`borderDark`, `error`/`success` kept, `midnight`, `primary`, `surfaceDark`, `surfaceVariantDark`, `textPrimaryDark`, `textSecondaryDark`)
- Modify: `lib/features/wallet/presentation/screens/wallet_screen.dart` (`brand`, `brandGlow`, `brandGradient`, `error`/`warning` kept, `primary`)
- Modify: `lib/features/wallet/presentation/widgets/transaction_detail_sheet.dart` (`borderDark`, `error`/`success` kept, `surfaceDark`, `textPrimaryDark`, `textSecondaryDark`)
- Modify: `lib/features/wallet/presentation/widgets/transaction_list_item.dart` (`error`/`success` kept, `surfaceVariantDark`, `textPrimaryDark`, `textSecondaryDark`, `textTertiary`)

`wallet_screen.dart` and `cards_screen.dart`'s sibling files were already migrated for dark-surface hardcoding in the prior redesign — this task, like Task 14, only touches remaining brand-color references.

- [ ] **Step 1: Migrate all five files** per the procedure.
- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/wallet/
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/wallet/presentation/screens/ lib/features/wallet/presentation/widgets/transaction_detail_sheet.dart lib/features/wallet/presentation/widgets/transaction_list_item.dart
git commit -m "refactor: migrate remaining wallet screens to colorScheme"
```

---

### Task 19: Final Cleanup — Delete Fully-Migrated Legacy Tokens

**Files:**
- Modify: `lib/shared/theme/app_colors.dart`

- [ ] **Step 1: Verify zero remaining references to every removed-with-call-sites token**

```bash
grep -rE "AppColors\.(brand\b|brandDark|brandLight|brandCyan|brandGlow|primary\b|primaryDark|primaryLight|primarySoft\b|primaryDarkMode|primarySoftDark|accent\b|midnight|navy|backgroundDark|surfaceDark|surfaceElevatedDark|surfaceVariantDark|borderDark|borderSubtleDark|background\b|surface\b|surfaceVariant\b|surfaceStrong|border\b|borderStrong|textPrimary\b|textSecondary\b|textTertiary\b|textDisabled|textPrimaryDark|textSecondaryDark|textTertiaryDark|statusInactive|nightGradient)\b" lib/
```

Expected: no output. If anything matches, that file was missed by Tasks 3, 12-18 — go migrate it using the same procedure before proceeding; do not delete tokens still in use.

- [ ] **Step 2: Delete the now-fully-unused tokens from `app_colors.dart`**

Remove every field named in the Global Constraints "Removed tokens WITH call sites" list from the class body (they were only kept temporarily so Tasks 3-18 could land incrementally without breaking the build).

- [ ] **Step 3: Verify the whole repo analyzes clean**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 4: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass, including the new provider tests from Tasks 4-5 and every existing test file untouched by this plan.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/theme/app_colors.dart
git commit -m "chore: remove legacy brand-blue tokens now that every screen is migrated"
```
