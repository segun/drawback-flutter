# Flutter Codebase Bug Report

> Generated: March 4, 2026

---

## Summary

| Severity | Count | Description |
|----------|-------|-------------|
| **Critical** | 3 | Missing widget, potential crash, dead code |
| **Memory Leaks** | 3 | Socket listeners, timer, focus node listeners |
| **Logic Errors** | 6 | Validation mismatch, eraser mode, null safety, race conditions, etc. |
| **Code Quality** | 5 | Duplicates, missing error handling, UX issues |

---

## Critical Bugs

### 1. Missing RadioGroup Widget (Compile Error)

**File:** `lib/features/home/presentation/screens/profile_screen.dart` (lines 176-195)

**Issue:** The code uses `RadioGroup<UserMode>` which is not a standard Flutter widget and doesn't exist in the codebase.

**Problem:** This will cause a compile-time error - the app won't build.

**Recommended Fix:** Replace with proper Flutter RadioListTile usage:

```dart
// Remove the RadioGroup wrapper entirely and use the RadioListTile widgets directly:
Column(
  children: <Widget>[
    RadioListTile<UserMode>(
      title: const Text('Public', style: TextStyle(fontSize: 13)),
      subtitle: const Text(
        'Visible in public user lists',
        style: TextStyle(fontSize: 11),
      ),
      value: UserMode.public,
      groupValue: _selectedMode,
      onChanged: (UserMode? value) {
        if (value != null) {
          setState(() => _selectedMode = value);
        }
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    ),
    RadioListTile<UserMode>(
      title: const Text('Private', style: TextStyle(fontSize: 13)),
      subtitle: const Text(
        'Only visible when searched by @name',
        style: TextStyle(fontSize: 11),
      ),
      value: UserMode.private,
      groupValue: _selectedMode,
      onChanged: (UserMode? value) {
        if (value != null) {
          setState(() => _selectedMode = value);
        }
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    ),
  ],
)
```

---

### 2. StateError: firstWhere without orElse

**File:** `lib/features/home/presentation/screens/dashboard_screen.dart` (lines 228-229)

**Issue:** `firstWhere` is called without an `orElse` callback, which throws `StateError` if no element is found.

```dart
final ChatRequest selectedChat = widget.controller.recentChats
    .firstWhere((ChatRequest chat) => chat.id == widget.controller.selectedChatRequestId);
```

**Problem:** If the selected chat request ID doesn't exist in `recentChats` (e.g., after a race condition or if the chat was removed), the app will crash.

**Recommended Fix:**

```dart
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

### 3. `_peerPresent` Field Never Updates (Dead Code)

**File:** `lib/features/home/presentation/home_controller.dart` (line 57)

**Issue:** `_peerPresent` is declared as `final` and initialized to `false`, so it can never be changed.

```dart
final bool _peerPresent = false;
```

**Problem:** The getter `peerPresent` will always return `false`, making peer presence tracking non-functional.

**Recommended Fix:** Remove the `final` keyword:

```dart
bool _peerPresent = false;
```

---

## Memory Leaks

### 4. Stream Subscription Leak - Socket Listeners Not Properly Cleaned

**File:** `lib/features/home/presentation/home_controller.dart` (lines 182-203)

**Issue:** Socket listeners are added in `_setupSocketListeners()` but the `dispose()` method only calls `disconnectSocket()`, which doesn't explicitly remove the listeners.

```dart
void _setupSocketListeners() {
  final socket = _socketService.socket;
  if (socket == null) {
    return;
  }

  socket.on('chat.requested', (dynamic data) { ... });
  socket.on('chat.response', (dynamic data) { ... });
  // ...
}
```

**Problem:** Since SocketService is a singleton, listeners may accumulate if HomeController is recreated, leading to duplicate event handling.

**Recommended Fix:** Add explicit listener removal:

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

### 5. Timer Leak in PulsingIndicator

**File:** `lib/features/home/presentation/widgets/pulsing_indicator.dart` (lines 26-32)

**Issue:** The AnimationController uses `..repeat(reverse: true)` which runs indefinitely.

**Problem:** While the controller is disposed properly, the animation should ideally be stopped before disposal to prevent potential issues.

**Recommended Fix:** Add explicit stop before dispose:

```dart
@override
void dispose() {
  _controller.stop();
  _controller.dispose();
  super.dispose();
}
```

---

### 6. FocusNode Listeners Not Explicitly Removed

**File:** `lib/features/auth/presentation/screens/register_screen.dart` (lines 39-54)

**Issue:** FocusNode listeners are added but not explicitly removed before disposal.

```dart
_emailFocus.addListener(() { ... });
_displayNameFocus.addListener(() { ... });
```

**Problem:** While `FocusNode.dispose()` should clean up, explicit removal is best practice and prevents potential issues.

**Recommended Fix:** Store listener references and remove them:

```dart
late VoidCallback _emailFocusListener;
late VoidCallback _displayNameFocusListener;

@override
void initState() {
  super.initState();
  _emailFocusListener = () {
    if (!_emailFocus.hasFocus && !_blurredFields.contains('email')) {
      setState(() => _blurredFields.add('email'));
    }
  };
  _emailFocus.addListener(_emailFocusListener);
  // ... etc
}

@override
void dispose() {
  _emailFocus.removeListener(_emailFocusListener);
  _displayNameFocus.removeListener(_displayNameFocusListener);
  // ... etc
  _emailFocus.dispose();
  _displayNameFocus.dispose();
  super.dispose();
}
```

---

## Logic Errors

### 7. Validation Pattern Mismatch - Comment vs Regex

**File:** `lib/features/auth/validation_constants.dart` (lines 9-12)

**Issue:** The comment says "3-29" characters but the regex specifies `{2,29}` (2-29 characters).

```dart
/// Matches: @ followed by 3-29 letters, numbers, or underscores
static final RegExp displayNamePattern = RegExp(
  r'^@[A-Za-z0-9_]{2,29}$',
);
```

**Problem:** Documentation doesn't match implementation, leading to confusion and potential validation issues.

**Recommended Fix:** Update the comment to match the regex (or vice versa depending on requirements):

```dart
/// Matches: @ followed by 2-29 letters, numbers, or underscores
static final RegExp displayNamePattern = RegExp(
  r'^@[A-Za-z0-9_]{2,29}$',
);
```

---

### 8. Eraser Mode Won't Work Correctly Without SaveLayer

**File:** `lib/features/drawing/widgets/drawing_canvas.dart` (lines 24-34)

**Issue:** The eraser uses `BlendMode.clear` without wrapping in a `saveLayer`:

```dart
if (stroke.color == 'eraser') {
  final Paint eraserPaint = Paint()
    ..blendMode = BlendMode.clear
    ..color = Colors.transparent
    ..strokeWidth = stroke.width
    //...
  canvas.drawLine(from, to, eraserPaint);
}
```

**Problem:** `BlendMode.clear` only works correctly within a layer. Without `saveLayer`, the eraser may not work as expected or may clear to the underlying widget's background.

**Recommended Fix:**

```dart
@override
void paint(Canvas canvas, Size size) {
  // Save a layer to enable proper blending for eraser
  canvas.saveLayer(Offset.zero & size, Paint());
  
  for (final DrawSegmentStroke stroke in strokes) {
    _drawStroke(canvas, size, stroke);
  }
  
  canvas.restore();
}
```

---

### 9. Missing Null Safety in UserProfile.fromJson

**File:** `lib/features/home/domain/home_models.dart` (lines 40-48)

**Issue:** The `fromJson` factory doesn't handle missing or null `appearInSearches` field.

```dart
factory UserProfile.fromJson(Map<String, dynamic> json) {
  return UserProfile(
    // ...
    appearInSearches: json['appearInSearches'] as bool,  // Can throw if null
    // ...
  );
}
```

**Problem:** If the API response doesn't include `appearInSearches`, the app will crash with a type cast error.

**Recommended Fix:**

```dart
appearInSearches: (json['appearInSearches'] as bool?) ?? false,
```

---

### 10. Race Condition in loadDashboardData

**File:** `lib/features/home/presentation/home_controller.dart` (lines 109-155)

**Issue:** Multiple concurrent calls to `loadDashboardData` are possible (e.g., from socket events and initial load).

**Problem:** If called concurrently, the state could become inconsistent.

**Recommended Fix:** Add a flag to prevent concurrent execution:

```dart
bool _isLoadingDashboardInProgress = false;

Future<bool> loadDashboardData({bool showLoading = true}) async {
  if (_isLoadingDashboardInProgress) {
    return false;
  }
  _isLoadingDashboardInProgress = true;
  
  try {
    return await _runGuarded<bool>(/* ... */);
  } finally {
    _isLoadingDashboardInProgress = false;
  }
}
```

---

### 11. Cursor Always Moved to End in DisplayNameTextField

**File:** `lib/core/widgets/display_name_text_field.dart` (lines 56-66)

**Issue:** When normalizing the display name, the cursor is always moved to the end.

```dart
void _handleOnChanged(String value) {
  final String normalized = _normalizeDisplayName(value);
  widget.controller.text = normalized;
  widget.controller.selection = TextSelection.fromPosition(
    TextPosition(offset: normalized.length),  // Always at end
  );
  widget.onChanged?.call(normalized);
}
```

**Problem:** Users editing in the middle of the text will have their cursor jump to the end, creating poor UX.

**Recommended Fix:** Preserve cursor position relative to changes:

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

### 12. Missing Error Handling in Bootstrap

**File:** `lib/features/auth/presentation/auth_controller.dart` (lines 32-49)

**Issue:** When bootstrap fails, the error is silently caught and the user is logged out without notification.

```dart
} catch (_) {
  await _tokenStore.clearToken();
  _accessToken = null;
  _currentUser = null;
}
```

**Problem:** Users may be confused about why they're logged out after a token expiration.

**Recommended Fix:** Add a specific error state or notice for expired sessions:

```dart
} catch (e) {
  await _tokenStore.clearToken();
  _accessToken = null;
  _currentUser = null;
  _notice = 'Your session has expired. Please log in again.';
}
```

---

## Code Quality Issues

### 13. Socket Singleton State Persistence

**File:** `lib/core/realtime/socket_service.dart` (lines 221-230)

**Issue:** The `SocketService` is a singleton, but socket event handlers may accumulate.

**Problem:** If the app navigates away and returns, new listeners may be added without removing old ones.

**Recommendation:** Track registered listeners and ensure proper cleanup. Consider keeping a registry of active listeners:

```dart
class SocketService {
  final Set<String> _registeredEvents = {};
  
  void on(String event, Function handler) {
    if (!_registeredEvents.contains(event)) {
      socket?.on(event, handler);
      _registeredEvents.add(event);
    }
  }
  
  void off(String event) {
    socket?.off(event);
    _registeredEvents.remove(event);
  }
}
```

---

### 14. Duplicate StatusBanner Components

**Files:**
- `lib/core/widgets/status_banner.dart`
- `lib/features/auth/presentation/widgets/status_banner.dart`

**Issue:** Two identical `StatusBanner` and `BannerKind` definitions exist.

**Problem:** Code duplication, potential inconsistencies, and confusion about which to import.

**Recommended Fix:** Remove the version in `features/auth/presentation/widgets/` and update all imports to use `lib/core/widgets/status_banner.dart`.

---

### 15. Duplicate CustomTextField Components

**Files:**
- `lib/core/widgets/custom_text_field.dart`
- `lib/features/auth/presentation/widgets/custom_text_field.dart`

**Issue:** Two nearly identical `CustomTextField` implementations exist (the one in `core` has an additional `focusNode` parameter).

**Problem:** Code duplication and inconsistency.

**Recommended Fix:** Consolidate into `lib/core/widgets/custom_text_field.dart` with all necessary parameters and update all imports.

---

### 16. Timer Not Cancelled on Hot Reload

**File:** `lib/features/drawing/presentation/screens/chat_room_screen.dart` (lines 65-68)

**Issue:** `_reconnectButtonTimer` and `_emoteAnimationTimer` are properly disposed, but hot reload scenarios may not trigger dispose.

**Recommendation:** Consider using `didUpdateWidget` for cleanup:

```dart
@override
void didUpdateWidget(ChatRoomScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Cancel any pending timers if configuration changed
}
```

---

### 17. Timer Cancellation Should Use Null-Aware Assignment

**File:** `lib/features/drawing/presentation/screens/chat_room_screen.dart`

**Issue:** Multiple places where timers are cancelled and restarted without null-checking.

**Recommendation:** Use consistent pattern:

```dart
_reconnectButtonTimer?.cancel();
_reconnectButtonTimer = Timer(duration, callback);
```

---

## Priority Order for Fixes

1. **Critical** - Fix immediately:
   - RadioGroup widget (blocks compilation)
   - `firstWhere` without `orElse` (crash)
   - `_peerPresent` final keyword (broken feature)

2. **High** - Fix in next sprint:
   - Socket listener cleanup (memory leak)
   - Null safety in `fromJson` (potential crash)
   - Race condition in `loadDashboardData`

3. **Medium** - Schedule for improvement:
   - Eraser mode fix
   - Cursor position in DisplayNameTextField
   - FocusNode listener cleanup

4. **Low** - Technical debt:
   - Code duplication cleanup
   - Documentation mismatches
   - Bootstrap error handling
