# Chapter 3: Demonstrating the Mobile Application - REVERB

## VI. Wireframes

The REVERB wireframes present the main interfaces and interactions of the mobile music streaming application. These wireframes were created to illustrate the layout, functionality, and user flow of the system.

---

### A. Dashboard (Home Screen)

The Dashboard serves as the central hub of REVERB, providing users with an overview of their music activity and quick access to all major features.

**[INSERT SCREENSHOT 1: Full Home Screen showing all sections]**

#### Main Elements:

**1. Search Bar**
- **Location**: Top of screen
- **Function**: Allows users to search for songs, artists, and albums
- **Interaction**: Tap to activate keyboard, type to search in real-time
- **Visual**: Dark surface (#14141F) with magnifying glass icon and hint text

**[INSERT SCREENSHOT 2: Close-up of Search Bar with sample search]**

**2. Quick Access Cards**
- **Location**: Below search bar
- **Function**: Provides instant shortcuts to three main features:
  - **Favorites** - Access liked songs (heart icon)
  - **Playlists** - View all playlists (library icon)
  - **Discover** - Jump to search (explore icon)
- **Visual**: Three horizontal cards with icons and labels
- **Interaction**: Single tap to navigate to feature

**[INSERT SCREENSHOT 3: Quick Access Cards section]**

**3. Recently Played Section**
- **Location**: Middle section, horizontally scrollable
- **Function**: Displays the last 10 songs the user has listened to
- **Elements**:
  - Song artwork (140x140px)
  - Song title (white, 13pt)
  - Artist name (gray, 12pt)
- **Interaction**: 
  - Swipe left/right to browse
  - Tap any song to play immediately
- **Updates**: Automatically refreshes when new songs are played

**[INSERT SCREENSHOT 4: Recently Played horizontal carousel]**

**4. My Playlists Section**
- **Location**: Below Recently Played
- **Function**: Shows all user-created playlists with custom covers
- **Elements**:
  - Playlist cover image (140x140px)
  - Playlist name (white, 13pt)
  - Song count (gray, 12pt)
  - Edit icon overlay (bottom-right corner)
- **Interaction**:
  - Tap playlist to view contents
  - Tap edit icon to change cover image
  - Long-press for additional options
- **Badge**: Shows total playlist count

**[INSERT SCREENSHOT 5: My Playlists section with multiple playlists]**

**5. Mini Player Bar**
- **Location**: Fixed at bottom of screen (visible on all pages)
- **Function**: Provides persistent playback control
- **Elements**:
  - Album artwork thumbnail (48x48px)
  - Song title and artist name
  - Play/Pause button
  - Next button
  - Progress bar (2.5px height)
- **Interaction**: Tap anywhere on the bar to expand to full Player screen
- **Behavior**: Only visible when music is playing

**[INSERT SCREENSHOT 6: Mini Player Bar at bottom of screen]**

#### Color Scheme:
- **Background**: #0A0A0F (near-black)
- **Card Surfaces**: #14141F (dark gray)
- **Primary Text**: White (#FFFFFF)
- **Secondary Text**: Gray (#B4B4C8)
- **Accents**: White with subtle shadows

#### User Flow from Dashboard:
```
Dashboard → Search → Results → Play
Dashboard → Quick Access → Feature → Content
Dashboard → Recently Played → Tap Song → Play
Dashboard → My Playlists → Playlist → Songs → Play
Dashboard → Mini Player → Full Player Screen
```

---

### B. Main Transaction Page – Add Song to Playlist

This wireframe sequence demonstrates the core transaction of REVERB: organizing discovered music by adding songs to playlists.

#### Screen 1: Search Results

**[INSERT SCREENSHOT 7: Search Results screen showing list of songs]**

**Main Elements:**

**Search Results List**
- **Layout**: Vertical scrollable list
- **Song Tiles** (each 72px height):
  - Album artwork (52x52px, left side)
  - Song title (15pt, white, bold)
  - Artist name (13pt, gray)
  - Duration (12pt, gray, right-aligned)
  - Three-dot menu icon (right edge)
- **Interaction**:
  - Tap song tile → Play immediately
  - Tap three-dot menu → Open action options

**Three-Dot Menu**
- **Appearance**: Floating menu overlay
- **Options**:
  - Play Next
  - **Add to Playlist** (main transaction)
  - Share
- **Interaction**: Tap any option to execute action

**[INSERT SCREENSHOT 8: Three-dot menu expanded showing options]**

---

#### Screen 2: Add to Playlist Modal

**[INSERT SCREENSHOT 9: Bottom sheet modal showing playlist selection]**

**Main Elements:**

**Modal Header**
- **Handle Bar**: Draggable indicator (40x4px, white24)
- **Title**: "Add to Playlist" (18pt, white, bold)
- **Background**: Dark surface (#14141F)
- **Interaction**: Swipe down to dismiss

**Create New Playlist Option**
- **Position**: Top of list
- **Elements**: 
  - Plus icon in circle (24px)
  - "Create New Playlist" text (16pt)
- **Interaction**: Tap to create new playlist inline

**Existing Playlists List**
- **Layout**: Scrollable vertical list
- **Playlist Tiles** (each 72px height):
  - Playlist cover (56x56px, rounded)
  - Playlist name (16pt, white)
  - Song count subtitle (14pt, gray)
- **Interaction**: 
  - Tap any playlist to add song
  - Selection triggers immediate add action

**[INSERT SCREENSHOT 10: Playlist selection list with multiple playlists]**

---

#### Screen 3: Confirmation

**[INSERT SCREENSHOT 11: Success SnackBar message at bottom]**

**Confirmation Message**
- **Appearance**: SnackBar at bottom of screen
- **Elements**:
  - Success message: "Added to [Playlist Name]"
  - Green checkmark icon
  - Dark background (#14141F)
- **Behavior**: Auto-dismisses after 2 seconds
- **User Experience**: Confirms transaction without interrupting flow

---

#### Screen 4: Alternative - Create New Playlist Flow

**[INSERT SCREENSHOT 12: Create Playlist dialog]**

**Create Playlist Dialog**
- **Layout**: Modal dialog, centered on screen
- **Elements**:
  - Title: "New Playlist"
  - Text input field (hint: "Playlist name")
  - Cancel button (gray text)
  - Create button (white text, bold)
- **Background**: Dark surface (#14141F)
- **Interaction**:
  - Type playlist name
  - Tap Create → New playlist added
  - Returns to playlist selection with new playlist

---

#### Screen 5: Playlist Cover Options

**[INSERT SCREENSHOT 13: Cover options bottom sheet]**

**Cover Options Modal**
- **Layout**: Bottom sheet with three options
- **Options**:
  1. **Choose from device**
     - Photo library icon
     - Opens device gallery picker
     - Auto-uploads to Firebase Storage
  2. **Enter image URL**
     - Link icon
     - Opens text input dialog
     - Accepts any image URL
  3. **Remove cover** (if cover exists)
     - Delete icon (red color)
     - Removes current cover image
     - Resets to default playlist icon
- **Interaction**: Tap any option to execute

**[INSERT SCREENSHOT 14: Image picker from device gallery]**

---

### Transaction Flow Summary

#### Complete User Journey:
```
1. User searches for song
   ↓
2. Search results display
   ↓
3. User taps three-dot menu on desired song
   ↓
4. Menu appears with "Add to Playlist" option
   ↓
5. User taps "Add to Playlist"
   ↓
6. Modal slides up showing playlists
   ↓
7. User selects destination playlist
   ↓
8. Song is added to playlist (backend)
   ↓
9. Success message appears
   ↓
10. Modal auto-dismisses
   ↓
11. User returns to search results
```

#### Data Elements Involved:
- **Song Object**: ID, title, artist, artwork URL, duration
- **Playlist Object**: ID, name, cover URL, song IDs array
- **User Object**: UID, playlists collection reference

#### Average Transaction Time:
- **Minimum**: 10 seconds (known song, fast selection)
- **Average**: 20-30 seconds
- **Maximum**: 60+ seconds (creating new playlist, slow network)

---

## VII. Task Analysis

The main transaction of REVERB is **adding a song to a playlist**. This task represents the core functionality that enables users to organize their music library.

### User Journey Breakdown

#### **Step 1: Open Dashboard**
- **Action**: User launches REVERB app
- **System Response**: Home screen loads instantly (no splash screen)
- **User Sees**: Search bar, Recently Played, Playlists, Quick Access
- **Time**: < 1 second

#### **Step 2: Search for a Song**
- **Action**: User taps search bar and types query
- **System Response**: 
  - Keyboard appears
  - Text displays in real-time
  - Clear button (X) becomes visible
- **Example Query**: "shape of you"
- **Time**: 2-4 seconds (typing duration)

#### **Step 3: View Results**
- **Action**: User submits search (tap Enter)
- **System Response**: 
  - API call to YouTube Music
  - Loading indicator displays briefly
  - Results populate in list format
- **User Sees**: 
  - Song tiles with artwork
  - Titles and artist names
  - Duration and three-dot menus
- **Backend**: InnerTube API query and response parsing
- **Time**: 0.5-2 seconds (network dependent)

#### **Step 4: Select Song Options**
- **Action**: User taps three-dot menu on desired song
- **System Response**: 
  - Popup menu appears
  - Haptic feedback (vibration)
  - Options display with icons
- **User Sees**: 
  - "Play Next" option
  - **"Add to Playlist"** option (target)
  - "Share" option
- **Time**: < 0.5 seconds

#### **Step 5: Select "Add to Playlist"**
- **Action**: User taps "Add to Playlist"
- **System Response**: 
  - Menu dismisses
  - Bottom sheet modal slides up (300ms animation)
  - Playlists load from Firestore
- **User Sees**: 
  - "Create New Playlist" option at top
  - List of existing playlists with covers
- **Time**: 0.3 seconds (animation) + 0.2-1 second (data load)

#### **Step 6: Choose Playlist**
- **Action**: User taps destination playlist
- **System Response**: 
  - Checkmark animation
  - Backend transaction begins
  - Loading state (brief)
- **Backend Process**:
  1. Validate user authentication
  2. Check if song already exists in playlist
  3. Add song ID to playlist.songs array
  4. Update Firestore document
  5. Return success/failure
- **Time**: 0.5-1.5 seconds

#### **Step 7: Complete Transaction**
- **System Response**: 
  - Song added to Firestore
  - Local state updates
  - Success confirmed
- **User Sees**: Nothing yet (processing in background)
- **Time**: < 1 second

#### **Step 8: Receive Confirmation**
- **System Response**: 
  - Success SnackBar appears at bottom
  - Message: "Added to [Playlist Name]"
  - Green checkmark icon
  - Modal auto-dismisses
- **User Experience**: 
  - Clear visual confirmation
  - Return to search results
  - Ready for next action
- **Time**: 2 seconds (auto-dismiss duration)

---

### Task Analysis Details

#### Total Interaction Points:
- **Minimum Taps Required**: 5-6
  1. Tap search bar
  2. Tap search/enter key
  3. Tap three-dot menu
  4. Tap "Add to Playlist"
  5. Tap destination playlist
  6. (Optional) Tap back button

#### Cognitive Load:
- **Low Load Points**:
  - Tapping search bar (universal pattern)
  - Typing query (familiar action)
  - Tapping menu (standard UI convention)
  
- **Medium Load Points**:
  - Scanning search results (visual processing)
  - Choosing correct song (comparison task)
  - Selecting playlist (decision making)

- **High Load Points**:
  - Creating new playlist name (creative thinking)
  - First-time use (learning interface)

#### Error Scenarios:

**1. No Internet Connection**
- **Failure Point**: Search submission (Step 3)
- **Error Message**: "No connection. Check your network."
- **Recovery**: User checks WiFi/data, retries search
- **Prevention**: Cache recent searches

**2. Song Already in Playlist**
- **Failure Point**: Add to playlist (Step 6)
- **Error Message**: "Song already in this playlist"
- **Recovery**: User selects different playlist or dismisses
- **Prevention**: Gray out playlists already containing song

**3. User Not Signed In**
- **Failure Point**: Firestore write (Step 7)
- **Error Message**: "Sign in to save playlists"
- **Recovery**: User creates account or signs in, retries
- **Prevention**: Anonymous auth allows temporary saves

**4. Network Timeout**
- **Failure Point**: Firestore write (Step 7)
- **Error Message**: "Failed to add. Try again."
- **Recovery**: User taps "Try Again" button
- **Prevention**: Retry logic with exponential backoff

#### Alternative Paths:

**Quick Add from Player Screen:**
```
Playing song → Tap heart icon → Auto-adds to Favorites
Time: 1 tap, < 1 second
```

**Create Playlist During Transaction:**
```
Step 5 → Tap "Create New Playlist" → Enter name → Continue with add
Additional Time: +5-10 seconds
```

---

### Success Metrics

#### Transaction Success Indicators:
- ✅ Song appears in selected playlist
- ✅ Success message displays
- ✅ Playlist song count increments
- ✅ Recently added section updates

#### Key Performance Indicators:
- **Completion Rate**: % of started transactions completed successfully
  - Target: > 95%
- **Average Time**: Seconds from search to successful add
  - Target: < 25 seconds
- **Error Rate**: % of failed transactions requiring retry
  - Target: < 2%
- **User Satisfaction**: Post-transaction feedback rating
  - Target: > 4.5/5 stars

---

## VIII. User Interface Manual

This manual provides step-by-step instructions for using the REVERB mobile application.

---

### Getting Started

#### First Launch
1. **Open the REVERB application** to access the Home screen
2. **Choose authentication method**:
   - **Continue as Guest** - Start immediately without account
   - **Sign In** - Use existing email and password
   - **Create Account** - Register new account via Profile icon
3. **Explore the interface**:
   - Search bar at top for finding music
   - Quick Access cards for main features
   - Recently Played shows your listening history
   - My Playlists displays your collections

**[INSERT SCREENSHOT 15: Welcome screen or first-time user view]**

---

### Main Navigation

The Home screen provides access to all major features:

#### **1. Search**
- **Location**: Top of Home screen
- **Purpose**: Find songs, artists, and albums from YouTube Music catalog
- **How to Use**:
  1. Tap the search bar
  2. Type song name, artist, or album
  3. Results appear as you type
  4. Tap any result to play or add to playlist

**[INSERT SCREENSHOT 16: Search in action with results]**

#### **2. Favorites**
- **Access**: Heart icon (top-right) OR Quick Access card
- **Purpose**: View and play all liked songs
- **Features**:
  - Grid view of favorite songs
  - Play all with shuffle
  - Remove songs by long-press or swipe
- **Updates**: Real-time sync across devices

**[INSERT SCREENSHOT 17: Favorites screen with grid layout]**

#### **3. Playlists**
- **Access**: Library icon (top-right) OR Quick Access card
- **Purpose**: Create, edit, and manage music collections
- **Features**:
  - Create unlimited playlists
  - Add custom cover images
  - Rename or delete playlists
  - View song count
- **Visual**: Grid layout with 2 columns

**[INSERT SCREENSHOT 18: Playlists screen showing multiple playlists]**

#### **4. Recently Played**
- **Access**: Home screen, middle section
- **Purpose**: Quickly replay recently played songs
- **Features**:
  - Shows last 10 played songs
  - Horizontal scrollable carousel
  - Auto-updates when playing new songs
  - Tap any song to replay

**[INSERT SCREENSHOT 19: Recently Played carousel]**

#### **5. Profile**
- **Access**: Person icon (top-right of Home screen)
- **Purpose**: Manage account settings and authentication
- **Features**:
  - View account information
  - Sign in / Sign out
  - Upgrade guest account to permanent
  - Manage sync settings

**[INSERT SCREENSHOT 20: Profile screen showing user information]**

---

### Playing Music

#### Starting Playback

**Method 1: From Search**
1. Search for a song using the search bar
2. Tap any song tile in the results
3. Music begins playing immediately
4. Player screen opens automatically

**Method 2: From Home Screen**
1. Browse Recently Played or My Playlists sections
2. Tap any song card
3. Playback starts instantly

**Method 3: From Playlists**
1. Open Playlists screen
2. Tap a playlist to view contents
3. Tap any song to play
4. OR tap Play All button for shuffle play

**[INSERT SCREENSHOT 21: Player Screen - full view]**

---

#### Player Controls

**Full Player Screen Elements:**

**Playback Controls** (bottom section):
- **Previous Button** - Skip to previous track in queue
- **Play/Pause Button** (large center) - Toggle playback
- **Next Button** - Skip to next track in queue

**Secondary Controls**:
- **Shuffle Button** - Toggle random playback order
- **Repeat Button** - Cycle through: Off → Repeat All → Repeat One
- **Heart Icon** - Add/remove from Favorites (animates when tapped)
- **Queue Icon** - View upcoming songs

**Information Display**:
- Album artwork (320x320px, centered)
- Song title (22pt, bold)
- Artist name (16pt, subtitle)
- "Now Playing" header text
- Progress bar with time stamps

**Gesture Controls**:
- **Tap anywhere on progress bar** - Seek to position
- **Tap back arrow** (top-left) - Return to previous screen
- **Swipe down** - Minimize to mini player

**[INSERT SCREENSHOT 22: Player controls close-up]**

---

#### Mini Player Bar

**Location**: Fixed at bottom of all screens (except full player)

**Elements**:
- Small album artwork (48x48px)
- Song title and artist (truncated)
- Play/Pause button
- Next button
- Thin progress bar

**Interactions**:
- **Tap anywhere on bar** → Expand to full player
- **Tap Play/Pause** → Control playback without expanding
- **Tap Next** → Skip to next song

**Behavior**:
- Appears automatically when music starts playing
- Persists across all app screens
- Hides when playback stops

**[INSERT SCREENSHOT 23: Mini Player Bar showing current song]**

---

### Managing Favorites

#### Adding to Favorites

**Method 1: From Player Screen**
1. While playing a song, look for the heart icon
2. Tap the heart icon
3. Icon animates and turns solid (white)
4. Song is added to Favorites immediately

**Method 2: From Song Lists**
1. Find the song in search results or playlist
2. Tap the three-dot menu icon
3. Select "Add to Favorites"
4. Heart icon appears on song tile

**[INSERT SCREENSHOT 24: Heart icon animation sequence]**

#### Viewing Favorites

1. Tap the **Heart icon** in top bar OR
2. Tap **Favorites** card in Quick Access section
3. Grid view displays all favorite songs (2 columns)
4. Scroll to browse collection
5. Tap any song to play

**Additional Actions**:
- **Play All Button** (floating action button) - Shuffles all favorites
- **Long-press song** - Access quick actions
- **Swipe song** - Remove from favorites

**[INSERT SCREENSHOT 25: Favorites grid with multiple songs]**

---

### Managing Playlists

#### Creating a New Playlist

1. Navigate to **Playlists** screen (library icon or Quick Access)
2. Tap the **+ (Plus)** floating action button (bottom-right)
3. **Create Playlist dialog** appears
4. Enter a name for your playlist
5. Tap **Create** button
6. New playlist appears in grid immediately

**[INSERT SCREENSHOT 26: Create Playlist dialog]**

---

#### Adding Songs to Playlists

**Method 1: From Search Results**
1. Search for a song
2. Tap the three-dot menu on any song
3. Select "Add to Playlist"
4. Choose destination playlist from list
5. Success message confirms addition

**Method 2: From Player Screen**
1. While playing a song, tap three-dot menu
2. Select "Add to Playlist"
3. Choose destination playlist
4. Song added without interrupting playback

**Method 3: Bulk Add**
1. Open Favorites screen
2. Select multiple songs (if feature enabled)
3. Tap "Add to Playlist"
4. Choose destination
5. All selected songs added

**[INSERT SCREENSHOT 27: Add to Playlist bottom sheet]**

---

#### Adding Playlist Covers

**Method 1: From Home Screen**
1. Navigate to **My Playlists** section on Home
2. Find your playlist card
3. **Option A**: Tap the small **edit icon** (bottom-right corner)
4. **Option B**: **Long-press** the playlist card
5. **Cover Options sheet** appears with three choices

**Method 2: From Playlists Screen**
1. Go to Playlists screen (full grid view)
2. Long-press any playlist card
3. Select cover option from menu

**Cover Options**:

**1. Choose from Device**
- Opens your device photo gallery
- Select any image from your photos
- Image auto-uploads to cloud storage
- Automatically compressed to 1024x1024px
- Optimized to 85% quality for fast loading

**2. Enter Image URL**
- Dialog appears with text input field
- Paste any image URL from the web
- Image loads directly from URL
- No upload needed

**3. Remove Cover** (only if cover exists)
- Removes current cover image
- Resets to default playlist icon
- Original image remains in cloud (not deleted)

**[INSERT SCREENSHOT 28: Cover options bottom sheet with three choices]**

**[INSERT SCREENSHOT 29: Device gallery picker open]**

**[INSERT SCREENSHOT 30: Enter URL dialog]**

---

#### Editing Playlists

**Renaming a Playlist**:
1. Open the playlist (tap card to view contents)
2. Tap **three-dot menu** (top-right)
3. Select **"Rename"**
4. Enter new name in dialog
5. Tap **Save**

**Deleting a Playlist**:
1. Open the playlist
2. Tap three-dot menu
3. Select **"Delete"** (red text)
4. Confirm deletion in popup
5. Playlist removed permanently

**Removing Songs**:
1. Open the playlist
2. Find song to remove
3. **Swipe left** on song tile
4. Confirm removal
5. Song count updates automatically

**[INSERT SCREENSHOT 31: Playlist detail screen with songs]**

**[INSERT SCREENSHOT 32: Rename/Delete menu options]**

---

### Key Interactions & Gestures

#### Touch Gestures

**Tap** (Single Touch):
- Select items (songs, playlists, buttons)
- Play/pause music
- Open screens and menus
- Toggle settings (shuffle, repeat)
- **Usage**: 95% of all interactions

**Long Press** (Touch and Hold):
- Access playlist cover options
- Show quick action menus
- Alternative to three-dot menu
- **Duration**: ~0.5 seconds
- **Feedback**: Haptic vibration

**Swipe Horizontal**:
- Navigate carousels (Recently Played, Playlists)
- Browse song artwork in player
- **Direction**: Left/right
- **Speed**: Moderate flick

**Swipe Vertical**:
- Scroll lists and screens
- **Pull down to refresh** (Home screen)
- Dismiss bottom sheets
- **Direction**: Up/down

**Drag**:
- Adjust progress bar position (seek)
- Reorder playlist songs (if enabled)
- **Usage**: Fine control needed

**[INSERT SCREENSHOT 33: Gesture examples illustrated]**

---

#### Interactive Elements

**Buttons**:
- Minimum size: 44x44px (accessible tap target)
- Visual feedback: Scale animation or color change
- Haptic feedback on tap
- Disabled state: Reduced opacity

**Cards**:
- Tap to open/select
- Long-press for options
- Hover effect: Slight scale (on capable devices)
- Shadow deepens on press

**Text Fields**:
- Tap to activate keyboard
- Show cursor and hint text
- Clear button (X) appears when typing
- Auto-focus on dialog open

**Sliders**:
- Drag thumb to adjust
- Tap track to jump to position
- Visual feedback: Thumb scales slightly
- Used for: Volume, seek bar

---

### Visual Feedback

**Animations**:
- **Fade In**: New screens appear (600ms)
- **Slide Up**: Bottom sheets (300ms)
- **Scale**: Button presses (100ms)
- **Hero**: Album artwork expansion to player (380ms)

**Loading States**:
- **Circular Spinner**: Data loading (white)
- **Skeleton Screens**: Content placeholder (gray blocks)
- **Progress Bars**: Long operations (thin line)

**Success Indicators**:
- **SnackBar Messages**: Bottom of screen, auto-dismiss
- **Icon Animations**: Heart fills, checkmark appears
- **Color Changes**: White → Filled state

**Error States**:
- **Error Icons**: Red with message text
- **Retry Buttons**: White on dark background
- **Toast Messages**: Brief error notification

**[INSERT SCREENSHOT 34: Various UI states - loading, success, error]**

---

### Special Features

#### Pull to Refresh
- **Location**: Home screen only
- **Action**: Pull down at top of screen
- **Effect**: 
  - Circular spinner appears
  - Reloads Recently Played
  - Updates playlists
  - Refreshes after ~1 second
- **Visual**: White spinner on dark background

#### Auto-Sync
- **Behavior**: Changes sync automatically when signed in
- **What Syncs**:
  - Favorites across devices
  - Playlists and covers
  - Recently played history (last 10)
- **Frequency**: Real-time (Firestore streams)
- **Indicator**: No visible indicator (seamless)

#### Offline Behavior
- **Search**: Requires internet connection
- **Playback**: Requires internet (streaming only)
- **Local Data**: Recently played list cached temporarily
- **Favorites**: List cached, playback requires connection

---

### Accessibility Features

#### Screen Reader Support
- All buttons have descriptive labels
- Song tiles announce: "[Title] by [Artist]"
- Navigation announces screen names
- Success messages are read aloud

#### Visual Accommodations
- High contrast colors (#FFFFFF on #0A0A0F)
- Large touch targets (minimum 44x44px)
- Scalable text (respects system font size)
- No color-only indicators (icons + text)

#### Motor Accommodations
- No time-based interactions
- No complex gestures required
- Alternative navigation methods
- Scrolling not mandatory for key actions

---

### Troubleshooting

**Music Won't Play**:
1. Check internet connection
2. Verify song is available in your region
3. Try searching for alternate version
4. Restart app if needed

**Recently Played Not Showing**:
1. Sign in with email account (not guest)
2. Play at least 3-5 songs
3. Pull down to refresh Home screen
4. Check Profile to confirm sign-in status

**Playlists Not Syncing**:
1. Verify signed in (check Profile)
2. Check internet connection
3. Force close and reopen app
4. Check Firebase sync status

**Cover Image Won't Upload**:
1. Check image size (< 10MB)
2. Verify internet connection
3. Try different image
4. Use URL method as alternative

---

### Tips & Best Practices

**For Best Experience**:
- ✅ Sign in with email for full sync
- ✅ Create playlists before searching
- ✅ Add covers for visual organization
- ✅ Use Recently Played for quick access
- ✅ Pull down to refresh occasionally

**To Save Data**:
- Search strategically (avoid browsing)
- Use WiFi for initial setup
- Recently Played uses minimal data
- Covers cached after first load

**For Organization**:
- Name playlists descriptively
- Add covers for easy identification
- Use Favorites for frequent songs
- Regularly check Recently Played

---

## Screenshot Placement Summary

**Total Screenshots Needed**: 34

### Dashboard Section (Wireframes VI.A):
1. Full home screen
2. Search bar close-up
3. Quick Access cards
4. Recently Played carousel
5. My Playlists section
6. Mini Player bar

### Transaction Section (Wireframes VI.B):
7. Search results screen
8. Three-dot menu expanded
9. Add to Playlist modal
10. Playlist selection list
11. Success SnackBar
12. Create Playlist dialog
13. Cover options sheet
14. Image picker from gallery
15. Welcome/first launch screen

### UI Manual Section (VIII):
16. Search with results
17. Favorites grid
18. Playlists screen
19. Recently Played detail
20. Profile screen
21. Full Player screen
22. Player controls close-up
23. Mini Player showing song
24. Heart icon animation
25. Favorites with songs
26. Create Playlist dialog (repeat)
27. Add to Playlist sheet (repeat)
28. Cover options (repeat)
29. Gallery picker
30. Enter URL dialog
31. Playlist detail with songs
32. Rename/Delete menu
33. Gesture illustrations
34. UI states (loading/success/error)

---

*Document Version: 2.0*  
*Last Updated: January 2025*  
*Ready for Academic Submission*
