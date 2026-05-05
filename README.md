# FuelEase Mobile

A Flutter mobile application for managing fuel cards, dispensing fuel at partner stations, and tracking wallet transactions. Targets Android and iOS.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Features](#features)
4. [Project Structure](#project-structure)
5. [Real-Time Dispensing Flow](#real-time-dispensing-flow)
6. [Setup](#setup)
7. [Development Commands](#development-commands)

---

## Overview

FuelEase Mobile is the customer-facing interface for the FuelEase platform. Users can register, manage fuel cards, initiate dispense requests at GPS-located stations, monitor live fueling progress in real time, and review wallet and transaction history. Push notifications are delivered via Firebase Cloud Messaging.

**Platforms:** Android, iOS  
**Flutter SDK:** ^3.10.4 (Dart 3.10.4+)

---

## Architecture

The app follows **Clean Architecture** organized around **feature modules**. Each feature owns its own screens, providers, and data-access logic. Cross-cutting concerns live under `lib/core/`.

| Concern | Solution |
|---|---|
| State management | Riverpod 2 (`StateNotifier`) with `riverpod_annotation` + `riverpod_generator` |
| Navigation | GoRouter 14 with named routes defined in `lib/core/routing/` |
| HTTP | Dio 5 with a custom interceptor that auto-injects the JWT bearer token |
| Real-time events | WebSocket client (`lib/core/realtime/`) — server subscribes client to `user:<userID>` channel on connect |
| Secure storage | `flutter_secure_storage` for JWT access and refresh tokens |
| Immutable models | `freezed` + `json_serializable` (generated via `build_runner`) |

---

## Features

### Authentication (`auth`)
- Splash screen with token-based session restore
- Welcome, login, and registration screens
- Auth state managed by `auth_provider`

### Fuel Cards (`cards`)
- List all cards linked to the account
- Card detail view (balance, status, limits)
- Create new card flow
- Pending card status screen

### Dashboard (`dashboard`)
- Home screen summarising account status and quick-access actions

### Dispense (`dispense`)
- Create a new dispense request (select card, station, amount)
- PIN + QR code display screen with countdown timer
- Live dispense screen: real-time progress bar, liters dispensed, TZS charged (WebSocket-driven)
- Dispense complete screen with receipt summary
- Dispense history

### Profile (`profile`)
- View and edit user profile

### Stations (`stations`)
- Interactive map (flutter\_map + GPS) showing nearby partner stations
- Station detail view with address and available pumps

### Wallet (`wallet`)
- Wallet balance overview with `fl_chart` spending charts
- Recharge / top-up flow
- Full transaction history with pagination

---

## Project Structure

```
lib/
  core/
    api/            # Dio client, interceptors, error handling
    realtime/       # WebSocket client for pump/dispense events
    routing/        # GoRouter config and named route constants
    storage/        # secure_storage.dart (tokens), app_cache.dart
    constants/      # app_constants.dart (API base URL, etc.)
  features/
    auth/           # splash, welcome, login, register + auth_provider
    cards/          # cards list, details, pending, create + providers
    dashboard/      # home_screen
    dispense/       # create, pin_qr, live, complete, history + providers
    profile/        # profile_screen
    stations/       # list, details + station_provider, station_details_provider
    wallet/         # wallet, recharge, history + wallet_provider, wallet_transactions_provider
  main.dart
```

---

## Real-Time Dispensing Flow

The live fueling experience is driven by a persistent WebSocket connection managed in `lib/core/realtime/`.

1. **Create request** — User submits a dispense request. On success the app navigates to `PinQrScreen`.
2. **PinQrScreen** — Displays a QR code and numeric PIN alongside a countdown timer. The user presents this at the pump.
3. **Pump validation** — When the pump operator scans or enters the PIN, the backend sets the dispense status to `active` and emits an event over the WebSocket. The app receives this event and auto-navigates to `LiveDispenseScreen`.
4. **LiveDispenseScreen** — Subscribes to `dispensing_progress` WebSocket events. Each event carries `ml_dispensed`; the screen updates a live progress bar, the liters counter, and the running TZS cost in real time.
5. **Completion** — On a `dispense_complete` event the app navigates to `DispenseCompleteScreen`, which renders the final summary and a receipt.

---

## Setup

### Prerequisites

- Flutter SDK ^3.10.4 — see [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install)
- Dart 3.10.4+
- Android Studio / Xcode for device/emulator targets

### Install dependencies

```bash
flutter pub get
```

### Code generation

`freezed`, `json_serializable`, and `riverpod_generator` all require generated files. Run this after any model or provider change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

To watch for changes during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### API base URL

Open `lib/core/constants/app_constants.dart` and set `apiBaseUrl` to point at your backend instance. The default is:

```
http://localhost:8080
```

### Firebase (push notifications)

Push notifications require valid Firebase project credentials:

- **Android** — replace `android/app/google-services.json` with your project's file.
- **iOS** — replace `ios/Runner/GoogleService-Info.plist` with your project's file.

If you are running without Firebase, notifications will be silently disabled; all other features remain functional.

---

## Development Commands

| Command | Description |
|---|---|
| `flutter pub get` | Install / sync dependencies |
| `dart run build_runner build --delete-conflicting-outputs` | One-shot code generation |
| `dart run build_runner watch --delete-conflicting-outputs` | Continuous code generation |
| `flutter run` | Run on connected device or emulator |
| `flutter build apk` | Build Android APK (release) |
| `flutter build ios` | Build iOS archive (requires macOS + Xcode) |
| `flutter test` | Run unit tests in `test/` |
| `flutter analyze --no-fatal-infos` | Static analysis |

---

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| flutter_riverpod | ^2.5.1 | State management |
| riverpod_annotation / riverpod_generator | latest | Riverpod code generation |
| go_router | ^14.6.2 | Declarative navigation |
| dio | ^5.4.3 | HTTP client |
| freezed_annotation | latest | Immutable model code generation |
| json_annotation / json_serializable | latest | JSON serialisation code generation |
| flutter_secure_storage | ^9.2.2 | Encrypted token storage |
| qr_flutter | ^4.1.0 | QR code display (dispense PIN) |
| mobile_scanner | ^5.2.3 | QR code scanning |
| flutter_map | ^7.0.2 | Map rendering |
| geolocator | latest | GPS location |
| fl_chart | ^0.69.2 | Spending/usage charts |
| firebase_core / firebase_messaging | latest | Push notifications |
| google_fonts | ^6.2.1 | Typography |
