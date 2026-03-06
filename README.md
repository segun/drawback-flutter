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
## iOS App Store Deployment

For deploying to the Apple App Store, see the comprehensive guides:

- **[iOS App Store Deployment Guide](docs/IOS_APPSTORE_DEPLOYMENT.md)** - Complete deployment process
- **[App Store Checklist](docs/APPSTORE_CHECKLIST.md)** - Step-by-step submission checklist
- **[App Store Metadata](docs/APPSTORE_METADATA.md)** - App description, screenshots, and metadata templates
- **[Assets Guide](docs/ASSETS_GUIDE.md)** - App icons and screenshots creation guide
- **[Quick Start](docs/IOS_DEPLOYMENT_QUICKSTART.md)** - Quick reference for deployment

### App Assets (Required Before Deployment!)

**Create App Icons:**
```bash
# 1. Create square icon (1024x1024) → save as assets/images/app_icon_1024.png
# 2. Generate all sizes:
cd flutter
./scripts/generate-app-icons.sh assets/images/app_icon_1024.png
```

**Create Screenshots:**
```bash
# Setup folders and take screenshots for required device sizes
./scripts/setup-screenshots.sh
# See docs/ASSETS_GUIDE.md for detailed instructions
```

See [ASSETS_QUICKREF.txt](ASSETS_QUICKREF.txt) for quick reference.

### Quick Deploy

To build and prepare for App Store submission:

```bash
make archive-ios
```

This automated script will:
1. Clean previous builds
2. Install dependencies
3. Run tests and analyzer
4. Build production IPA
5. Display next steps for upload

The IPA will be created at: `build/ios/ipa/drawback_flutter.ipa`

### Configuration

- **Bundle ID:** `chat.drawback.flutter`
- **App Name:** DrawkcaB
- **Team ID:** QLNTY3GVPQ
- **Minimum iOS:** 13.0