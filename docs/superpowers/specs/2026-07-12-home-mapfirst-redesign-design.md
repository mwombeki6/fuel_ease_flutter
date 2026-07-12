# Home Screen Map-First Redesign — "Pump & Go"

**Date:** 2026-07-12
**Status:** Approved — ready for implementation
**Scope:** New design tokens (`AppColors`, `AppTextStyles` additions), bottom navigation shell (`MainNavigation`), and `HomeScreen` (full rebuild).

This is the first delivery of the Flutter app's full visual identity replacement (approved: full replacement, not an extension of the existing brand-blue system; a distinct consumer-friendly identity, not brand-matched to the `fuel-ease-web` "Signal Grid" ops dashboard). Home is the flagship screen for the new identity. The remaining ~18 screens (auth, dispense flow, profile, stations list, wallet recharge/transaction history) and the already-redesigned wallet/cards screens (`docs/superpowers/specs/2026-05-21-wallet-cards-redesign-design.md`) are **out of scope** here — see [Out of Scope](#out-of-scope).

---

## 1. Design Tokens — "Pump & Go" Palette

Replace the brand-blue palette in `lib/shared/theme/app_colors.dart` with the tokens below. This is a full replacement of the color system, not an addition alongside it — `brand`, `brandDark`, `brandLight`, `brandCyan`, `midnight`, `navy`, and their aliases are removed. Semantic tokens (`success`, `error`, `warning`, `info`) are kept but repointed to the new hex values so existing call sites that reference them by name continue to compile.

### Light theme

| Token | Hex | Usage |
|---|---|---|
| `background` | `#FAF8F4` | Scaffold background, page canvas |
| `surface` | `#FFFFFF` | Cards, sheets, search field — elevation via shadow, not border |
| `surfaceMuted` | `#F0EEE8` | Header icon buttons, secondary chip backgrounds |
| `border` | `#EDEAE1` | Used sparingly — dividers, the rare bordered container. Prefer shadow elevation over borders per Section 3. |
| `textPrimary` | `#211F1A` | Primary text |
| `textSecondary` | `#8A8578` | Secondary/meta text |
| `evergreen` | `#1F4D3A` | Brand accent: active nav icon/label, wallet-chip balance text, location-pin icon stroke, available-station map markers, cluster badges |
| `brightGreen` | `#3FAE5C` | Primary action + success/active: Scan pump button, Pay nav icon fill, Open status text, selected-station map marker |
| `amber` | `#A3760F` (text) / `#FDF2E3` (surface) | Pending/attention banners |
| `errorDot` | `#D9534F` | Notification badge dot |
| `mapCanvas` | `#E9EDE2` | Map background fill |
| `mapRoad` | `#D3DCC3` | Road geometry |
| `mapAreaFill` | `#DFE4D5` | Area/building blocks |
| `mapLabel` | `#8A9179` | Road/area name labels |

### Dark theme

| Token | Hex | Usage |
|---|---|---|
| `backgroundDark` | `#161513` | Scaffold background — neutral charcoal, not brown-black |
| `surfaceDark` | `#211F1C` | Cards, sheets, search field |
| `surfaceMutedDark` | `#2A2825` | Elevated/tertiary surfaces |
| `borderDark` | `#3A3733` | Search-field border in dark mode (kept for definition against the dark map; light mode's search field has no border) |
| `textPrimaryDark` | `#F2F0EA` | Primary text |
| `textSecondaryDark` | `#A8A296` | Secondary/meta text |
| `evergreenDark` | `#2A5C46` | Reserved for future brand-fill surfaces on other screens (Cards/Stations/Activity). Not used anywhere on Home in this delivery — see note below. |
| `brightGreenDark` | `#4BC470` | Does double duty on Home: brand accent (active nav label, wallet-chip text) *and* primary action/success (Scan pump button, Open status, selected marker, Pay icon fill) |
| `amberDark` | `#F0CB80` (text) / `#332A17` (surface) | Pending/attention banners |
| `errorDotDark` | `#E8837E` | Notification badge dot |
| `mapCanvasDark` | `#1C1A17` | Map background fill |
| `mapRoadDark` | `#28261F` | Road geometry |
| `mapLabelDark` | `#8F897C` (area labels) / `#C9C2AE` (road labels, higher-contrast) | Label text — dark mode needs the higher-contrast variant on roads specifically for legibility against `mapRoadDark` |
| `unavailableMarkerDark` | `#4A463D` | Closed/unavailable station pins |
| `unavailableMarkerLight` | `#B9B3A3` | Closed/unavailable station pins |

**Note on `evergreenDark`:** the approved Home mockups never needed a distinct deep-evergreen fill in dark mode once the wallet/card strip was removed (Section 5) — `brightGreenDark` covers every remaining green element. Keep `evergreenDark` defined in `AppColors` regardless; it exists for other screens' future redesigns (e.g. a card illustration on the Cards tab), not because Home needs it today. Do not delete it as "unused."

### Typography

Keep `google_fonts` Sora (`lib/shared/theme/app_text_styles.dart`) — no typeface change was scoped in this round. Add one requirement not currently expressed anywhere in `AppTextStyles`: **tabular numerals on every monetary and numeric-count display** (wallet chip, any liters/pump counts). Apply via `fontFeatures: [FontFeature.tabularFigures()]` at the call site (balance chip, station-sheet pump counts) rather than adding it to a shared text style, since not every use of `bodyMedium`/`titleMedium` etc. is numeric.

### Icons

Replace `Icons.*` Material glyphs used on Home and the nav shell with a consistent **stroke-based icon set** (2px stroke weight, matching the mockups' inline-SVG look). Use `flutter_svg` if not already a dependency, or hand-build `CustomPainter`s for the ~10 icons needed (home, map-pin, payment/scan, clock/activity, card, search, bell, chevron, filter, recenter). Check `pubspec.yaml` for `flutter_svg` before adding it as a new dependency.

---

## 2. Bottom Navigation Shell Rebuild

**File:** `lib/core/navigation/main_navigation.dart`

The current `_FeNavBar` is a 4-item glass-morphism pill (Home, Cards, Wallet, Profile) plus a separately-floating `_CenterFuelButton`. Replace it entirely.

### New structure: 5 equal-width destinations, no floating FAB

```
Home · Stations · Pay · Activity · Cards
```

- Single docked `Container`, full width (no side margins — flush with screen edges), `Row` of 5 `Expanded` children, each a `Column` (icon + label, `MainAxisAlignment.center`).
- **No raised/floating action button.** Pay is a same-baseline nav item like the other four. Its icon sits inside a filled rounded-square container (28×28, `borderRadius: 9`, background = `brightGreen`/`brightGreenDark` — **always** filled, not state-dependent, since Pay represents an action/entry point rather than a persistent selected screen).
- Pay's label color: always `evergreen`/`brightGreenDark` (brand-colored), independent of which tab is currently selected — it does not participate in the active/inactive state logic the other four items use.
- The other four items use standard active/inactive coloring: active = `evergreen` (light) / `brightGreenDark` (dark) on both icon and label; inactive = `textSecondary`/`textSecondaryDark`.
- Bottom safe-area padding: `padding: EdgeInsets.only(bottom: 8 + MediaQuery.paddingOf(context).bottom)` (or `SafeArea(bottom: true, child: ...)` wrapping the row) — do not hardcode a fixed bottom inset.
- Bar surface: `surface`/`surfaceDark`, elevated via `BoxShadow` only (`0 -2px 10px rgba(0,0,0,0.05)` light / `rgba(0,0,0,0.2)` dark) — no border.

### Routing changes

`ShellRoute` (in `app_router.dart`) currently wraps `Routes.home`, `Routes.cards`, `Routes.wallet`, `Routes.profile`. Update the shell's tab set to:

| Tab | Route | Target screen | Redesign status |
|---|---|---|---|
| Home | `Routes.home` | `HomeScreen` (rebuilt, Section 3) | **This spec** |
| Stations | `Routes.stations` | `StationsScreen` (existing) | Out of scope — future work |
| Pay | *(not a route — see below)* | — | New, minimal (Section 6) |
| Activity | *new route, e.g.* `/activity` | `ActivityScreen` (new, thin wrapper) | New, minimal (Section 6) |
| Cards | `Routes.cards` | `CardsScreen` (already redesigned) | Already done |

`Routes.wallet` and `Routes.profile` are no longer direct nav-bar destinations. Wallet detail is reached by tapping the header wallet chip (Section 5); Profile needs a new entry point (not designed in this round — flag as a small follow-up, e.g. a settings icon somewhere, since removing Profile's nav slot without replacing its entry point would strand that screen. Recommend the simplest fix: add a profile/settings icon button next to the header bell on Home, reusing `Routes.profile` as-is, until a proper location is designed).

Tapping **Pay** does not switch the shell's active tab — it pushes a route (`context.push(...)`) on top of the current tab, matching the old `_CenterFuelButton`'s `context.push(Routes.createDispensingRequest)` pattern. The nav bar's "active tab" visual state is therefore driven by the shell's current route among {Home, Stations, Activity, Cards} only; Pay is never "active" in that sense (consistent with its always-on brand-colored treatment above).

---

## 3. Home Screen — Full-Screen Map Architecture

**File:** `lib/features/dashboard/presentation/screens/home_screen.dart` (full rebuild — current file is 1,310 lines built around a different visual system; do not attempt to patch it incrementally)

### Layout (top to bottom, single `Column` inside the `Scaffold` body)

1. **Header** (fixed height, ~66px) — greeting/location on the left (`Text` "Good evening, {firstName}" + a small location-pin icon + area name, sourced from the existing geolocation state already used by `_TopSearchBar`), wallet chip + notification bell on the right (Section 5).
2. **Conditional alert banner** (Section 6) — renders only when `pendingActionsProvider` (new) has an entry. Zero height / not in the tree otherwise. Does not permanently reduce map height.
3. **Map zone** — `Expanded` (fills all remaining vertical space down to the bottom nav). `Stack` containing:
   - `_MapLayer` (existing widget, keep as-is functionally — `FlutterMap` + `MarkerClusterLayerWidget` + `MarkerLayer` for user location) restyled with the new `TileLayer`/marker colors from Section 1 and marker semantics from Section 4. Map fills 100% of the zone — no border, no border-radius, no card wrapper (edge-to-edge).
   - Floating search bar (restyle existing `_TopSearchBar`'s search field — keep the Mapbox geocoding autosuggest logic via `MapboxGeocodingService.suggest`, restyle only: taller field ~48px, `surface`/`surfaceDark` background, shadow elevation, no visible border in light mode).
   - Single floating recenter control (existing `_LocationFab`, restyled, bottom-right, positioned above the sheet's collapsed height so it never sits behind the sheet). Drop the separate zoom +/− control stack the mockups explored — `flutter_map` already supports pinch-zoom; a dedicated zoom control is redundant chrome per the "fewer bordered rectangles / less UI on the canvas" direction from the approved round.
   - Persistent draggable station sheet (Section 4), anchored to the bottom of this zone (not the screen) so it never overlaps the nav bar below.

4. **Bottom navigation** — outside the `Expanded` map zone, from Section 2.

### Removed from Home entirely

- The old `_DashboardSheet` (balance card, "Fuel Up" CTA button, inline recent-transactions list) — replaced by the header wallet chip + station sheet + conditional alert. Do not carry any of its widgets forward.
- `MapStylePicker` (day/night/satellite/fuelEase style switcher) — the new design has one map style per theme (light/dark), matching `AppColors.mapCanvas`/`mapCanvasDark`. Remove the picker UI; keep at most one `MapStyle` value per `ThemeMode` if `map_config.dart`'s `MapStyle` enum is still needed elsewhere (check before deleting the enum outright).

### Providers watched

- `stationMapPinsProvider` (existing, `lib/features/stations/presentation/providers/station_map_provider.dart`) — unchanged provider, restyled marker rendering only.
- `availableBalanceProvider` (existing) — drives the header wallet chip.
- A new `nearestOrSelectedStationProvider` (`Provider.autoDispose<StationMapPin?>`, new file `lib/features/dashboard/presentation/providers/nearest_station_provider.dart`) — resolves which station the sheet displays: the user-tapped pin if one is selected this session, otherwise the nearest station from `stationMapPinsProvider` by client-computed distance (reuse the existing `_metersTo()`/`_distanceLabel()` logic, moved out of `home_screen.dart` into this provider file so it's testable independent of the widget).
- `pendingActionsProvider` (new, Section 6).

---

## 4. Station Bottom Sheet — Three States

**File:** `lib/features/dashboard/presentation/widgets/station_sheet.dart` (new)

Built on Flutter SDK's `DraggableScrollableSheet` (already used elsewhere in the app for the old `_DashboardSheet` — no new package needed; confirmed no dedicated bottom-sheet package exists in `pubspec.yaml`, and none is required).

| State | `initialChildSize` / `minChildSize` | Content |
|---|---|---|
| Collapsed | `~0.22` of map-zone height | Station name (18px, `w800`), "Open"/"Closed" status text (right-aligned, colored, no pill background), distance + drive-time subtitle, `Directions` + `Scan pump` buttons side by side (48px tall, `borderRadius: 14`) |
| Half-expanded | `~0.5` | Adds: fuel types (if available — see [Known Gaps](#known-gaps--backend-follow-ups)), "`{activePumps}` pumps available" (from `StationMapPin.activePumps`, present today), payment methods (if available — see Known Gaps) |
| Full-expanded | `~0.92` | Adds: address/area (`StationMapPin.region`/`district`, present today), amenities and phone number (**not modeled today** — omit these rows until the backend adds them; do not fabricate placeholder data), `Directions` + `Scan pump` remain pinned at the bottom |

`snap: true`, `snapSizes: [0.22, 0.5, 0.92]`. Corner radius `26` top-only. Drag handle: 36×4px pill, `border`/`borderDark`-toned, centered, 10px top padding.

**Open/closed derivation:** `StationMapPin` has no `isOpen` field. Keep the existing derivation used in the current `home_screen.dart`: open = `status == 'active' && !hasSuspension`.

---

## 5. Header Wallet Chip

Single-line, plain text, no border/background container: `"TZS {formattedBalance}"` using tabular numerals, colored `evergreen`/`brightGreenDark`, positioned left of the notification bell in the header. Source: `availableBalanceProvider`.

- Tap target: wraps in a `GestureDetector`/`InkWell` (min 44×44 hit area even though the visible text is smaller — pad the tappable region, don't enlarge the text) that pushes `Routes.wallet` (Payment Hub / wallet detail — reuse the existing, already-redesigned `WalletScreen`; no new destination needed).
- Hide/reveal: reuse whatever balance-masking mechanism `WalletScreen` already implements if one exists (check `wallet_provider.dart`/`WalletSummary` for a stored preference before building a new one); if none exists today, this chip does not need to introduce one — masking wasn't part of the approved mockups, only referenced as "support hide/reveal **where required**." Treat as not required for this delivery unless an existing mechanism is trivially reusable.

---

## 6. Conditional Alert Banner + Activity/Pay Tabs (minimal)

### Alert banner

Single-line, dismissible-by-navigation (not by swipe-to-dismiss — tapping "View" is the only exit), amber-toned, renders only when `pendingActionsProvider` returns a non-null entry.

**`pendingActionsProvider`** (`Provider.autoDispose<PendingAction?>`, new file `lib/features/dashboard/presentation/providers/pending_actions_provider.dart`). Priority order when more than one exists, return the highest-priority one:

1. An in-progress dispense session: `FuelSession.status` where `isActive == true` (existing model, `lib/features/wallet/data/models/fuel_session.dart`) — surfaces as `"Fueling in progress at {stationName}"`.
2. Any other in-flight action the app already tracks (e.g. an unconfirmed recharge, if `RechargeScreen`'s provider exposes an in-flight state — inspect `lib/features/wallet/presentation/providers/` at implementation time for the exact provider name; do not invent one if none exists).

**Known Gaps** (see below): `WalletTransaction` has no `pending`/`failed`/`reversed` status field today, so those three specific banner triggers named in the approved design ("pending, failed, reversed, or action-required transactions") **cannot be fully implemented against the current backend contract**. Implement the provider against what's available now (dispense-session state); wire the wallet-transaction-status cases as soon as the backend model supports them — the provider's shape (`PendingAction? { type, label, route }`) is designed to accept new `type` variants without a UI change.

### Activity tab (minimal, new)

**File:** `lib/features/dashboard/presentation/screens/activity_screen.dart` (new, thin)

No unified wallet+dispense feed was designed in this round. For this delivery, `ActivityScreen` renders the existing `TransactionHistoryScreen` content (reuse its body, don't fork it) reached via the new `Routes.activity` path registered in the shell. A true merged activity feed (wallet transactions + dispense sessions) is future work — see [Out of Scope](#out-of-scope).

### Pay tab (minimal, new)

Tapping **Pay** pushes `Routes.createDispensingRequest` (existing `CreateDispenseScreen`) — the closest existing "payment hub" entry point. A dedicated Payment Hub screen (scan / manual code / repeat payment, as described during brainstorming) was not designed in this round; this is an interim wire-up, not the final destination. Flag as follow-up design work.

---

## 7. "Scan pump" — Reconciling With the Existing Dispense Flow

The approved mockups show `Scan pump` as a station-sheet action implying the customer scans a QR/code physically on the pump. **This does not match the current backend flow.** Research findings:

- `mobile_scanner` is pinned in `pubspec.yaml` but is used nowhere in `lib/` — there is no camera-based scan screen today.
- The existing dispense flow is the *inverse*: the app **generates** a PIN/QR (`PinQrScreen`, `lib/features/dispense/presentation/screens/pin_qr_screen.dart`) that the customer shows to station staff, who scan it. There is no evidence the backend validates a pump-side code the customer's camera would read.
- `Routes.scanQR = '/fuel/scan'` exists as a constant in `routes.dart` but has no matching `GoRoute` — it is dead code today.

**Resolution for this delivery:** the `Scan pump` button on the station sheet navigates to `Routes.createDispensingRequest` with `preselectedStationId` set to the sheet's current station (`context.push(Routes.createDispensingRequest, extra: station.id)`), reusing the existing `CreateDispenseScreen → PinQrScreen` flow as-is. This preserves the design intent — the button establishes fueling context for a specific station before anything payment-related happens — without inventing scanning infrastructure the backend doesn't support.

Building an actual customer-facing camera scanner (using the already-pinned `mobile_scanner`) that reads a code physically posted at the pump is a larger, separate backend + app effort (the backend would need to mint and validate pump-specific codes) and is **out of scope** for this spec.

---

## Known Gaps / Backend Follow-ups

These are data-model gaps discovered while writing this spec, not design decisions. The Home UI is built to degrade gracefully around them (omit the row/chip rather than fabricate data) and should be revisited once the backend adds the fields.

| Gap | Current state | Affects |
|---|---|---|
| Station fuel types | `StationMapPin` has no `fuelTypes` field | Station sheet half/full-expanded states — omit the "Petrol · Diesel" row until available |
| Station payment methods | `StationMapPin` has no supported-payment-methods field | Station sheet half-expanded state — omit until available |
| Station amenities/phone | Not modeled | Station sheet full-expanded state — omit until available |
| Wallet transaction status (`pending`/`failed`/`reversed`) | `WalletTransaction` only has `type: credit\|debit`, no status field | Conditional alert banner can't surface these three cases yet — see Section 6 |
| Profile nav entry point | Removed from the 5-item bottom nav in favor of Stations/Activity | Needs a small follow-up (icon button on Home header, or another location) — not designed in this round |
| Duplicate `walletTransactionsProvider` | Defined independently in both `wallet_provider.dart` and `wallet_transactions_provider.dart` with different signatures | Pre-existing tech debt, unrelated to this redesign; use `recentTransactionsProvider` (from `wallet_transactions_provider.dart`) for any Home/Activity read in this delivery, don't fix the duplication as part of this work |

---

## Out of Scope

- Full visual redesign of `StationsScreen`, `ActivityScreen` (beyond the thin wrapper in Section 6), `ProfileScreen`, all `dispense/` screens, `auth/` screens, `recharge_screen.dart`, `transaction_history_screen.dart`.
- A real customer-facing camera QR scanner (Section 7).
- A dedicated Payment Hub screen for the Pay tab (Section 6).
- A unified wallet+dispense Activity feed (Section 6).
- Wallet-balance hide/reveal, unless a mechanism already exists to reuse (Section 5).
- Removing the `MapStyle` enum / `map_config.dart` infrastructure if it's still referenced elsewhere — only remove the day/night/satellite picker *UI* from Home.

---

## Implementation Notes

- Build the map-zone `Stack` and station sheet as their own widgets (`_MapZone`, `StationSheet`) rather than inline in `HomeScreen.build()` — the old file's 1,310-line single-widget structure is exactly the kind of file this rebuild should avoid repeating.
- `nearest-station` distance math already exists in the current file (`_metersTo`/`_distanceLabel`, using `latlong2`'s `Distance`) — extract it into `nearest_station_provider.dart` rather than rewriting it.
- Existing marker clustering (`flutter_map_marker_cluster`, `maxClusterRadius: 80`) stays; only marker colors/icons change per Section 1's tokens and Section 4's semantics (available / selected / unavailable / cluster).
- Confirm whether `flutter_svg` is already a dependency before adding it for the new icon set (Section 1) — if not present, hand-rolled `CustomPainter`s for the ~10 icons are an acceptable alternative with no new dependency.

## Files to Create

| File | Purpose |
|---|---|
| `lib/features/dashboard/presentation/widgets/station_sheet.dart` | `StationSheet` — 3-state `DraggableScrollableSheet` (Section 4) |
| `lib/features/dashboard/presentation/providers/nearest_station_provider.dart` | `nearestOrSelectedStationProvider` (Section 3) |
| `lib/features/dashboard/presentation/providers/pending_actions_provider.dart` | `pendingActionsProvider`, `PendingAction` model (Section 6) |
| `lib/features/dashboard/presentation/screens/activity_screen.dart` | Thin `ActivityScreen` wrapper (Section 6) |
| `lib/features/dashboard/presentation/widgets/header_wallet_chip.dart` | Wallet chip widget (Section 5) |

## Files to Modify

| File | Changes |
|---|---|
| `lib/shared/theme/app_colors.dart` | Full token replacement per Section 1 |
| `lib/shared/theme/app_theme.dart` | Repoint `ColorScheme.light`/`.dark` field mappings to new tokens; update `bottomSheetTheme`/`inputDecorationTheme`/button themes' radii to match Section 3-4 (48px search field, 14px button radius, 26px sheet top radius) |
| `lib/core/navigation/main_navigation.dart` | Full nav-bar rebuild per Section 2 |
| `lib/core/routing/routes.dart` | Add `Routes.activity`; remove or leave dead `Routes.scanQR` (Section 7) as-is since it's unrelated to this work |
| `lib/core/routing/app_router.dart` | Update `ShellRoute` tab set per Section 2's table; add `GoRoute` for `Routes.activity` |
| `lib/features/dashboard/presentation/screens/home_screen.dart` | Full rebuild per Section 3 |
| `lib/shared/map/map_config.dart` | Remove `MapStylePicker` UI usage from Home; keep `MapStyle` enum/`StationClusterMarker`/`LiveDispensePulse` if referenced elsewhere, restyle marker colors per Section 1 |
