# Flutter Bug Fix Implementation Plan

> Generated: March 5, 2026

---

## Overview

Fix 16 verified bugs across crash prevention, memory leaks, broken features, UX issues, and code quality. Bug #1 (RadioGroup) was a false positive and is skipped - the code compiles successfully.

**Total Estimated Effort:** ~4-5 hours

---

## Phase 1: Critical Crashes (P1) — 30 min

### Bug #2: StateError from firstWhere

**File:** `lib/features/home/presentation/screens/dashboard_screen.dart:264`

**Issue:** `firstWhere` called without `orElse` callback causes crash if selected chat not in recentChats list.

**Fix:**
```dart
// Before
final ChatRequest selectedChat = widget.controller.recentChats
    .firstWhere((ChatRequest chat) => chat.id == widget.controller.selectedChatRequestId);

// After
final ChatRequest? selectedChat = widget.controller.recentChats
    .where((ChatRequest chat) => chat.id == widget.controller.selectedChatRequestId)
    .firstOrNull;

if (selectedChat == null) {
  return const Center(
    child: Text(
      'Chat not found. Please select another chat.',
      style: TextStyle(color: Color(0xFF9F1239)),
    ),
  );
}
```

---

### Bug #3: _peerPresent Never Updates

**File:** `lib/features/home/presentation/home_controller.dart:52`

**Issue:** `_peerPresent` declared as `final` so it can never change - peer presence tracking is broken.

**Fix:**
```dart
// Before
final bool _peerPresent = false;

// After
bool _peerPresent = false;
```

---

## Phase 2: Memory & State Issues (P2) — 1 hour

### Bug #4: Socket Listeners Not Removed

**File:** `lib/features/home/presentation/home_controller.dart:182-213, 265`

**Issue:** Socket listeners accumulate when HomeController recreated (SocketService is singleton).

**Fix:** Add `_removeSocketListeners()` method following `chat_room_screen.dart` pattern:
```dart
void _removeSocketListeners() {
  final socket = _socketService.socket;
  if (socket == null) {
    return;
  }
  
  socket.off('chat.requested');
  socket.off('chat.response');
  socket.off('draw.peer.waiting');
  socket.off('connect_error');
}

@override
void dispose() {
  _removeSocketListeners();
  disconnectSocket();
  super.dispose();
}
```

---

### Bug #10: Race Condition in loadDashboardData

**File:** `lib/features/home/presentation/home_controller.dart:109`

**Issue:** Concurrent calls can corrupt state (socket events + initial load).

**Fix:** Add guard flag:
```dart
bool _isLoadingDashboardInProgress = false;

Future<bool> loadDashboardData({bool showLoading = true}) async {
  if (_isLoadingDashboardInProgress) {
    return false;
  }
  _isLoadingDashboardInProgress = true;
  
  try {
    return await _runGuarded<bool>(
      () async {
        // ... existing logic
      },
      fallback: false,
    );
  } finally {
    _isLoadingDashboardInProgress = false;
  }
}
```

---

## Phase 3: Broken Features (P3) — 45 min

### Bug #8: Eraser Mode Broken

**File:** `lib/features/drawing/widgets/drawing_canvas.dart:15`

**Issue:** `BlendMode.clear` doesn't work without `saveLayer`.

**Fix:**
```dart
@override
void paint(Canvas canvas, Size size) {
  // Save layer to enable proper blending for eraser
  canvas.saveLayer(Offset.zero & size, Paint());
  
  for (final DrawSegmentStroke stroke in strokes) {
    _drawStroke(canvas, size, stroke);
  }
  
  canvas.restore();
}
```

---

### Bug #9: Null Safety Missing

**File:** `lib/features/home/domain/home_models.dart:45`

**Issue:** Crashes if API doesn't send `appearInSearches` field.

**Fix:**
```dart
// Before
appearInSearches: json['appearInSearches'] as bool,

// After
appearInSearches: (json['appearInSearches'] as bool?) ?? false,
```

---

## Phase 4: UX Issues (P4) — 1 hour

### Bug #6: FocusNode Listeners Not Removed

**File:** `lib/features/auth/presentation/screens/register_screen.dart:39-70`

**Issue:** Listeners not explicitly removed before disposal (best practice violation).

**Fix:**
```dart
late VoidCallback _emailFocusListener;
late VoidCallback _displayNameFocusListener;
late VoidCallback _passwordFocusListener;
late VoidCallback _confirmPasswordFocusListener;

@override
void initState() {
  super.initState();
  _emailFocusListener = () {
    if (!_emailFocus.hasFocus && !_blurredFields.contains('email')) {
      setState(() => _blurredFields.add('email'));
    }
  };
  _emailFocus.addListener(_emailFocusListener);
  // ... repeat for other listeners
}

@override
void dispose() {
  _emailFocus.removeListener(_emailFocusListener);
  _displayNameFocus.removeListener(_displayNameFocusListener);
  _passwordFocus.removeListener(_passwordFocusListener);
  _confirmPasswordFocus.removeListener(_confirmPasswordFocusListener);
  // ... existing dispose calls
}
```

---

### Bug #11: Cursor Jump in DisplayNameTextField

**File:** `lib/core/widgets/display_name_text_field.dart:63-69`

**Issue:** Cursor always jumps to end when editing middle of text.

**Fix:**
```dart
void _handleOnChanged(String value) {
  final String normalized = _normalizeDisplayName(value);
  final int cursorOffset = widget.controller.selection.baseOffset;
  final int adjustment = normalized.length - value.length;
  
  widget.controller.text = normalized;
  widget.controller.selection = TextSelection.fromPosition(
    TextPosition(
      offset: (cursorOffset + adjustment).clamp(1, normalized.length),
    ),
  );
  widget.onChanged?.call(normalized);
}
```

---

### Bug #12: Silent Bootstrap Failure

**File:** `lib/features/auth/presentation/auth_controller.dart:44`

**Issue:** Users logged out silently without explanation.

**Fix:**
```dart
// Before
} catch (_) {
  await _tokenStore.clearToken();
  _accessToken = null;
  _currentUser = null;
}

// After
} catch (_) {
  await _tokenStore.clearToken();
  _accessToken = null;
  _currentUser = null;
  _notice = 'Your session has expired. Please log in again.';
}
```

---

## Phase 5: Code Quality (P5) — 30 min

### Bugs #14 & #15: Delete Duplicate Components

**Files to delete:**
- `lib/features/auth/presentation/widgets/status_banner.dart`
- `lib/features/auth/presentation/widgets/custom_text_field.dart`

**Reason:** All production imports use `core/widgets/` versions. Duplicates are unused dead code.

---

### Bug #7: Documentation Mismatch

**File:** `lib/features/auth/validation_constants.dart:10`

**Fix:**
```dart
// Before
/// Matches: @ followed by 3-29 letters, numbers, or underscores

// After
/// Matches: @ followed by 2-29 letters, numbers, or underscores
```

---

### Bug #5: Timer Stop Before Dispose

**File:** `lib/features/home/presentation/widgets/pulsing_indicator.dart:38`

**Fix:**
```dart
@override
void dispose() {
  _controller.stop();
  _controller.dispose();
  super.dispose();
}
```

---

## Verification

### Static Analysis
```bash
flutter analyze
```

### Tests
```bash
flutter test
```

### Coverage Check
```bash
./scripts/coverage.sh
```

### Manual Testing
```bash
flutter run -d <device>
```
- Navigate to dashboard
- Select chat (test crash fix)
- Profile settings (test mode selection)
- Drawing (test eraser mode)
- Check peer presence indicators

---

## Success Criteria

✅ All 16 bugs fixed  
✅ No new analyzer warnings  
✅ All existing tests pass  
✅ No regressions in manual testing  
✅ Code follows established patterns  
