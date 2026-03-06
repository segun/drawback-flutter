# iOS App Store Deployment Guide

This guide covers the complete process for deploying the DrawkcaB Flutter app to the Apple App Store.

## Prerequisites

### Apple Developer Account
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Access to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Development Team ID: `QLNTY3GVPQ` (already configured)

### Development Environment
- [ ] Xcode installed (latest stable version recommended)
- [ ] Flutter SDK installed and configured
- [ ] CocoaPods installed (`sudo gem install cocoapods`)
- [ ] Valid code signing certificates in Keychain
- [ ] Provisioning profiles downloaded in Xcode

---

## Pre-Deployment Checklist

### 1. App Configuration
- [ ] Bundle identifier updated: `chat.drawback.flutter` (not `com.example.*`)
- [ ] App display name: "DrawkcaB"
- [ ] Version number updated in `pubspec.yaml` (e.g., `1.0.0+1`)
  - Format: `major.minor.patch+buildNumber`
  - Increment build number for each TestFlight/App Store submission
- [ ] Backend URL set to production: `https://drawback.chat/api`

### 2. App Store Connect Setup
- [ ] Create new app in [App Store Connect](https://appstoreconnect.apple.com)
  - Bundle ID: `chat.drawback.flutter`
  - App Name: "DrawkcaB"
  - Primary Language: English (U.S.)
  - SKU: `drawback-flutter-ios`
- [ ] App icon uploaded (1024x1024 PNG, no transparency, no alpha channel)
- [ ] Screenshots prepared for required device sizes:
  - iPhone 6.9" (iPhone 16 Pro Max): 1320 x 2868 px
  - iPhone 6.7" (iPhone 14 Pro Max): 1290 x 2796 px
  - iPhone 6.5" (iPhone 11 Pro Max): 1242 x 2688 px
  - iPad Pro 12.9" (6th gen): 2048 x 2732 px (if supporting iPad)
- [ ] App description written (4000 character limit)
- [ ] Keywords selected (100 character limit, comma-separated)
- [ ] Support URL configured
- [ ] Privacy policy URL configured
- [ ] App category selected (Social Networking or Graphics & Design)
- [ ] Content rating questionnaire completed

### 3. Code Signing & Certificates
- [ ] Distribution certificate created in Apple Developer Portal
- [ ] App Store provisioning profile created
- [ ] Certificates and profiles imported in Xcode
- [ ] Automatic signing configured OR manual signing set up properly
- [ ] Verify in Xcode: Runner target → Signing & Capabilities

### 4. Privacy & Permissions
- [ ] Review Info.plist privacy descriptions (already added):
  - `NSUserTrackingUsageDescription` - For analytics (if implemented)
- [ ] Privacy policy hosted and accessible
- [ ] App Privacy details configured in App Store Connect:
  - Data collected: Email, user ID, username, drawings (optional)
  - Data usage: App functionality, product personalization
  - Data linked to user: Yes
  - Third-party tracking: No (unless using analytics)

### 5. Testing
- [ ] All unit tests passing: `make tests`
- [ ] Integration tests passing
- [ ] App tested on physical iOS devices (iPhone and iPad if supporting)
- [ ] Test on minimum supported iOS version (iOS 13.0+)
- [ ] Test core flows:
  - Registration + email confirmation
  - Login + logout
  - Password reset
  - Account deletion
  - Network error handling
- [ ] Test with poor network conditions
- [ ] Test in airplane mode (graceful degradation)

### 6. Performance & Quality
- [ ] No compiler warnings in Xcode
- [ ] Flutter analyzer passes: `flutter analyze`
- [ ] App size optimized (check IPA size after build)
- [ ] Launch time acceptable (< 3 seconds on target device)
- [ ] Memory usage reasonable (check Xcode Instruments)
- [ ] No crashes or hangs during testing

---

## Build & Deployment Process

### Step 1: Clean Build Environment
```bash
cd flutter
make clean-all
make install
```

### Step 2: Run Tests
```bash
make tests
make analyze
```

### Step 3: Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Increment for each release
```

### Step 4: Build Archive
Use the automated script:
```bash
make archive-ios
```

Or manually:
```bash
flutter build ipa \
  --dart-define=BACKEND_URL=https://drawback.chat/api \
  --release \
  --export-options-plist=ios/ExportOptions.plist
```

The IPA file will be created at:
```
build/ios/ipa/drawback_flutter.ipa
```

### Step 5: Validate Archive (Recommended)
Before uploading, validate the IPA:
```bash
xcrun altool --validate-app \
  -f build/ios/ipa/drawback_flutter.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

### Step 6: Upload to App Store Connect

**Option A: Xcode (Recommended for first time)**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Product → Archive
3. When archive completes, Window → Organizer
4. Select your archive → Distribute App
5. Choose "App Store Connect"
6. Follow the wizard to upload

**Option B: Command Line (using App Store Connect API)**
```bash
xcrun altool --upload-app \
  -f build/ios/ipa/drawback_flutter.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

**Option C: Transporter App**
1. Download Transporter from Mac App Store
2. Open the IPA file in Transporter
3. Click "Deliver"

### Step 7: TestFlight (Optional but Recommended)
1. In App Store Connect, go to TestFlight tab
2. Add internal testers (up to 100)
3. Upload build becomes available automatically
4. Add external testers (requires Beta App Review, up to 10,000)
5. Collect feedback and fix issues before production release

### Step 8: Submit for App Review
1. In App Store Connect, go to "App Store" tab
2. Create new version (e.g., 1.0.0)
3. Select the build uploaded from Xcode/CI
4. Fill in "What's New in This Version"
5. Add required screenshots and metadata (if not done already)
6. Fill out Export Compliance Information:
   - Does your app use encryption? **YES** (uses HTTPS)
   - Is it exempt from U.S. encryption regulations? **YES** (standard HTTPS only)
7. Fill out Content Rights information
8. Submit for Review
9. Respond to any questions from Apple Review team promptly

### Step 9: Release
Once approved:
- **Manual Release**: Click "Release This Version" in App Store Connect
- **Automatic Release**: Configure in version settings before submission
- **Scheduled Release**: Set a specific date/time

---

## Post-Release

### Monitoring
- [ ] Monitor crash reports in App Store Connect
- [ ] Check user reviews and respond
- [ ] Monitor analytics (if configured)
- [ ] Watch for performance metrics in App Store Connect

### Updates
For subsequent releases:
1. Increment version in `pubspec.yaml`:
   - Patch update (bug fixes): `1.0.1+2`
   - Minor update (new features): `1.1.0+3`
   - Major update (breaking changes): `2.0.0+4`
2. Run full build process again
3. Submit for review (typically faster for updates)

---

## Common Issues & Solutions

### Issue: "No valid code signing certificates"
**Solution**: 
1. Open Xcode → Settings → Accounts
2. Select your Apple ID → Download Manual Profiles
3. Or use automatic signing in Xcode project settings

### Issue: "Missing compliance documentation"
**Solution**: 
- Answer export compliance questions in App Store Connect
- For standard HTTPS encryption, select "Yes" for use of encryption and "Yes" for exemption

### Issue: "Invalid provisioning profile"
**Solution**:
1. Delete `ios/Pods`, `ios/Podfile.lock`
2. Run `make clean-all && make install`
3. Regenerate provisioning profile in Apple Developer Portal
4. Download in Xcode Settings → Accounts

### Issue: "App rejected for 2.1 Performance - App Completeness"
**Solution**:
- Ensure demo account works (if required)
- All buttons and features must be functional
- Backend must be accessible and stable during review

### Issue: "App rejected for 4.3 Design - Spam"
**Solution**:
- Make your app unique - add distinctive features
- Provide detailed explanation of unique value proposition
- Include detailed description in App Review Notes

### Issue: Build size too large (>200MB)
**Solution**:
```bash
flutter build ipa --split-debug-info=./debug_symbols --obfuscate
```
Archive debug symbols for crash reporting.

---

## App Store Connect API Keys (Optional)

For automated uploads via CI/CD:

1. Generate API key in App Store Connect:
   - Users and Access → Keys tab → App Store Connect API
   - Generate new key with "Developer" role
   - Download .p8 file (only available once!)
   - Note Key ID and Issuer ID

2. Configure API credentials:
```bash
export APP_STORE_CONNECT_API_KEY_ID="YOUR_KEY_ID"
export APP_STORE_CONNECT_API_ISSUER_ID="YOUR_ISSUER_ID"
export APP_STORE_CONNECT_API_KEY_PATH="/path/to/AuthKey_XXXXX.p8"
```

---

## Resources

### Apple Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Flutter Documentation
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Build and release an iOS app](https://docs.flutter.dev/deployment/ios)
- [Obfuscating Dart code](https://docs.flutter.dev/deployment/obfuscate)

### Tools
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)
- [TestFlight](https://developer.apple.com/testflight/)
- [Transporter](https://apps.apple.com/app/transporter/id1450874784)

---

## Quick Reference Commands

```bash
# Clean and reinstall dependencies
make clean-all && make install

# Run tests and analysis
make tests && make analyze

# Build production IPA
make archive-ios

# Open in Xcode for archiving
open ios/Runner.xcworkspace

# Check Flutter doctor
flutter doctor -v

# List connected devices
flutter devices

# Check app size
du -sh build/ios/ipa/drawback_flutter.ipa
```

---

**Last Updated**: March 6, 2026  
**Maintained By**: DrawkcaB Development Team
