# DrawkcaB Flutter Client (Auth MVP)

This folder contains the Flutter implementation for the phased migration.

## Scope

Implemented in this MVP:
- Main entry screen (`/`)
- Login (`/login`)
- Register (`/register`)
- Forgot password (from login dialog)
- Reset password (`/reset-password`, supports `?token=`)
- Email confirmation result screen (`/confirm` with query params)
- Authenticated home placeholder (`/home`)

Deferred to later phases:
- Realtime chat and drawing canvas
- Socket.IO integration
- Dashboard parity with React

## Backend URL configuration

`AppConfig` reads the backend API URL from a Dart define:

- key: `BACKEND_URL`
- default: `http://localhost:3000/api`

Example:

```bash
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:3000/api
```

## Auth persistence

Access token persistence uses `flutter_secure_storage` (`drawkcab-access-token`).

## Run locally

```bash
cd flutter
flutter pub get
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:3000/api
```

For mobile targets, replace the device selector with an emulator or attached device.

## VS Code one-click run

This repo now includes launch configs in `.vscode/launch.json`:

- `Flutter: Chrome (Local API)`
- `Flutter: iPhone (LAN API)`
- `Flutter: Emulator (Local API)`

Use **Run and Debug** in VS Code and select one of these configurations.

Notes:
- The iPhone config uses your current LAN backend URL (`http://192.168.1.147:3000/api`).
- If your IP changes, update the `BACKEND_URL` value in `.vscode/launch.json`.
- For emulator runs, launch the emulator first (for example `flutter emulators --launch apple_ios_simulator`), then run `Flutter: Emulator (Local API)`.
