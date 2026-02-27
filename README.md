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
