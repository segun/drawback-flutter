# API Reference - Subscription Endpoints

Quick reference for exact request/response formats.

---

## POST /purchases/verify

Verify purchase receipt from Flutter app and activate subscription.

### Request from Flutter

```json
{
  "platform": "android",
  "receipt": "abcdefghijklmnop.AO-J1OxYZ123...",
  "productId": "monthly"
}
```

**Field details:**
- `platform`: `"android"` for Android, `"ios"` for iOS
- `receipt`: Purchase token from Google Play (`purchase.verificationData.serverVerificationData`)
- `productId`: Base plan ID - `monthly`, `quarterly`, or `yearly`

**Important:** Flutter sends base plan ID (`monthly`), but backend uses parent subscription ID (`discovery_access`) when calling Google API.

### Response to Flutter

**Success:**
```json
{
  "success": true,
  "subscription": {
    "tier": "monthly",
    "startDate": "2026-03-14T10:30:00.000Z",
    "endDate": "2026-04-14T10:30:00.000Z",
    "autoRenew": true
  }
}
```

**Failure:**
```json
{
  "success": false,
  "error": "Invalid or unpaid subscription",
  "details": "Subscription not found"
}
```

---

## GET /users/me

Get current user profile with subscription status.

### Request

No request body (authenticated via Bearer token in header).

### Response

```json
{
  "id": "user123",
  "email": "user@example.com",
  "displayName": "John Doe",
  "mode": "PUBLIC",
  "appearInSearches": true,
  "appearInDiscoveryGame": true,
  "hasDiscoveryAccess": true,
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": "2026-03-14T10:30:00.000Z",
  "subscription": {
    "tier": "monthly",
    "platform": "android",
    "endDate": "2026-04-14T10:30:00.000Z",
    "autoRenew": true
  }
}
```

**Note:** `hasDiscoveryAccess` is computed on the backend:
```javascript
hasDiscoveryAccess = (now < subscription_end_date) && (status === 'active')
```

**Cross-platform behavior:** The `platform` field indicates where the subscription was purchased (`android`, `ios`, or `mock`), but access is granted on all platforms. A user who subscribes on Android will have `hasDiscoveryAccess: true` when they log in on iOS.

---

## POST /purchases/mock-unlock

Development-only endpoint to simulate subscription without real payment.

### Request

No body required (authenticated route).

### Response

```json
{
  "success": true
}
```

**What it does:** Sets subscription end date to 30 days from now for testing.

**Availability:** Only works when `NODE_ENV === 'development'`

---

## Google Pub/Sub Notification Format

Notifications arrive at your Pub/Sub subscription (via pull or push).

### Notification Structure

```json
{
  "version": "1.0",
  "packageName": "chat.drawback.flutter",
  "eventTimeMillis": "1710412200000",
  "subscriptionNotification": {
    "version": "1.0",
    "notificationType": 2,
    "purchaseToken": "abcdefghijklmnop.AO-J1OxYZ123...",
    "subscriptionId": "discovery_access"
  }
}
```

**Important:** The `subscriptionId` is the **parent subscription ID** (not the base plan ID). To determine which base plan the user purchased (monthly/quarterly/yearly), query the purchase details using the `purchaseToken`.

### Notification Types

| Code | Type | Meaning | Action Required |
|------|------|---------|----------------|
| 1 | SUBSCRIPTION_RECOVERED | Payment recovered after being on hold | Update status to 'active' |
| 2 | SUBSCRIPTION_RENEWED | Auto-renewal succeeded | Update `subscription_end_date` |
| 3 | SUBSCRIPTION_CANCELED | User cancelled subscription | Set `auto_renew = false`, status = 'cancelled' |
| 4 | SUBSCRIPTION_PURCHASED | New subscription | Process same as verify (if not already done) |
| 5 | SUBSCRIPTION_ON_HOLD | Payment failed, retry period | Set status = 'on_hold' |
| 6 | SUBSCRIPTION_IN_GRACE_PERIOD | Payment failed, still has access | Set status = 'grace_period' |
| 7 | SUBSCRIPTION_RESTARTED | User restarted a cancelled sub | Set status = 'active', `auto_renew = true` |
| 10 | SUBSCRIPTION_PRICE_CHANGE_CONFIRMED | User accepted price change | Log, no action needed |
| 12 | SUBSCRIPTION_REVOKED | Refund issued | Set status = 'revoked', remove access immediately |
| 13 | SUBSCRIPTION_EXPIRED | Subscription ended | Set status = 'expired' |

---

## Google Play Developer API Response

When you call `androidPublisher.purchases.subscriptions.get()`:

```json
{
  "kind": "androidpublisher#subscriptionPurchase",
  "startTimeMillis": "1710412200000",
  "expiryTimeMillis": "1713004200000",
  "autoRenewing": true,
  "priceCurrencyCode": "USD",
  "priceAmountMicros": "4990000",
  "countryCode": "US",
  "developerPayload": "",
  "paymentState": 1,
  "cancelReason": 0,
  "userCancellationTimeMillis": null,
  "orderId": "GPA.1234-5678-9012-34567",
  "linkedPurchaseToken": null,
  "purchaseType": 0,
  "acknowledgementState": 1,
  "emailAddress": "user@example.com"
}
```

### Key Fields

- `startTimeMillis`: Subscription start (milliseconds since epoch)
- `expiryTimeMillis`: Subscription end (milliseconds since epoch)
- `autoRenewing`: `true` if will auto-renew, `false` if cancelled
- `paymentState`: 
  - `0` = pending
  - `1` = paid
  - `2` = free trial
  - `3` = pending deferred
- `orderId`: Unique transaction ID (use as `original_transaction_id`)
- `purchaseType`:
  - `0` = test
  - `1` = promo
  - `2` = rewarded

---

## Common Error Responses

### 401 Unauthorized
```json
{
  "error": "No authentication token provided"
}
```

### 400 Bad Request
```json
{
  "error": "Missing required field: receipt"
}
```

### 403 Forbidden
```json
{
  "error": "DISCOVERY_LOCKED",
  "message": "Active subscription required for discovery access",
  "code": "SUBSCRIPTION_REQUIRED"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Verification failed",
  "details": "Unable to connect to Google Play API"
}
```

---

## ID Reference Quick Table

| Context | Use Which ID? | Example Value |
|---------|---------------|---------------|
| **Play Console - Subscription** | Parent ID | `discovery_access` |
| **Play Console - Base Plans** | Base plan IDs | `monthly`, `quarterly`, `yearly` |
| **Flutter - Product IDs** | Base plan IDs | `monthly`, `quarterly`, `yearly` |
| **Flutter → Backend** | Base plan ID | `"productId": "monthly"` |
| **Backend → Google API** | Parent subscription ID | `subscriptionId: "discovery_access"` |
| **Google Notifications** | Parent subscription ID | `"subscriptionId": "discovery_access"` |
| **Database - Tier Column** | Base plan ID | `"monthly"` |

---

## Cross-Platform Subscription Notes

### Platform Independence

Subscriptions are **account-based**, not platform-specific:

- User subscribes on Android → Backend stores subscription with `platform: 'android'`
- User logs in on iOS → Backend returns `hasDiscoveryAccess: true`
- ✅ Access works seamlessly across all platforms

### Subscription Management

Users must manage subscriptions through the platform where they purchased:

```json
{
  "subscription": {
    "platform": "android"  // User must use Google Play Store to manage
  }
}
```

**Display in UI:**
- Android: "Manage in Google Play Store"
- iOS: "Manage in App Store"
- Mock: "Test Subscription (Development)"

### Restore Purchases Behavior

When a user taps "Restore Purchases":

1. Flutter calls platform-specific restore (`restorePurchases()`)
2. Platform returns any purchases made on **that platform**
3. App refreshes user profile from backend
4. Backend returns `hasDiscoveryAccess` based on **any platform's** subscription
5. UI shows appropriate message:
   - If has access: "Your subscription is active"
   - If no access: "No subscription found"

**Important:** Don't reveal in the iOS app that a user has an Android subscription (App Store guideline compliance).

---

## Environment Variables Reference

### Backend Required Variables

```bash
# Google Play (Android)
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_PUBSUB_SUBSCRIPTION=play-subscriptions-pull
GOOGLE_PACKAGE_NAME=chat.drawback.flutter
GOOGLE_SUBSCRIPTION_ID=discovery_access

# Apple App Store (iOS) - if implementing
APPLE_SHARED_SECRET=your-app-store-shared-secret
```

---

## Database Schema Reference

```sql
-- User subscription fields
subscription_platform        VARCHAR(20)   -- 'android', 'ios', 'mock'
subscription_tier           VARCHAR(20)   -- 'monthly', 'quarterly', 'yearly'
subscription_status         VARCHAR(20)   -- 'active', 'cancelled', 'expired', 'grace_period', 'revoked'
subscription_start_date     TIMESTAMP
subscription_end_date       TIMESTAMP
subscription_auto_renew     BOOLEAN
original_transaction_id     VARCHAR(255)  -- Google orderId or Apple originalTransactionId
purchase_token              TEXT          -- Google purchase token (for Android)
```

---

## Quick Implementation Checklist

### Flutter Side
- [ ] Product IDs use base plan IDs: `monthly`, `quarterly`, `yearly`
- [ ] Send `productId` to backend in verify request
- [ ] Handle purchase success/failure states
- [ ] Implement restore purchases flow

### Backend Side
- [ ] Use parent subscription ID (`discovery_access`) in Google API calls
- [ ] Store base plan ID (`monthly`, etc.) in database tier field
- [ ] Compute `hasDiscoveryAccess` dynamically from `subscription_end_date`
- [ ] Set up Pub/Sub listener for real-time notifications
- [ ] Handle all notification types (renewed, cancelled, expired, etc.)

### Google Cloud Side
- [ ] Enable Google Play Developer API
- [ ] Create service account with proper permissions
- [ ] Configure Pub/Sub topic and subscription
- [ ] Grant Play Console access to service account
- [ ] Configure RTDN in Play Console

---

## Support Links

- [Google Play Billing Documentation](https://developer.android.com/google/play/billing/subscriptions)
- [Google Play Developer API Reference](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs/pull)
- [Real-time Developer Notifications](https://developer.android.com/google/play/billing/rtdn-reference)
