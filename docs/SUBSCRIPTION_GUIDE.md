# Subscription Implementation Guide

Complete guide for implementing Android and iOS subscriptions with backend verification.

---

## Table of Contents

1. [Cross-Platform Subscription Behavior](#cross-platform-subscription-behavior)
2. [Understanding Google Play's Subscription Model](#understanding-google-plays-subscription-model)
3. [Google Play Console Setup](#google-play-console-setup)
4. [Backend Implementation](#backend-implementation)
5. [Flutter Integration](#flutter-integration)
6. [Testing](#testing)
7. [Production Checklist](#production-checklist)

---

## Cross-Platform Subscription Behavior

### How It Works

Subscriptions in this app are **account-based**, not platform-based:

- ✅ User subscribes on **Android** → Has access on **iOS**, **Web**, etc.
- ✅ User subscribes on **iOS** → Has access on **Android**, **Web**, etc.
- ✅ Revenue goes to whichever platform they subscribed on
- ✅ Access works on all devices where user is logged in

This follows the pattern used by major apps like **Spotify**, **Netflix**, **YouTube Premium**, and **Disney+**.

### Subscription Management

Users must manage their subscriptions through the platform they subscribed on:

| Subscribed On | Manage Via |
|---------------|------------|
| Android | Google Play Store settings |
| iOS | App Store settings |
| Web (future) | Website account settings |

**Important:** Users cannot cancel an Android subscription from the iOS app, and vice versa. The app must direct them to the appropriate platform's settings.

### Backend Implementation

The backend doesn't restrict access by platform. The `hasDiscoveryAccess` field is computed from `subscription_end_date` regardless of `subscription_platform`:

```javascript
const hasDiscoveryAccess = 
  user.subscription_end_date && 
  now < user.subscription_end_date && 
  user.subscription_status === 'active';
// Note: No check for subscription_platform
```

This provides the best user experience and avoids forcing users to pay twice if they switch devices.

### Revenue Attribution

- User pays $4.99 on Android → Google takes 15-30%, you receive the rest
- User uses app on iOS with same account → Apple gets nothing
- This is standard practice and complies with both stores' policies
- Apple/Google cannot prevent this as the subscription was legitimately purchased through their platform

### App Store Compliance

**✅ Allowed:**
- User subscribes on Android, uses subscription on iOS ✓
- Show subscription status from other platform ✓
- Direct users to platform-specific settings to manage subscription ✓
- Show "Subscribed via [Platform]" information ✓

**❌ Not Allowed (violates App Store guidelines):**
- Showing Android pricing in iOS app to encourage cheaper purchase
- Direct links to subscribe outside the app
- Telling iOS users "subscribe on Android to save money"
- Bypassing the in-app purchase system for new subscriptions

### UX Recommendations

**1. Show where subscription was purchased:**
```dart
Widget _buildSubscriptionInfo(Subscription sub) {
  return Column(
    children: [
      Text('✓ Discovery Access Active'),
      Text('Subscribed via: ${sub.platformDisplayName}'),
      Text('To manage, use ${sub.platformDisplayName} settings'),
    ],
  );
}
```

**2. Handle "Restore Purchases" gracefully:**
```dart
// When user taps "Restore Purchases" on iOS but has Android subscription
await restorePurchases(); // Tries iOS restore
await refreshUserProfile(); // Gets subscription from backend (any platform)

if (user.hasDiscoveryAccess) {
  showMessage('Your subscription is active'); // Don't reveal platform
}
```

**3. Clear communication on paywall:**
```
┌────────────────────────────────────────┐
│  💎 Discovery Access                   │
│                                        │
│  ✓ Works on all your devices          │
│  ✓ Subscribe once, use everywhere     │
└────────────────────────────────────────┘
```

---

## Understanding Google Play's Subscription Model

### The Confusion Explained

Google changed their subscription model in 2022, and it's NOT like iOS. This causes massive confusion.

**Structure you create in Play Console:**

```
📦 Subscription (Parent)
   └─ ID: discovery_access
   └─ Name: "Discovery Access"
   
   ├─ 📋 Base Plan: Monthly
   │    └─ ID: monthly
   │    └─ Period: 1 month
   │    └─ Price: $4.99
   │
   ├─ 📋 Base Plan: Quarterly
   │    └─ ID: quarterly
   │    └─ Period: 3 months
   │    └─ Price: $11.99
   │
   └─ 📋 Base Plan: Yearly
        └─ ID: yearly
        └─ Period: 12 months
        └─ Price: $39.99
```

**You create:**
- 1 subscription with ID `discovery_access`
- 3 base plans inside it with IDs: `monthly`, `quarterly`, `yearly`

### Which ID Goes Where?

| Context | Which ID? | Example |
|---------|-----------|---------|
| Flutter `queryProductDetails()` | Base plan IDs | `monthly`, `quarterly`, `yearly` |
| Flutter `buyNonConsumable()` | Base plan ID | `monthly` |
| Flutter → Backend request | Base plan ID | `"productId": "monthly"` |
| Backend → Google API | Parent subscription ID | `subscriptionId: "discovery_access"` |
| Google → Backend webhook | Parent subscription ID | `"subscriptionId": "discovery_access"` |
| Database storage (tier) | Base plan ID | `subscription_tier: "monthly"` |

### Common Mistakes

❌ **Wrong: Using base plan ID in Google API**
```javascript
await androidPublisher.purchases.subscriptions.get({
  subscriptionId: 'monthly',  // ❌ Base plan ID won't work
  token: purchaseToken,
});
```

✅ **Correct: Using parent ID in Google API**
```javascript
await androidPublisher.purchases.subscriptions.get({
  subscriptionId: 'discovery_access',  // ✅ Parent subscription ID
  token: purchaseToken,
});
```

---

## Google Play Console Setup

### Step 1: Create Your App in Play Console

1. Go to https://play.google.com/console
2. Create app if not exists → Enter app details
3. Note your **Package Name**: Should match your app's applicationId in `android/app/build.gradle.kts`
   - For this app: `chat.drawback.flutter`

### Step 2: Upload Initial APK (REQUIRED Before Creating Subscriptions)

**Why required:** Google needs to scan your APK to verify the billing library is integrated before allowing you to create subscriptions.

#### Build and Upload

1. **Ensure billing dependency exists in pubspec.yaml:**
   ```yaml
   dependencies:
     in_app_purchase: ^3.2.3
   ```

2. **Build signed release APK:**
   ```bash
   flutter build apk --release
   ```
   
   **Or build App Bundle (recommended):**
   ```bash
   flutter build appbundle --release
   ```

3. **Upload to Play Console:**
   - Go to Play Console → **Testing** → **Internal testing**
   - Click **Create new release**
   - Upload your APK or AAB file
   - Fill in release notes (can be anything: "Initial billing setup")
   - Click **Review release** → **Start rollout to Internal testing**

4. **Wait 5-10 minutes** for Google to process the APK

**Troubleshooting:**
- **Build fails**: Make sure `in_app_purchase: ^3.2.3` is in pubspec.yaml and run `flutter pub get`
- **Can't see subscription option after upload**: Wait 10-15 minutes, then refresh the page
- **"Billing library not detected"**: Ensure you uploaded a release build (not debug), and that `in_app_purchase` package is in dependencies

### Step 3: Create Subscription Products

1. **Navigate:** Play Console → Your App → **Monetize** → **Subscriptions**
2. Click **Create subscription**

3. **Configure the subscription:**
   - **Subscription ID:** `discovery_access` (the parent container)
   - **Name:** Discovery Access
   - **Description:** Get access to discovery game features

4. **Add Base Plans** (these are your monthly/quarterly/yearly tiers):

Click **Add base plan** for each tier:

**Base Plan 1: Monthly**
- **Base plan ID:** `monthly`
- **Billing period:** 1 month
- **Price:** $4.99 USD
- **Auto-renewal:** Yes

**Base Plan 2: Quarterly**
- **Base plan ID:** `quarterly`
- **Billing period:** 3 months
- **Price:** $11.99 USD
- **Auto-renewal:** Yes

**Base Plan 3: Yearly**
- **Base plan ID:** `yearly`
- **Billing period:** 12 months
- **Price:** $39.99 USD
- **Auto-renewal:** Yes

5. **Optional: Add free trial offer** to each base plan (7 days recommended)
6. **Save and activate** the subscription

### Step 4: Verify Flutter Code Product IDs

Open `lib/core/services/purchase_service.dart` and verify the product IDs match:

```dart
/// Base product IDs (same across iOS and Android)
static const String monthlyProductId = 'monthly';
static const String quarterlyProductId = 'quarterly';
static const String yearlyProductId = 'yearly';
```

**Note:** The app uses the same product IDs across both platforms. Make sure your base plan IDs in Google Play Console match these exactly.

### Step 5: Set Up Google Cloud Project & Service Account

**Why needed:** Backend needs API access to verify purchases

1. **Go to Google Cloud Console:** https://console.cloud.google.com
2. **Select project** linked to your Play Console (or create new one)
3. **Enable Google Play Developer API:**
   - Search "Google Play Android Developer API"
   - Click **Enable**

4. **Create Service Account:**
   - Navigate: **IAM & Admin** → **Service Accounts**
   - Click **Create Service Account**
   - Name: `play-store-verifier`
   - Click **Create and Continue**
   - Skip role assignment for now → **Done**

5. **Create JSON Key:**
   - Click on the service account you just created
   - Go to **Keys** tab
   - Click **Add Key** → **Create new key**
   - Select **JSON**
   - Click **Create** (file downloads automatically)
   - **SAVE THIS FILE** - you'll upload it to your backend server

6. **Grant Play Console Access:**
   - Go back to **Play Console**
   - Navigate: **Users and permissions** → **Invite new users**
   - Enter the service account email (looks like `play-store-verifier@your-project.iam.gserviceaccount.com`)
   - **Permissions:** Check "View financial data" and "Manage orders and subscriptions"
   - Click **Invite user**

### Step 6: Set Up Real-time Developer Notifications (RTDN)

**Why needed:** Get notified when subscriptions renew, cancel, etc.

1. **Create Pub/Sub Topic:**
   - Go to **Google Cloud Console**
   - Navigate: **Pub/Sub** → **Topics**
   - Click **Create Topic**
   - Topic ID: `play-subscriptions`
   - Click **Create**

2. **Grant Google Play Publishing Rights:**
   - Click on the topic you just created
   - Go to **Permissions** tab
   - Click **Add Principal**
   - Principal: `google-play-developer-notifications@system.gserviceaccount.com`
   - Role: **Pub/Sub Publisher**
   - Click **Save**

3. **Create Pub/Sub Subscription (Pull):**
   - Navigate: **Pub/Sub** → **Subscriptions**
   - Click **Create Subscription**
   - Subscription ID: `play-subscriptions-pull`
   - Select topic: `play-subscriptions`
   - Delivery type: **Pull**
   - Click **Create**

4. **Configure in Play Console:**
   - Go to **Play Console** → Your App
   - Navigate: **Monetization setup**
   - Find **Real-time developer notifications**
   - Topic name: Enter full path: `projects/YOUR_PROJECT_ID/topics/play-subscriptions`
     - Replace `YOUR_PROJECT_ID` with your actual Google Cloud project ID
   - Click **Save**

---

## Backend Implementation

### Required Environment Variables

Add these to your backend:

```bash
# Google Play
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_PUBSUB_SUBSCRIPTION=play-subscriptions-pull
GOOGLE_PACKAGE_NAME=chat.drawback.flutter
GOOGLE_SUBSCRIPTION_ID=discovery_access  # Parent subscription ID

# Apple (if implementing iOS)
APPLE_SHARED_SECRET=your-app-store-shared-secret
```

### Install Dependencies

**Node.js:**
```bash
npm install @google-cloud/pubsub googleapis
```

**Python:**
```bash
pip install google-cloud-pubsub google-auth google-api-python-client
```

### Database Schema

Add these fields to your User model:

```sql
-- PostgreSQL example
ALTER TABLE users ADD COLUMN subscription_platform VARCHAR(20);
ALTER TABLE users ADD COLUMN subscription_tier VARCHAR(20);
ALTER TABLE users ADD COLUMN subscription_status VARCHAR(20);
ALTER TABLE users ADD COLUMN subscription_start_date TIMESTAMP;
ALTER TABLE users ADD COLUMN subscription_end_date TIMESTAMP;
ALTER TABLE users ADD COLUMN subscription_auto_renew BOOLEAN;
ALTER TABLE users ADD COLUMN original_transaction_id VARCHAR(255);
ALTER TABLE users ADD COLUMN purchase_token TEXT;

-- Add index for performance
CREATE INDEX idx_users_subscription_end ON users(subscription_end_date);
```

### Endpoint 1: POST /purchases/verify

**Purpose:** Verify purchase receipt from Flutter app and activate subscription

**Request:**
```json
{
  "platform": "android",
  "receipt": "purchase_token...",
  "productId": "monthly"
}
```

**Implementation (Node.js):**

```javascript
const { google } = require('googleapis');

app.post('/purchases/verify', authenticateUser, async (req, res) => {
  const { platform, receipt, productId } = req.body;
  const userId = req.user.id;

  if (platform !== 'android') {
    return res.status(400).json({ error: 'Only android supported' });
  }

  try {
    // 1. Initialize Google Play API client
    const auth = new google.auth.GoogleAuth({
      keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const androidPublisher = google.androidpublisher({
      version: 'v3',
      auth: await auth.getClient(),
    });

    // 2. Use parent subscription ID (not base plan ID)
    const subscriptionId = process.env.GOOGLE_SUBSCRIPTION_ID;

    // 3. Verify the purchase with Google
    const result = await androidPublisher.purchases.subscriptions.get({
      packageName: process.env.GOOGLE_PACKAGE_NAME,
      subscriptionId: subscriptionId,
      token: receipt,
    });

    const subscription = result.data;

    // 4. Check if subscription is valid
    if (!subscription || subscription.paymentState !== 1) {
      return res.status(400).json({ 
        success: false, 
        error: 'Invalid or unpaid subscription' 
      });
    }

    // 5. Extract subscription details
    const startTime = new Date(parseInt(subscription.startTimeMillis));
    const endTime = new Date(parseInt(subscription.expiryTimeMillis));
    const isAutoRenewing = subscription.autoRenewing === true;
    const tier = productId; // Base plan ID from Flutter

    // 6. Update user in database
    await db.query(`
      UPDATE users 
      SET 
        subscription_platform = 'android',
        subscription_tier = $1,
        subscription_status = 'active',
        subscription_start_date = $2,
        subscription_end_date = $3,
        subscription_auto_renew = $4,
        original_transaction_id = $5,
        purchase_token = $6
      WHERE id = $7
    `, [tier, startTime, endTime, isAutoRenewing, subscription.orderId, receipt, userId]);

    // 7. Return success
    res.json({
      success: true,
      subscription: {
        tier,
        startDate: startTime.toISOString(),
        endDate: endTime.toISOString(),
        autoRenew: isAutoRenewing,
      },
    });

  } catch (error) {
    console.error('Purchase verification failed:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Verification failed',
      details: error.message 
    });
  }
});
```

### Endpoint 2: GET /users/me (Update existing)

Add computed `hasDiscoveryAccess` field:

```javascript
app.get('/users/me', authenticateUser, async (req, res) => {
  const user = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
  
  // Compute hasDiscoveryAccess
  const now = new Date();
  const hasDiscoveryAccess = 
    user.subscription_end_date && 
    now < user.subscription_end_date && 
    user.subscription_status === 'active';

  res.json({
    id: user.id,
    email: user.email,
    displayName: user.display_name,
    hasDiscoveryAccess,
    subscription: user.subscription_end_date ? {
      tier: user.subscription_tier,
      endDate: user.subscription_end_date,
      autoRenew: user.subscription_auto_renew,
    } : null,
  });
});
```

### Endpoint 3: Real-time Notifications (Background Worker)

**Create a background worker to listen to Pub/Sub:**

```javascript
const { PubSub } = require('@google-cloud/pubsub');
const { google } = require('googleapis');

async function listenForSubscriptionEvents() {
  const pubsub = new PubSub({
    projectId: process.env.GOOGLE_CLOUD_PROJECT_ID,
    keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS,
  });

  const subscription = pubsub.subscription(process.env.GOOGLE_PUBSUB_SUBSCRIPTION);

  subscription.on('message', async (message) => {
    try {
      const data = JSON.parse(message.data.toString());
      console.log('Received notification:', data);

      if (data.subscriptionNotification) {
        await handleSubscriptionNotification(data.subscriptionNotification);
      }

      message.ack();
    } catch (error) {
      console.error('Error processing notification:', error);
      message.nack();
    }
  });

  console.log('Listening for subscription notifications...');
}

async function handleSubscriptionNotification(notification) {
  const { notificationType, purchaseToken, subscriptionId } = notification;

  // Find user with this purchase token
  const user = await db.query(
    'SELECT * FROM users WHERE purchase_token = $1',
    [purchaseToken]
  );

  if (!user) {
    console.error('User not found for token:', purchaseToken);
    return;
  }

  switch (notificationType) {
    case 2: // SUBSCRIPTION_RENEWED
      // Fetch updated subscription info
      const auth = new google.auth.GoogleAuth({
        keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
      });
      
      const androidPublisher = google.androidpublisher({
        version: 'v3',
        auth: await auth.getClient(),
      });

      const result = await androidPublisher.purchases.subscriptions.get({
        packageName: process.env.GOOGLE_PACKAGE_NAME,
        subscriptionId: subscriptionId,
        token: purchaseToken,
      });

      const newEndTime = new Date(parseInt(result.data.expiryTimeMillis));

      await db.query(
        'UPDATE users SET subscription_end_date = $1, subscription_status = $2 WHERE id = $3',
        [newEndTime, 'active', user.id]
      );
      console.log(`Subscription renewed for user ${user.id} until ${newEndTime}`);
      break;

    case 3: // SUBSCRIPTION_CANCELED
      await db.query(
        'UPDATE users SET subscription_status = $1, subscription_auto_renew = $2 WHERE id = $3',
        ['cancelled', false, user.id]
      );
      console.log(`Subscription cancelled for user ${user.id}`);
      break;

    case 13: // SUBSCRIPTION_EXPIRED
      await db.query(
        'UPDATE users SET subscription_status = $1 WHERE id = $2',
        ['expired', user.id]
      );
      console.log(`Subscription expired for user ${user.id}`);
      break;

    case 6: // SUBSCRIPTION_IN_GRACE_PERIOD
      await db.query(
        'UPDATE users SET subscription_status = $1 WHERE id = $2',
        ['grace_period', user.id]
      );
      console.log(`Subscription in grace period for user ${user.id}`);
      break;

    case 12: // SUBSCRIPTION_REVOKED (refund)
      await db.query(
        'UPDATE users SET subscription_status = $1 WHERE id = $2',
        ['revoked', user.id]
      );
      console.log(`Subscription revoked for user ${user.id}`);
      break;

    default:
      console.log(`Unhandled notification type: ${notificationType}`);
  }
}

// Start the listener
listenForSubscriptionEvents();
```

**Start the worker:**
```bash
node subscription-worker.js
# Or add to your process manager (PM2, systemd, etc.)
```

### Endpoint 4: POST /purchases/mock-unlock (Development Only)

For testing without real payments:

```javascript
app.post('/purchases/mock-unlock', authenticateUser, async (req, res) => {
  // Only available in development
  if (process.env.NODE_ENV !== 'development') {
    return res.status(404).json({ error: 'Not found' });
  }

  const userId = req.user.id;
  const now = new Date();
  const endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30 days

  await db.query(`
    UPDATE users 
    SET 
      subscription_platform = 'mock',
      subscription_tier = 'monthly',
      subscription_status = 'active',
      subscription_start_date = $1,
      subscription_end_date = $2,
      subscription_auto_renew = false
    WHERE id = $3
  `, [now, endDate, userId]);

  res.json({ success: true });
});
```

---

## Flutter Integration

### Update purchase_service.dart

Ensure the purchase flow sends the token to backend:

```dart
Future<bool> _completePurchase(String productId) async {
  subscription = _inAppPurchase.purchaseStream.listen(
    (List<PurchaseDetails> purchases) async {
      for (final PurchaseDetails purchase in purchases) {
        if (purchase.productID != productId) continue;
        if (purchase.status == PurchaseStatus.pending) continue;

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          
          // Verify with backend
          final bool verified = await verifyReceipt(
            platform: 'android',
            receipt: purchase.verificationData.serverVerificationData,
            productId: productId,
          );
          
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(verified);
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    },
  );
  
  // ... rest of the code
}
```

### Update verifyReceipt method

```dart
Future<bool> verifyReceipt({
  required String platform,
  required String receipt,
  required String productId,
}) async {
  try {
    final Map<String, dynamic> response = await _client.postJson(
      '/purchases/verify',
      body: <String, dynamic>{
        'platform': platform,
        'receipt': receipt,
        'productId': productId,
      },
      headers: await _authHeaders(),
    );
    return response['success'] == true;
  } catch (e) {
    debugPrint('Receipt verification failed: $e');
    return false;
  }
}
```

---

## Testing

### Test with Google Play Internal Testing

1. **Upload to Internal Testing:**
   - Build: `flutter build appbundle --release`
   - Upload to Play Console → **Testing** → **Internal testing**
   - Create release → Upload AAB

2. **Add Test Users:**
   - Go to **Testing** → **License testing**
   - Add test Gmail accounts
   - These accounts get instant approval and can make test purchases

3. **Enable Test Subscriptions:**
   - Test subscriptions renew much faster (monthly = 5 minutes)
   - Useful for testing renewal webhooks

4. **Install App:**
   - Share internal testing link with test account
   - Install from link (NOT from local APK)
   - Must install from Play Store for subscriptions to work

5. **Make Test Purchase:**
   - Open app → Go to paywall
   - Select subscription tier
   - Complete purchase (test cards work)
   - Verify backend receives webhook notification

### Verification Checklist

- [ ] User can see subscription tiers with correct prices
- [ ] Selecting tier initiates purchase flow
- [ ] Google Play billing dialog appears
- [ ] After purchase, `/purchases/verify` is called
- [ ] Backend successfully verifies with Google API
- [ ] User record updated with subscription dates
- [ ] `/users/me` returns `hasDiscoveryAccess: true`
- [ ] User can access discovery game
- [ ] Pub/Sub receives notification (check logs)
- [ ] Subscription worker processes notification
- [ ] Test subscription auto-renews after 5 minutes
- [ ] User's `subscription_end_date` updates after renewal
- [ ] User can cancel subscription
- [ ] Status changes to `cancelled`, access persists until end date
- [ ] After expiration, `hasDiscoveryAccess` becomes `false`

---

## Production Checklist

Before launching:

- [ ] Switch all product IDs from test to production
- [ ] Remove/disable mock purchase endpoint
- [ ] Set up monitoring for subscription worker
- [ ] Set up alerts for failed verifications
- [ ] Configure automatic database backups
- [ ] Test with real payment method
- [ ] Test refund handling
- [ ] Add proper error messages in app
- [ ] Add subscription management UI (view/cancel)
- [ ] Test on multiple Android devices/versions
- [ ] Load test backend verification endpoint
- [ ] Set up logging for all purchases
- [ ] Document customer support procedures
- [ ] Verify webhook worker has auto-restart on crash

---

## Common Issues & Solutions

### "Product not found" in app
- **Cause:** App not installed from Play Store
- **Fix:** Must install via Internal Testing link, not local APK

### "Purchase verification failed"
- **Cause:** Service account doesn't have permissions
- **Fix:** Check Play Console → Users and permissions → Grant "View financial data"

### "No webhooks received"
- **Cause:** Pub/Sub not configured correctly
- **Fix:** Verify topic name in Play Console exactly matches your topic

### Subscription doesn't renew
- **Cause:** Worker not running
- **Fix:** Check if subscription-worker.js is running, check logs

### Backend can't verify purchase
- **Cause:** API not enabled or credentials wrong
- **Fix:** Enable "Google Play Android Developer API" in Google Cloud Console

---

## Quick Reference: Where Things Are

| Task | Location |
|------|----------|
| Create subscriptions | Play Console → Monetize → Subscriptions |
| Enable API | Google Cloud Console → APIs & Services → Library |
| Service account | Google Cloud Console → IAM & Admin → Service Accounts |
| Grant Play access | Play Console → Users and permissions |
| Pub/Sub topic | Google Cloud Console → Pub/Sub → Topics |
| RTDN setup | Play Console → Monetization setup |
| Upload app | Play Console → Testing → Internal testing |
| Add test users | Play Console → Testing → License testing |

---

## Support

**Google Play documentation:**
- https://developer.android.com/google/play/billing/subscriptions
- https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions

**Pub/Sub documentation:**
- https://cloud.google.com/pubsub/docs/pull
