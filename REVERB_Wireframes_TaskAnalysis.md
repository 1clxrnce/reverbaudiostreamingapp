# REVERB - Wireframes & Task Analysis

## VI. Wireframes

### Overview
The following wireframes represent the actual user interface of the REVERB mobile application. Each screen has been annotated to explain page elements, user interactions, and component purposes.

---

### Wireframe 1: Dashboard (Home Screen)

**[INSERT SCREENSHOT: Home Screen with all sections visible]**

#### Screen Purpose
The Dashboard serves as the main entry point and navigation hub for the entire application. It provides quick access to all core features and displays personalized music content.

#### Page Elements & Annotations

**1. Top Bar Section**
- **Logo (Left)**: REVERB branding, provides visual identity
- **Search Bar (Center-spanning)**: 
  - Input field with hint text: "Search songs, artists, albums..."
  - Magnifying glass icon (left)
  - Clear button (X icon) appears when typing
  - **Interaction**: Tap to activate keyboard, type to search in real-time
  - **Purpose**: Primary music discovery mechanism
- **Heart Icon**: Quick access to favorites page
- **Library Icon**: Navigate to playlists screen
- **Profile Icon**: Access account settings and sign-in/out

**2. Quick Access Cards Section**
- **Section Title**: "Quick Access" (22pt bold, white text)
- **Three Horizontal Cards** (120px width each):
  1. **Favorites Card**:
     - Heart icon (40px, white)
     - "Favorites" label below
     - Background: #14141F (dark surface)
     - **Interaction**: Tap to open favorites grid
     - **Purpose**: Instant access to liked songs
  
  2. **Playlists Card**:
     - Library music icon (40px, white)
     - "Playlists" label below
     - **Interaction**: Tap to open playlists screen
     - **Purpose**: Quick access to user's playlists
  
  3. **History Card**:
     - History icon (40px, white)
     - "History" label below
     - **Interaction**: Tap to view play history
     - **Purpose**: Resume recent listening

**3. Recently Played Section**
- **Section Title**: "Recently Played" (22pt bold)
- **Horizontal Scrollable List**:
  - Song cards (140x140px artwork)
  - Song title (13pt, white, truncated)
  - Artist name (12pt, gray, truncated)
  - **Interaction**: 
    - Swipe left/right to browse
    - Tap any song to play immediately
  - **Purpose**: Quick replay of recent songs
- **Data Source**: Last 10 played tracks from user history

**4. My Playlists Section**
- **Section Title**: "My Playlists" (22pt bold)
- **Playlist Counter Badge**: Shows total playlist count
- **Horizontal Scrollable List**:
  - Playlist cards (140x140px covers)
  - Playlist name (13pt, white, truncated)
  - Song count (12pt, gray)
  - **Edit Icon Overlay** (bottom-right, 16px)
  - **Interaction**:
    - Tap playlist to view contents
    - Tap edit icon to change cover
    - Long-press for cover options
  - **Purpose**: Visual playlist navigation and management

**5. Mini Player Bar (Bottom)**
- **Fixed position at screen bottom**
- **Components**:
  - Album artwork thumbnail (48x48px)
  - Song title (14pt, white)
  - Artist name (12pt, gray)
  - Play/Pause button (28px icon)
  - Next button (28px icon)
  - Progress bar (2.5px height, white)
- **Interaction**: Tap anywhere to expand to full player
- **Purpose**: Persistent playback control

#### Color Scheme
- Background: #0A0A0F (near-black)
- Surface cards: #14141F (dark gray)
- Primary text: White (#FFFFFF)
- Secondary text: Gray (#B4B4C8)
- Accent hints: Subtle white shadows

#### User Flow from Dashboard
```
Dashboard → Search → Results → Play → Player Screen
Dashboard → Quick Access → Favorites/Playlists → View → Play
Dashboard → Recently Played → Tap Song → Player Screen
Dashboard → My Playlists → Tap Playlist → Playlist Detail → Play
Dashboard → Mini Player → Tap → Full Player Screen
```

---

### Wireframe 2: Main Transaction Page (Add Song to Playlist)

**[INSERT SCREENSHOT: Search Results Screen with song list]**

**[INSERT SCREENSHOT: Three-dot menu opened on a song]**

**[INSERT SCREENSHOT: "Add to Playlist" bottom sheet modal]**

#### Transaction Purpose
The core transaction in REVERB is **adding songs to playlists**. This represents the primary user action for organizing their music library.

#### Transaction Flow Screens

#### Screen A: Search Results
**Page Elements:**

**1. Search Bar (Top)**
- Active search query displayed
- Clear button (X) visible
- **Purpose**: Shows user what they searched for

**2. Results List**
- **Song Tiles** (Full-width, 72px height):
  - Album artwork (52x52px, rounded corners)
  - Song title (15pt, white, bold)
  - Artist name (13pt, gray)
  - Duration (12pt, gray, right-aligned)
  - **Three-dot menu icon** (right edge)
- **Scrollable**: Vertical scroll for long results
- **Interaction**: 
  - Tap song → Play immediately
  - Tap three-dot menu → Open options
- **Purpose**: Display search results for selection

**3. Three-Dot Menu Options**
- Floating menu appears on tap
- **Options**:
  - "Play Next" - Add to queue
  - **"Add to Playlist"** - Main transaction trigger
  - "Share" - Share song link
- **Purpose**: Access additional song actions

---

#### Screen B: Add to Playlist Modal (Transaction Screen)

**[INSERT SCREENSHOT: Bottom sheet showing playlist selection]**

**Page Elements:**

**1. Modal Header**
- **Handle Bar** (40px wide, 4px tall, white24)
  - **Purpose**: Visual indicator of draggable modal
- **Title**: "Add to Playlist" (18pt, white, bold)
- **Close Affordance**: Swipe down to dismiss
- **Background**: #14141F (dark surface)

**2. Create New Playlist Option**
- **Card at top** (full-width):
  - Plus icon in circle (24px)
  - "Create New Playlist" text (16pt)
  - **Interaction**: Tap to create new playlist
  - **Purpose**: Quick playlist creation without leaving flow

**3. Existing Playlists List**
- **Scrollable List** (if many playlists):
  - Playlist tiles (full-width, 72px height)
  - Cover image (56x56px, rounded)
  - Playlist name (16pt, white)
  - Song count subtitle (14pt, gray)
  - **Selection Indicator**: Checkmark appears on tap
- **Interaction**: Tap any playlist to add song
- **Purpose**: Select destination playlist

**4. Confirmation Feedback**
- **Success Message**: SnackBar appears at bottom
  - "Added to [Playlist Name]"
  - Green checkmark icon
  - Auto-dismisses after 2 seconds
- **Purpose**: Confirm transaction success

**5. Empty State** (if no playlists exist)
- Icon: Queue music (48px, white24)
- Text: "No playlists yet"
- Subtitle: "Create your first playlist"
- **Create Button**: Prominent white button
- **Purpose**: Guide first-time users

#### Transaction Interaction Flow
```
1. User searches for song
2. Results display in list
3. User taps three-dot menu on desired song
4. Menu appears with options
5. User taps "Add to Playlist"
6. Modal slides up from bottom
7. User sees playlist list
8. User taps destination playlist
9. Song is added (backend transaction)
10. Success message appears
11. Modal dismisses automatically
12. User returns to search results
```

#### Data Elements Involved
- **Song Object**: 
  - ID (unique identifier)
  - Title
  - Artist
  - Album artwork URL
  - Duration
- **Playlist Object**:
  - ID
  - Name
  - Cover URL
  - Song IDs array
- **User Object**:
  - UID
  - Playlists collection reference

#### Error Handling
- **Network Error**: "Failed to add song. Try again."
- **Already Exists**: "Song already in this playlist"
- **Empty Selection**: Modal remains open until selection

---

### Wireframe 3: Alternative Transaction - Create Playlist with Cover

**[INSERT SCREENSHOT: Playlists Screen with + button]**

**[INSERT SCREENSHOT: Create Playlist Dialog]**

**[INSERT SCREENSHOT: Playlist with Edit Cover Button]**

**[INSERT SCREENSHOT: Cover Options Bottom Sheet]**

#### Transaction Purpose
Creating and customizing playlists is a secondary core transaction that demonstrates the app's personalization features.

#### Page Elements

**Screen: Playlists Grid**
- **Grid Layout**: 2 columns
- **Floating Action Button** (bottom-right):
  - White circle with + icon
  - **Interaction**: Tap to create playlist
  - **Purpose**: Primary action on this screen

**Screen: Create Playlist Dialog**
- **Dark Modal** (#14141F background)
- **Title**: "New Playlist" (18pt, white, bold)
- **Text Input Field**:
  - Hint: "Playlist name"
  - Dark background (#14141F)
  - White text
  - 12px rounded corners
- **Action Buttons**:
  - "Cancel" (gray text)
  - "Create" (white text, bold)
- **Purpose**: Capture playlist name

**Screen: Playlist Card with Edit Icon**
- **Playlist Cover** (140x140px)
- **Edit Icon Overlay** (bottom-right corner):
  - Semi-transparent black circle
  - White edit icon (16px)
  - **Purpose**: Visual indicator of editability

**Screen: Cover Options Modal**
- **Three Options**:
  1. **"Choose from device"**
     - Photo library icon
     - Opens device gallery
     - Uploads to Firebase Storage
  
  2. **"Enter image URL"**
     - Link icon
     - Opens text input dialog
     - Accepts any image URL
  
  3. **"Remove cover"** (if cover exists)
     - Delete icon (red)
     - Removes current cover
     - Resets to default icon

#### Transaction Steps
```
1. User taps + button on Playlists screen
2. Dialog appears with text field
3. User types playlist name
4. User taps "Create"
5. Playlist is created in Firestore
6. Grid updates with new playlist
7. User taps edit icon on new playlist
8. Cover options modal appears
9. User selects "Choose from device"
10. Gallery picker opens
11. User selects image
12. Image is compressed and uploaded
13. Cover URL is saved to playlist
14. Grid updates with new cover
15. Success message displays
```

---

## VII. Task Analysis

### Overview
This task analysis examines the complete user journey for the main transaction: **Adding a song to a playlist**. This represents the core interaction loop that enables users to organize their music library.

---

### User Goals
**Primary Goal**: Add a discovered song to a playlist for future listening  
**Secondary Goals**: 
- Organize music by mood, genre, or purpose
- Build curated collections
- Create shareable playlists

---

### User Journey: Complete Transaction Flow

#### Phase 1: Discovery (Dashboard → Search)

**Step 1: Access Dashboard**
- **Action**: User opens app
- **System Response**: Home screen loads instantly (no splash)
- **User Sees**: 
  - Search bar at top
  - Recently played songs
  - Existing playlists
- **Decision Point**: User wants to find a new song
- **Time**: < 1 second

**Step 2: Initiate Search**
- **Action**: User taps search bar
- **System Response**: 
  - Keyboard appears
  - Search icon animates
  - Cursor blinks in field
- **User Sees**: Active input field
- **Cognitive Load**: Low - familiar search pattern
- **Time**: < 0.5 seconds

**Step 3: Enter Search Query**
- **Action**: User types song name or artist
  - Example: "shape of you"
- **System Response**: 
  - Text appears in real-time
  - Clear (X) button becomes visible
- **User Sees**: Their query being entered
- **Time**: 2-4 seconds (typing)

**Step 4: Submit Search**
- **Action**: User taps search/enter on keyboard
- **System Response**: 
  - API call to YouTube Music
  - Loading indicator appears
  - Keyboard dismisses
- **User Sees**: Loading state
- **Backend Process**:
  - InnerTube API query
  - Results parsing
  - Song object creation
- **Time**: 0.5-2 seconds (network dependent)

---

#### Phase 2: Selection (Search Results)

**Step 5: Review Results**
- **Action**: User scrolls through results list
- **System Response**: 
  - Results display in list format
  - Smooth scrolling
- **User Sees**: 
  - Song tiles with artwork
  - Song titles and artists
  - Durations
  - Three-dot menus
- **Decision Point**: User identifies desired song
- **Cognitive Load**: Medium - visual scanning
- **Time**: 2-8 seconds (varies by result position)

**Step 6: Preview (Optional)**
- **Action**: User taps song to preview
- **System Response**: 
  - Song begins playing immediately
  - Player screen opens
- **User Decision**: 
  - If correct song → Continue to add
  - If wrong song → Go back and try again
- **Time**: 0-10 seconds

---

#### Phase 3: Transaction Initiation

**Step 7: Access Song Options**
- **Action**: User taps three-dot menu on song tile
- **System Response**: 
  - Popup menu appears
  - Options display with icons
  - Haptic feedback (subtle vibration)
- **User Sees**: 
  - "Play Next" option
  - **"Add to Playlist"** option (target)
  - "Share" option
- **Visual Hierarchy**: Icons help quick identification
- **Time**: < 0.5 seconds

**Step 8: Select "Add to Playlist"**
- **Action**: User taps "Add to Playlist" option
- **System Response**: 
  - Menu dismisses
  - Bottom sheet modal slides up
  - Animation duration: 300ms
- **User Sees**: Modal with playlists
- **Cognitive Load**: Low - clear transition
- **Time**: 0.3 seconds (animation)

---

#### Phase 4: Transaction Execution

**Step 9: View Playlist Options**
- **Action**: User scans available playlists
- **System Response**: 
  - Playlists load from Firestore
  - "Create New Playlist" option at top
  - Existing playlists below
- **User Sees**: 
  - Playlist names
  - Cover images
  - Song counts
- **Decision Point**: Select existing or create new
- **Time**: 1-5 seconds

**Step 9A: If Creating New Playlist**
- **Action**: User taps "Create New Playlist"
- **System Response**: 
  - New dialog appears
  - Text field focused
  - Keyboard appears
- **User Action**: Types playlist name
- **System Response**: Creates playlist in Firestore
- **Additional Time**: +5-10 seconds
- **Flow**: Returns to playlist selection with new playlist

**Step 10: Select Destination Playlist**
- **Action**: User taps target playlist
- **System Response**: 
  - Checkmark animation appears
  - Backend transaction begins
  - Loading state (brief)
- **Backend Process**:
  ```
  1. Validate user authentication
  2. Check if song already in playlist
  3. Add song ID to playlist.songs array
  4. Update Firestore document
  5. Return success/failure
  ```
- **Time**: 0.5-1.5 seconds

---

#### Phase 5: Confirmation & Completion

**Step 11: Receive Confirmation**
- **System Response**: 
  - Success SnackBar appears at bottom
  - Message: "Added to [Playlist Name]"
  - Green checkmark icon
  - Modal auto-dismisses
- **User Sees**: 
  - Clear success feedback
  - Return to search results
- **Cognitive Satisfaction**: Task completed successfully
- **Time**: 2 seconds (auto-dismiss)

**Step 12: Continue or Exit**
- **User Options**:
  - **Option A**: Search for another song (loop to Step 2)
  - **Option B**: Play the song (tap song tile)
  - **Option C**: View playlist (navigate to playlists)
  - **Option D**: Return to home (back button)
- **System State**: Transaction saved, ready for next action
- **Time**: User-determined

---

### Complete Journey Timeline

| Phase | Steps | Time Range | Cumulative Time |
|-------|-------|------------|-----------------|
| Discovery | 1-4 | 3-8 seconds | 3-8 seconds |
| Selection | 5-6 | 2-18 seconds | 5-26 seconds |
| Initiation | 7-8 | 0.8 seconds | 6-27 seconds |
| Execution | 9-10 | 1.5-11.5 seconds | 8-39 seconds |
| Confirmation | 11-12 | 2+ seconds | 10-41+ seconds |

**Average Transaction Time**: 20-30 seconds  
**Minimum Transaction Time**: 10 seconds (known song, fast network)  
**Maximum Transaction Time**: 60+ seconds (new user, slow network, creating playlist)

---

### Task Analysis Breakdown

#### 1. Cognitive Load Analysis

**Low Cognitive Load Points**:
- Tapping search bar (universal pattern)
- Typing query (familiar action)
- Tapping three-dot menu (standard UI)
- Selecting from list (simple choice)

**Medium Cognitive Load Points**:
- Scanning search results (visual processing)
- Deciding correct song (comparison task)
- Choosing destination playlist (decision making)

**High Cognitive Load Points**:
- Creating new playlist name (creative thinking)
- First-time use (learning interface)

**Mitigation Strategies**:
- Clear visual hierarchy
- Familiar icons and patterns
- Immediate feedback on actions
- Undo/back options available

---

#### 2. Interaction Points

**Total Taps Required**: 5-6 minimum
1. Tap search bar
2. Tap search/enter
3. Tap three-dot menu
4. Tap "Add to Playlist"
5. Tap destination playlist
6. (Optional) Back button

**Gesture Types Used**:
- Single tap (primary)
- Scroll (secondary)
- Keyboard input (secondary)
- Swipe down to dismiss (optional)

**Haptic Feedback Points**:
- Three-dot menu tap
- Playlist selection
- Success confirmation

---

#### 3. Error Scenarios & Recovery

**Error 1: No Internet Connection**
- **Point of Failure**: Step 4 (Search submission)
- **System Response**: "No connection. Check your network."
- **User Recovery**: 
  - Check WiFi/data
  - Retry search
- **Prevention**: Cache recent searches

**Error 2: Song Already in Playlist**
- **Point of Failure**: Step 10 (Add to playlist)
- **System Response**: "Song already in this playlist"
- **User Recovery**: 
  - Select different playlist
  - Dismiss modal
- **Prevention**: Gray out playlists that already contain song

**Error 3: Network Timeout During Add**
- **Point of Failure**: Step 10 (Firestore write)
- **System Response**: "Failed to add. Try again."
- **User Recovery**: 
  - Tap "Try Again" button
  - Re-select playlist
- **Prevention**: Retry logic with exponential backoff

**Error 4: User Not Signed In (Guest Mode)**
- **Point of Failure**: Step 10 (Firestore requires auth)
- **System Response**: "Sign in to save playlists"
- **User Recovery**: 
  - Create account
  - Sign in
  - Retry transaction
- **Prevention**: Anonymous auth allows temporary saves

---

#### 4. Alternative Paths

**Path A: Quick Add from Player**
```
Playing song → Tap heart icon → Auto-adds to Favorites
Time: 1 tap, < 1 second
Bypasses: Steps 1-8
```

**Path B: Batch Add from Favorites**
```
Favorites screen → Select multiple → Add all to playlist
Time: Multiple selections, 1 destination choice
Efficiency: High for many songs
```

**Path C: Voice Search (Future)**
```
Tap mic icon → Speak song name → Results appear
Bypasses: Keyboard input
Saves: 2-4 seconds typing time
```

---

#### 5. User Satisfaction Factors

**Positive Factors**:
- ✓ Fast search results (< 2 seconds)
- ✓ Clear visual feedback (animations, confirmations)
- ✓ Familiar interaction patterns (standard UI)
- ✓ Undo capability (remove from playlist later)
- ✓ Non-destructive actions (can't lose data)

**Friction Points**:
- ⚠ Multiple taps required (5-6 minimum)
- ⚠ Must remember playlist names
- ⚠ No bulk operations (one song at a time)
- ⚠ Network dependency for search

**Improvement Opportunities**:
1. **Smart Suggestions**: Suggest playlists based on song genre
2. **Recently Used**: Show recently added-to playlists first
3. **Drag & Drop**: Visual playlist organization
4. **Offline Queue**: Save adds locally, sync when online
5. **Voice Commands**: "Add this to my workout playlist"

---

#### 6. Accessibility Considerations

**Screen Reader Support**:
- All buttons have semantic labels
- Search field has hint text
- Results announced as they load
- Success messages are spoken

**Motor Impairment Support**:
- Large touch targets (44x44px minimum)
- No required gestures (alternatives available)
- Scrolling not mandatory (fits small screens)

**Visual Impairment Support**:
- High contrast colors (#FFFFFF on #0A0A0F)
- Scalable text (respects system font size)
- Icons paired with text labels

**Cognitive Support**:
- Consistent navigation patterns
- Clear visual hierarchy
- Progressive disclosure (modals)
- Undo/back options always available

---

#### 7. Technical Flow Diagram

```
[User Opens App]
       ↓
[Home Screen Loads]
       ↓
[User Taps Search] ← Keyboard appears
       ↓
[User Types Query] ← Real-time input
       ↓
[User Submits] → [API Call] → [Parse Results]
       ↓                            ↓
[Results Display] ← [200 OK Response]
       ↓
[User Scans List] ← Visual processing
       ↓
[User Taps Menu] → Haptic feedback
       ↓
[Options Appear] ← Animation
       ↓
[User Taps "Add to Playlist"]
       ↓
[Modal Slides Up] ← Animation (300ms)
       ↓
[Playlists Load] ← Firestore query
       ↓
[User Selects Playlist] → Auth check
       ↓                      ↓
[Firestore Write] ← [Validation Pass]
       ↓
[Success Response] → Update local state
       ↓
[Show SnackBar] ← "Added to [Name]"
       ↓
[Auto Dismiss] → Return to results
       ↓
[Transaction Complete]
```

---

#### 8. Success Metrics

**Transaction Success Indicators**:
- Song appears in selected playlist
- Success message displayed
- Playlist song count increments
- Recently added section updates

**Measurable KPIs**:
- **Completion Rate**: % of started transactions completed
- **Average Time**: Seconds from search to add
- **Error Rate**: % of failed transactions
- **Retry Rate**: % requiring multiple attempts
- **User Satisfaction**: Post-transaction feedback

**Target Benchmarks**:
- Completion Rate: > 95%
- Average Time: < 25 seconds
- Error Rate: < 2%
- User Satisfaction: > 4.5/5 stars

---

### Conclusion

The "Add Song to Playlist" transaction demonstrates REVERB's focus on efficient music organization. The journey is optimized for:

1. **Speed**: Minimal steps from discovery to completion
2. **Clarity**: Clear feedback at every interaction point
3. **Flexibility**: Multiple entry points and paths
4. **Recovery**: Graceful error handling and retry mechanisms
5. **Satisfaction**: Visual and haptic feedback confirm success

The task analysis reveals a well-structured flow with minimal cognitive load and maximum user control, resulting in a smooth, satisfying transaction experience.

---

### Next Steps for Implementation Screenshots

To complete this document, capture the following screenshots from the running app:

**Dashboard Wireframe:**
1. Full home screen (scroll to show all sections)
2. Close-up of search bar
3. Quick Access cards
4. Recently Played carousel
5. My Playlists section
6. Mini player bar

**Transaction Wireframe:**
1. Search results screen
2. Three-dot menu open on a song
3. "Add to Playlist" modal open
4. Playlist selection list
5. Success SnackBar message
6. Create new playlist dialog
7. Cover options bottom sheet

**Recommended Screenshot Settings:**
- Device: Standard Android phone (1080x2400)
- Orientation: Portrait
- Time: Hide or use 9:41 (standard mockup time)
- Battery: Full or hidden
- Network: WiFi icon visible

---

*Document Version: 1.0*  
*Last Updated: January 2025*  
*Ready for Screenshot Integration*
