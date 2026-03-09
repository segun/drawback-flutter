# Plan: Discovery Game Paywall with Purchase & Ad Options

## Overview

Implement a feature-gated Discovery Game with two unlock options:
1. **Permanent unlock** — One-time in-app purchase
2. **Temporary unlock** — Watch a rewarded ad for 5 minutes of access

Development uses mock purchases/ads for testing before wiring up real App Store / Play Store / AdMob.

---

## Access Model

| Access Type | Duration | Implementation |
|-------------|----------|----------------|
| **Purchased** | Forever | Backend stores `hasDiscoveryAccess: true` |
| **Ad-based** | 5 minutes | Client stores `discoveryAccessExpiry` timestamp |

Ad-based access is client-side only (simpler, acceptable for short windows).

---

## Backend Tasks

### 1. Add subscription field to user model
- Add `hasDiscoveryAccess: boolean` (default: `false`) to user schema
- Include field in `/users/me` response

### 2. Create mock unlock endpoint (development only)
- `POST /purchases/mock-unlock` → sets `hasDiscoveryAccess = true` for authenticated user
- Guard with environment check (disable in production)

### 3. Create receipt verification endpoint (for later)
- `POST /purchases/verify`
- Accepts `{ platform: 'ios' | 'android', receipt: string }`
- Placeholder that just returns success for now

### 4. Protect discovery endpoints
- Check `hasDiscoveryAccess` on `/discovery/random` and related endpoints
- Return `403 Forbidden` with `{ error: 'DISCOVERY_LOCKED', message: 'Discovery requires premium access' }` if false
- **Note:** Backend does NOT validate ad-based temporary access — client-side honor system

---

## Frontend (Flutter) Tasks

### 1. Create purchase service
**File:** `lib/core/services/purchase_service.dart`

```dart
class PurchaseService {
  static const bool _useMockPurchases = true; // Toggle for dev
  
  Future<bool> hasDiscoveryAccess() async {
    // Check from user profile or cached value
  }
  
  Future<bool> purchaseDiscovery() async {
    if (_useMockPurchases) {
      // Call mock endpoint
      await api.post('/purchases/mock-unlock');
      return true;
    }
    // Real IAP code (Phase 2)
  }
  
  Future<void> restorePurchases() async {
    // For real IAP - restores previous purchases
  }
}
```

### 2. Create ad service
**File:** `lib/core/services/ad_service.dart`

```dart
class AdService {
  static const bool _useMockAds = true; // Toggle for dev
  static const int tempAccessMinutes = 5;
  
  RewardedAd? _rewardedAd;
  
  // Test ad unit IDs (always work, no AdMob account needed)
  static String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'  // Android test
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS test
  
  /// Pre-load ad (call early so it's ready)
  Future<void> loadRewardedAd() async {
    if (_useMockAds) return;
    
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => debugPrint('Ad failed: $error'),
      ),
    );
  }
  
  /// Show rewarded ad, returns true if user earned reward
  Future<bool> showRewardedAdForAccess() async {
    if (_useMockAds) {
      // Simulate watching ad
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }
    
    if (_rewardedAd == null) return false;
    
    final completer = Completer<bool>();
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd(); // Pre-load next
      },
    );
    
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        completer.complete(true);
      },
    );
    
    _rewardedAd = null;
    return completer.future;
  }
}
```

### 3. Create discovery access manager
**File:** `lib/core/services/discovery_access_manager.dart`

```dart
class DiscoveryAccessManager {
  final PurchaseService _purchaseService;
  final AdService _adService;
  
  DateTime? _tempAccessExpiry;
  
  /// Check if user has any form of access
  bool hasAccess(bool hasPermanentAccess) {
    // Permanent purchase takes priority
    if (hasPermanentAccess) return true;
    
    // Check temporary ad-based access
    if (_tempAccessExpiry != null) {
      if (DateTime.now().isBefore(_tempAccessExpiry!)) {
        return true;
      }
      _tempAccessExpiry = null; // Expired
    }
    
    return false;
  }
  
  /// Grant temporary access after watching ad
  void grantTemporaryAccess() {
    _tempAccessExpiry = DateTime.now().add(
      Duration(minutes: AdService.tempAccessMinutes),
    );
  }
  
  /// Time remaining for temporary access
  Duration? get remainingTime {
    if (_tempAccessExpiry == null) return null;
    final remaining = _tempAccessExpiry!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}
```

### 4. Update user model
**File:** `lib/features/home/domain/home_models.dart` (or wherever user model lives)

- Add `hasDiscoveryAccess` field to user model
- Parse from `/users/me` response

### 5. Create paywall/upgrade screen
**File:** `lib/features/discovery/presentation/screens/discovery_paywall_screen.dart`

UI with two options:
```
┌─────────────────────────────────────────────────────────────┐
│               🎨 Unlock Discovery Game                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Find random users and start drawing together!              │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  💎  Unlock Forever — $2.99                         │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  📺  Watch Ad — 5 min access                        │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   Already purchased? Restore Purchases                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 6. Gate discovery screen access
**File:** Update `lib/features/discovery/presentation/screens/discovery_swipe_screen.dart` parent

- Check `discoveryAccessManager.hasAccess(user.hasDiscoveryAccess)` before navigating
- If false → show `DiscoveryPaywallScreen` instead

### 7. Show remaining time indicator
When user has temporary access, show countdown in discovery screen header:
```dart
Text('⏱️ ${remainingTime.inMinutes}:${remainingTime.inSeconds % 60}')
```

### 8. Handle access expiry during use
- Check remaining time periodically while in discovery
- When expired, show prompt: "Time's up! Watch another ad or unlock forever"

---

## File Structure (New Files)

```
lib/
  core/
    services/
      purchase_service.dart           # NEW - handles IAP logic
      ad_service.dart                 # NEW - handles rewarded ads
      discovery_access_manager.dart   # NEW - combines purchase + ad access
  features/
    discovery/
      presentation/
        screens/
          discovery_paywall_screen.dart  # NEW - upgrade/paywall UI
        widgets/
          access_timer_widget.dart       # NEW - countdown for temp access
```

---

## Dependencies

```yaml
# pubspec.yaml (Phase 2 - real implementation)
dependencies:
  in_app_purchase: ^3.1.0       # For real IAP
  google_mobile_ads: ^5.1.0     # For rewarded ads
```

---

## Testing Checklist

### Paywall UI
- [ ] User without access sees paywall when tapping Discovery
- [ ] Paywall shows both "Unlock Forever" and "Watch Ad" options
- [ ] "Restore Purchases" link is visible

### Purchase Flow (Mock)
- [ ] "Unlock Forever" button calls mock endpoint successfully
- [ ] User profile refreshes with `hasDiscoveryAccess: true`
- [ ] User with permanent access goes directly to Discovery Swipe
- [ ] 403 from backend shows appropriate error/upgrade prompt

### Ad Flow (Mock)
- [ ] "Watch Ad" button shows loading state
- [ ] After mock ad completes, user gets access to Discovery
- [ ] Timer shows remaining access time (e.g., "4:32 remaining")
- [ ] Timer counts down in real-time
- [ ] When timer expires, user is prompted to watch another ad or purchase
- [ ] User can watch multiple ads in a session

### Edge Cases
- [ ] App backgrounded during temp access — timer continues correctly
- [ ] User with permanent access never sees timer
- [ ] Ad fails to load — show error message, don't grant access

---

## Phase 2: Real In-App Purchases (After Store Setup)

1. Set `_useMockPurchases = false` in `PurchaseService`
2. Add `in_app_purchase` package to pubspec.yaml
3. Configure products in App Store Connect / Play Console
4. Implement real receipt verification on backend
5. Set up webhooks for subscription events
6. Remove/disable mock endpoint in production

---

## Phase 3: Real Ads (After AdMob Setup)

### AdMob Account Setup
1. Create account at [admob.google.com](https://admob.google.com)
2. Add iOS app → get App ID
3. Add Android app → get App ID
4. Create Rewarded Video ad unit for each platform → get Ad Unit IDs

### iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxx~yyyyyyyy</string>
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
  <!-- Add more SKAdNetwork IDs as needed -->
</array>
```

### Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxx~yyyyyyyy"/>
```

### Code Changes
1. Set `_useMockAds = false` in `AdService`
2. Replace test ad unit IDs with real ones
3. Add `google_mobile_ads` to pubspec.yaml
4. Initialize MobileAds in `main.dart`:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await MobileAds.instance.initialize();
     runApp(MyApp());
   }
   ```

---

## Notes

- Keep mock mode toggles easy to find for switching between dev/prod
- Consider adding admin ability to grant access (for support cases)
- Log all purchase/ad attempts for debugging
- AdMob test ads work on both simulator and device without account setup
- Real ads require physical device testing (simulators show test ads only)
- Consider rate-limiting ad watches (e.g., max 10 per day) to prevent abuse
- Track ad revenue vs purchase revenue to optimize pricing
