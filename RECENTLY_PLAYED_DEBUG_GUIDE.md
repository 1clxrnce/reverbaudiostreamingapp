# Recently Played - Debug & Fix Guide

## Current Status

### ✅ Player Screen - FIXED
- Shows "Now Playing" text (line 166 in player_screen.dart)
- Wrapped in SingleChildScrollView (line 193)
- No overflow issues

### 🔧 Recently Played - Enhanced Debugging Added

## What I Just Fixed

### 1. Enhanced Logging in Audio Handler
**File**: `lib/audio/audio_handler.dart`

Added detailed debug logs to track every step:
```dart
Future<void> _recordPlayHistory(Song song) async {
  try {
    final user = _auth.currentUser;
    debugPrint('[audio] attempting to record play for: ${song.title}');
    debugPrint('[audio] user signed in: ${user != null} (uid: ${user?.uid})');
    
    if (user == null) {
      debugPrint('[audio] skipping recording - no user signed in');
      return;
    }

    await _firestore.recordPlay(user.uid, song);
    debugPrint('[audio] ✓ successfully recorded play: ${song.title}');
  } catch (e, stackTrace) {
    debugPrint('[audio] ✗ failed to record play: $e');
    debugPrint('[audio] stack trace: $stackTrace');
  }
}
```

### 2. Enhanced Logging in Firestore Service
**File**: `lib/services/firestore_service.dart`

Added logging to Firestore operations:
```dart
Future<void> recordPlay(String userId, Song song) async {
  try {
    debugPrint('[firestore] recording play - user: $userId, song: ${song.title}');
    
    await _db
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(song.id)
        .set({...}, SetOptions(merge: true));
    
    debugPrint('[firestore] ✓ play recorded successfully');
  } catch (e, stackTrace) {
    debugPrint('[firestore] ✗ failed to record play: $e');
    rethrow;
  }
}
```

### 3. Enhanced Logging in Home Screen
**File**: `lib/screens/home_screen.dart`

Added logging to see what data is received:
```dart
data: (songs) {
  debugPrint('[home] Recently Played loaded: ${songs.length} songs');
  if (songs.isEmpty) {
    debugPrint('[home] No history found - showing empty state');
    // Show empty state
  }
  debugPrint('[home] Displaying ${songs.length} songs: ${songs.map((s) => s.title).join(", ")}');
  // Display songs
}
```

---

## How to Test & Debug

### Step 1: Run the App with Logs
```bash
cd "c:\Users\Joshua\flutter projects\simple_player"
flutter run
```

### Step 2: Sign In to the App
**IMPORTANT**: You MUST be signed in with an email account (not guest/anonymous)

1. Open the app
2. Tap Profile icon (top right)
3. If you see "Guest User":
   - Tap "Create Account" or "Sign In"
   - Use a real email and password
4. Verify you're signed in (should show your email)

### Step 3: Play Some Songs
1. Go to home screen
2. Tap search bar
3. Search for a song (e.g., "shape of you")
4. Tap any song to play it
5. **Wait 3-5 seconds** for it to start playing
6. Play at least 3 different songs

### Step 4: Watch the Debug Logs

You should see logs like this in your terminal:

**When a song starts playing:**
```
[audio] attempting to record play for: Shape of You
[audio] user signed in: true (uid: abc123...)
[firestore] recording play - user: abc123..., song: Shape of You
[firestore] ✓ play recorded successfully
[audio] ✓ successfully recorded play: Shape of You
```

**If NOT signed in:**
```
[audio] attempting to record play for: Shape of You
[audio] user signed in: false (uid: null)
[audio] skipping recording - no user signed in
```

**If there's an error:**
```
[audio] attempting to record play for: Shape of You
[audio] user signed in: true (uid: abc123...)
[firestore] recording play - user: abc123..., song: Shape of You
[firestore] ✗ failed to record play: [permission-denied] ...
```

### Step 5: Check Home Screen

1. Go back to home screen (tap back arrow)
2. Look for "Recently Played" section
3. Should show the songs you just played

**Watch for these logs:**
```
[home] Recently Played loaded: 3 songs
[home] Displaying 3 songs: Shape of You, Despacito, Perfect
```

**If empty:**
```
[home] Recently Played loaded: 0 songs
[home] No history found - showing empty state
```

---

## Common Issues & Solutions

### Issue 1: "skipping recording - no user signed in"

**Problem**: User is not signed in or using anonymous auth

**Solution**:
1. Open Profile screen
2. Sign out if needed
3. Tap "Sign In" or "Create Account"
4. Use email and password (not guest mode)
5. Try playing songs again

### Issue 2: "permission-denied" error

**Problem**: Firestore security rules blocking writes

**Solution**:
1. Open Firebase Console: https://console.firebase.google.com
2. Go to your project
3. Click "Firestore Database" in left menu
4. Click "Rules" tab
5. Add this rule:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      match /history/{songId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /favorites/{songId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /playlists/{playlistId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

6. Click "Publish"
7. Try playing songs again

### Issue 3: "Recently Played loaded: 0 songs" but songs were recorded

**Problem**: Data exists but not loading

**Solution**:
1. Pull down on home screen to refresh
2. Check Firebase Console → Firestore Database
3. Navigate to: `users/{your-uid}/history`
4. Verify documents exist
5. Check if `lastPlayedAt` field has a timestamp
6. If documents exist but not loading, check the stream query

### Issue 4: Songs recorded but old songs showing

**Problem**: Old test data interfering

**Solution**:
1. Open Firebase Console → Firestore
2. Go to `users/{your-uid}/history`
3. Delete all old documents
4. Play new songs
5. Refresh home screen

---

## Verify in Firebase Console

### Check if Data is Being Written:

1. Open https://console.firebase.google.com
2. Select your project
3. Click "Firestore Database"
4. Navigate to: **users → {your-uid} → history**
5. You should see documents like:

```
Document ID: dQw4w9WgXcQ (song video ID)
Fields:
  - id: "dQw4w9WgXcQ"
  - title: "Never Gonna Give You Up"
  - artist: "Rick Astley"
  - artwork: "https://..."
  - lastPlayedAt: January 21, 2025 at 10:30:00 AM UTC
  - playCount: 1
```

### Check Multiple Plays:

If you play the same song twice:
```
  - playCount: 2  (incremented)
  - lastPlayedAt: [updated to new time]
```

---

## Expected Log Flow

### Complete successful flow:

```
1. User taps song in search results
   └─> [audio] attempting to record play for: Song Title

2. Audio handler checks user
   └─> [audio] user signed in: true (uid: xyz123)

3. Calls Firestore service
   └─> [firestore] recording play - user: xyz123, song: Song Title

4. Firestore writes data
   └─> [firestore] ✓ play recorded successfully

5. Audio handler confirms
   └─> [audio] ✓ successfully recorded play: Song Title

6. User goes to home screen
   └─> [home] Recently Played loaded: 1 songs
   └─> [home] Displaying 1 songs: Song Title
```

---

## Quick Checklist

Before reporting the issue isn't fixed, verify:

- [ ] App is running with `flutter run` (can see logs)
- [ ] Signed in with real email account (not guest)
- [ ] Played at least 3 songs
- [ ] Waited 3-5 seconds between plays
- [ ] Checked terminal for debug logs
- [ ] Checked Firebase Console for data
- [ ] Refreshed home screen (pull down)
- [ ] Firestore rules allow read/write
- [ ] No errors in terminal logs

---

## What to Share if Still Not Working

If it's still not working after all steps, share:

1. **Terminal logs** from when you played songs
2. **Screenshot** of Firebase Console showing history collection
3. **Screenshot** of home screen (showing empty state or error)
4. **User status** from Profile screen (email shown?)
5. **Any error messages** from the logs

---

## Summary of Changes

✅ **Player Screen**: Already has "Now Playing", already scrollable  
✅ **Debugging**: Added comprehensive logging to track data flow  
✅ **Error Handling**: Added stack traces to identify issues  
✅ **Quick Access**: Changed History → Discover card  

**Next**: Run the app and watch the logs to see what's happening!

---

*Created: January 2025*  
*All debugging code committed*
