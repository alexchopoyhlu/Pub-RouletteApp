# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pub Roulette is a multiplayer iOS pub crawl game built with SwiftUI and Firebase. Players join parties via codes, get assigned to teams through a spinning wheel, receive randomized pub orders and drink assignments, then race to complete the crawl while submitting photo evidence.

## Architecture

### State Management Pattern

The app uses Swift's `@Observable` pattern (iOS 17+) with singleton services:

- **PartyService**: Central state manager (`currentParty`, `currentPlayer`, `isHost`)
- **FirebaseService**: Firestore operations with real-time listeners
- **LocationService**: MapKit integration for pub search

**Data Flow:**
```
View → ViewModel → PartyService → FirebaseService ↔ Firestore
```

All state changes flow through `PartyService.currentParty` which is mirrored in Firestore. Changes propagate to all clients via `addSnapshotListener()`.

### Game Phase Progression

The game flows through 6 phases defined by `PartyStatus` enum:

```
LOBBY → TEAM_ASSIGNMENT → PUB_REVEAL → DRINK_REVEAL → ACTIVE → FINISHED
```

**Navigation Pattern:**
- Uses `NavigationPath` with `.append(PartyStatus)` for phase transitions
- Status changes in Firebase trigger automatic navigation via `onChange(of: viewModel.party?.status)`
- Only host can initiate transitions; other players observe and sync
- Backward navigation prevented by tracking status order (0-5)

### Real-Time Multiplayer Sync

**Party State:**
- `listenToParty(code:)` establishes snapshot listener on party document
- All clients observe same Firestore document
- Read-modify-write pattern prevents race conditions:
  1. Fetch full party
  2. Modify local copy
  3. Write back entire updated object

**Wheel Spin Sync:**
- Host calculates `WheelState` (rotation, targetRotation, spinStartTime) and writes to Firebase
- Non-hosts detect `spinStartTime` change in `syncWheelState()` and animate locally
- Each client maintains `displayRotation` for smooth animation despite network latency

**Messages:**
- Subcollection: `parties/{code}/messages/`
- Ordered by timestamp with `listenToMessages()` listener
- System messages track game events (completions, joins)

### Firebase Structure

**Main Document:** `parties/{partyCode}`
```swift
{
  code: String,
  hostId: String,
  status: PartyStatus,
  teams: [Team],
  players: [Player],
  pubs: [Pub],
  wheelState: WheelState,
  // ... settings
}
```

**Messages Subcollection:** `parties/{partyCode}/messages/{messageId}`

### Key Data Structures

**Team Progression:**
```swift
struct Team {
    var pubOrder: [Int]              // Team's randomized pub sequence
    var drinkOrder: [String]          // Drink per pub
    var currentPubIndex: Int          // Tracks progression
    var submissions: [String: [String]]  // pubIndex → [playerIds]
    var pubCompletionTimes: [String: Date]  // pubIndex → completionTime
    var finishTime: Date?             // Set when all pubs complete
}
```

When all team members submit for a pub:
1. `currentPubIndex` increments
2. `pubCompletionTimes[pubIndex]` records timestamp
3. System message sent
4. If `currentPubIndex >= pubOrder.count`, set `finishTime` and end game

## Custom Animations & UI Components

### Mesh Gradients
**File:** `AnimatedMeshGradient.swift`

- Themes: `.midnight`, `.aurora`, `.amber`, `.sunset`, `.victory`, `.monochrome`
- iOS 18+: Native `MeshGradient` with `TimelineView(.animation)` for continuous sine/cosine wave motion
- Fallback: Animated blur circles for iOS <18
- Each game phase uses a specific theme for visual continuity

### Wheel Component
**File:** `WheelView.swift`

- Radial segmentation: `segmentSize = 360° / playerCount`
- Player names positioned along radius with mid-angle rotation
- Text auto-flips on left half for readability
- Border crossing detection triggers haptic feedback
- Ease-out cubic easing over 4 seconds

### Pub Reveal Animation
**File:** `PubRevealViewModel.swift`

3-pass shuffle animation:
1. **Gather**: Cards move to center with calculated offsets, Z-indices alternate
2. **Scatter**: Cards repositioned using shuffled indices
3. **Gather**: Spring animation returns to original positions

Sequential reveal: 400ms delay between cards with 3D rotation effect.

### Slot Machine Animation
**File:** `DrinkRevealViewModel.swift`

Phase-based slot animation:
- `SlotPhase`: idle → spinning → stopping → revealed
- Phase 1: All slots spin simultaneously
- Phase 2: Cascade stopping with 150ms delays
- Final snap uses spring animation (0.25s response, 0.7 damping)
- Vertical offset + linear blur during spin for visual polish

## Design Patterns & Conventions

### Safe Array Access
```swift
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```
Use this throughout for optional lookups: `party.pubs[safe: index]`

### Custom Font System
```swift
Text("Hello").font(.bricolage(.headline))
```
Bricolage Grotesque SemiBold is used consistently across the app.

### Haptic Feedback
```swift
Haptics.light()      // Selections
Haptics.medium()     // Button taps
Haptics.heavy()      // Major actions (wheel spin)
Haptics.success()    // Confirmations
Haptics.warning()    // Destructive actions
```

### Party Code Generation
6-character uppercase alphanumeric, excluding confusing characters (0/O/I/1/L):
```swift
"ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
```

### Distribution Modes
```swift
enum DrinkDistributionMode {
    case random      // Drinks can repeat or not appear
    case oneOfEach   // All selected drinks cycle, ensuring each appears
}
```
Logic in `assignPubOrdersAndDrinks()` handles different strategies.

## Important Implementation Notes

### Never Break Synchronization
- All party/team/player updates MUST go through FirebaseService
- Never modify `PartyService.currentParty` directly without syncing to Firebase
- Use read-modify-write pattern for concurrent updates

### Host vs Non-Host Logic
- Only `isHost` can trigger phase transitions
- Non-host players observe state changes and navigate accordingly
- Check `viewModel.isHost` before enabling control buttons

### Submission Flow
When player submits evidence:
1. Add playerId to `team.submissions[pubIndex]`
2. Check if all team members submitted
3. If complete: increment `currentPubIndex`, record time, send system message
4. If team finished all pubs: set `finishTime`, update party status to `.finished`

### Animation Timing
Common durations from `Constants.swift`:
- Wheel spin: 4.0 seconds
- Card flip: 0.6 seconds
- Slot spin phases: varies (2-5 seconds total)
- Use spring animations for final reveals: `response: 0.4-0.5, dampingFraction: 0.6-0.75`

### Observable ViewModel Pattern
```swift
@Observable
final class MyViewModel {
    var property: String = ""  // Automatically triggers view updates
}

// In View:
@State private var viewModel = MyViewModel()
```

### Mesh Gradient Integration
For new animated backgrounds:
```swift
ZStack {
    MeshGradientBackground(theme: .yourTheme)
    // Your content
}
```

## Xcode Project Structure

```
Pub Roulette/
├── Models/           # Codable data structures (Party, Team, Player, Pub, Message)
├── Services/         # Singleton services (PartyService, FirebaseService, LocationService)
├── ViewModels/       # @Observable view models per phase
├── Views/
│   ├── Home/         # Entry point, mesh gradients
│   ├── Lobby/        # Party join/create, settings
│   ├── TeamAssignment/  # Wheel spin
│   ├── PubReveal/    # Shuffle animation
│   ├── DrinkReveal/  # Slot machine
│   ├── Crawl/        # Feed/Route/Rankings tabs
│   └── Results/      # Winner screen with confetti
└── Utilities/        # Extensions, Constants, Haptics
```

## Development Workflow

### Building
Standard Xcode build system. Open `Pub Roulette.xcodeproj` and build for iOS simulator or device.

### Previews
Use SwiftUI previews for rapid iteration:
```swift
#Preview {
    NavigationStack {
        MyView()
    }
}
```

### Debugging
- Print statements used throughout for state tracking
- Check Firestore console for data verification
- Use Xcode debugger for breakpoint debugging

## Firebase Considerations

### No Authentication
The app uses public Firestore rules (demo mode). For production, add Firebase Authentication.

### Party Cleanup
No automatic party deletion. Old parties remain in Firestore indefinitely.

### Offline Behavior
Firebase SDK handles offline caching, but the app assumes connectivity for real-time sync.

## Common Pitfalls

1. **Don't skip reading files before editing** - Always read existing code before modifications
2. **Mesh gradients require iOS 18+** - Check availability and provide fallback
3. **Triangle shape is defined in WheelView.swift** - Don't redeclare in other files
4. **Safe subscript already exists** - Don't duplicate in Collection extensions
5. **Party status transitions are one-way** - Can't go backwards in phase progression
6. **System messages use special senderId** - `senderId: "system"` for game events
