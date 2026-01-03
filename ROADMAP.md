# PlanPop Development Roadmap

A cute, colorful to-do list app for students ages 10-18.

---

## Phase 1: Project Setup

Setting up the foundation for your app.

- [x] Create a new Xcode project (iOS App, SwiftUI)
- [x] Name the project "PlanPop"
- [x] Set minimum iOS version to 16.0
- [x] Copy all Swift files into the project
- [x] Organize files into folders (Models, Views, ViewModels, etc.)
- [x] Add app icon (design a cute, pastel-colored icon)
- [x] Configure Info.plist for notifications permission
  - Add `NSUserNotificationsUsageDescription` key
- [x] Initialize Git repository

---

## Phase 2: Core Models & Data

Building the data layer of your app.

- [x] Create `Task` model
  - Properties: id, title, notes, isCompleted, dueDate, reminder, category, priority
  - Helper methods for filtering (isDueToday, isDueTomorrow, etc.)

- [x] Create `Category` model
  - Properties: id, name, color, icon
  - Default categories: School, Home, Fun

- [x] Create `UserSettings` model
  - Premium status, theme, notifications, streak tracking

- [x] Create `PersistenceManager`
  - Save/load tasks, categories, and settings to UserDefaults
  - Handle first-launch setup

---

## Phase 3: Core Views

Building the main screens users will see.

- [x] Create `ContentView` (main tab container)
  - Tab bar with Tasks and Settings tabs
  - Pastel-colored accent

- [x] Create `TaskListView`
  - Header with greeting and streak badge
  - Filter pills (Today, Tomorrow, This Week, All, Completed)
  - Scrollable task list
  - Empty state when no tasks
  - Floating add button

- [x] Create `AddTaskView`
  - Title input field
  - Optional notes
  - Due date picker (toggle to show/hide)
  - Reminder toggle and picker
  - Category selection chips
  - Priority selector
  - Delete button (when editing)

- [x] Create `SettingsView`
  - Stats card (streak, total completed)
  - Category management link
  - Notification toggle
  - Theme selector
  - Premium upgrade section
  - About/version info

- [x] Create `CategoryManagerView`
  - List of existing categories
  - Add new category
  - Edit/delete categories
  - Color and icon picker

---

## Phase 4: UI Components

Reusable building blocks for your app.

- [x] Create `TaskRow` component
  - Circular checkbox with animation
  - Task title with strikethrough when done
  - Category badge
  - Due date/time display
  - Overdue indicator
  - Reminder bell icon

- [x] Create `EmptyStateView` component
  - Friendly emoji
  - Encouraging message
  - Different messages for different filters

- [x] Create `ConfettiView` component
  - Colorful falling confetti pieces
  - Triggered when all daily tasks are done

- [x] Create `StreakBadge` component
  - Flame icon
  - Current streak count

- [x] Create `FilterPill` component
  - Rounded pill shape
  - Icon and text
  - Task count badge

---

## Phase 5: Theme & Styling

Making your app look cute and polished.

- [x] Create `Theme.swift` with color definitions
  - Primary pastel pink
  - Secondary colors
  - Text colors
  - Success, warning, error colors

- [x] Define pastel color palettes for different themes
  - Cotton Candy (pink) - Free
  - Ocean Breeze (blue) - Premium
  - Mint Fresh (green) - Premium
  - Lavender Dream (purple) - Premium

- [x] Create custom button styles
  - Primary button (filled)
  - Secondary button (outlined)

- [x] Create card styling modifier

- [x] Design and add app icon
- [x] Create launch screen

---

## Phase 6: Notifications

Keeping users on track with reminders.

- [x] Create `NotificationManager`
  - Request permission
  - Schedule reminders
  - Cancel reminders
  - Handle notification taps

- [x] Set up `AppDelegate` for notifications
  - Show notifications in foreground
  - Handle notification taps
  - Clear badge on launch

- [x] Test notifications work correctly
  - Create a task with reminder
  - Wait for notification to fire
  - Tap notification to open app

---

## Phase 7: Premium Features (Placeholders)

Setting up for future monetization.

- [x] Add premium status to UserSettings
- [x] Lock extra themes for free users
- [x] Limit categories to 3 for free users
- [x] Create Premium info sheet with feature list

- [x] Add StoreKit 2 integration
  - Created product identifier (`com.planpop.app.premium.lifetime`)
  - Implemented purchase flow with verification
  - Implemented restore purchases
  - Added error handling and loading states

- [x] Add task icons/stickers (premium feature)
  - Icon picker in AddTaskView (premium-gated)
  - Display icons in TaskRow

- [x] Add streak freeze (premium feature)
  - 2 freezes per month for premium users
  - Auto-refresh monthly
  - Auto-use when missing exactly 1 day
  - Display in Settings stats card

- [x] Add achievement badges (gamification)
  - 11 achievements across 4 categories (Tasks, Streaks, Time, Special)
  - AchievementsView with grid layout and progress tracking
  - Auto-unlock on task completion, category creation, premium upgrade
  - Celebration alert when achievement unlocked

- [x] Add smart features (analytics & insights)
  - ProductivityData model tracking completion times and patterns
  - Task.completedAt timestamp for analytics
  - InsightsView with weekly/monthly productivity reports
  - Last 7 days bar chart visualization
  - Peak productivity hour and day detection
  - Smart reminder suggestions based on user patterns

---

## Phase 8: Testing & Polish

Making sure everything works perfectly.

### Testing Checklist

- [x] Test adding a new task
- [x] Test editing an existing task
- [x] Test marking tasks complete/incomplete
- [x] Test deleting tasks
- [x] Test filter buttons work correctly
- [x] Test categories can be created/edited/deleted
- [x] Test category limit for free users
- [x] Test streak increments correctly
- [x] Test streak resets after missing a day
- [x] Test confetti shows when all tasks done
- [x] Test notifications fire at correct time
- [x] Test data persists after closing app
- [x] Test empty states show correctly
- [x] Test on different iPhone sizes

### Polish Checklist

- [x] Add haptic feedback for task completion
- [x] Smooth animations for all interactions
- [x] Verify all text is readable
- [x] Check color contrast meets accessibility standards
- [x] Test VoiceOver accessibility
- [x] Ensure buttons are easy to tap (44pt minimum)

---

## Phase 9: App Store Preparation

Getting ready to publish.

- [x] Write app description
  - App name, subtitle, promotional text
  - Full description with features
  - Keywords for search optimization
- [ ] Create screenshots for different devices
- [ ] Design promotional artwork
- [ ] Set up App Store Connect
- [ ] Configure app privacy details
- [ ] Submit for review

---

## File Structure Reference

```
PlanPop/
├── PlanPopApp.swift          # App entry point
├── Models/
│   ├── Task.swift            # Task data model
│   ├── Category.swift        # Category data model
│   ├── Achievement.swift     # Achievement badges
│   ├── ProductivityData.swift    # Analytics tracking
│   └── UserSettings.swift    # User preferences
├── Views/
│   ├── ContentView.swift     # Main tab container
│   ├── TaskListView.swift    # Task list screen
│   ├── AddTaskView.swift     # Add/edit task form
│   ├── SettingsView.swift    # Settings screen
│   ├── CategoryManagerView.swift  # Manage categories
│   ├── AchievementsView.swift     # Achievement badges grid
│   └── InsightsView.swift         # Productivity insights
├── ViewModels/
│   └── TaskViewModel.swift   # Business logic
├── Managers/
│   ├── PersistenceManager.swift   # Data storage
│   ├── NotificationManager.swift  # Push notifications
│   └── StoreManager.swift         # StoreKit 2 purchases
├── Components/
│   ├── TaskRow.swift         # Single task row
│   ├── EmptyStateView.swift  # Empty state message
│   ├── ConfettiView.swift    # Celebration animation
│   └── StreakBadge.swift     # Streak display
├── Theme/
│   └── Theme.swift           # Colors and styles
├── Products.storekit         # StoreKit configuration
└── Preview Content/
    └── (preview assets)
```

---

## Tips for Beginners

1. **Start small**: Get the basic task list working before adding features
2. **Test often**: Run the app after each change to catch bugs early
3. **Use previews**: SwiftUI previews let you see changes instantly
4. **Read errors**: Xcode error messages tell you what's wrong
5. **Google is your friend**: Copy error messages and search for solutions
6. **Take breaks**: Fresh eyes solve problems faster

---

## Common Issues & Solutions

### "Cannot find 'X' in scope"
- Make sure the file is added to the Xcode project
- Check for typos in the name
- Make sure the struct/class is not marked `private`

### "Type 'X' does not conform to protocol 'Codable'"
- All properties must be Codable types
- Add `Codable` conformance to nested types

### App data disappears
- Make sure you're calling save methods after changes
- Check the UserDefaults keys are consistent

### Notifications don't work
- Check notification permissions in Settings app
- Simulator may not show notifications reliably
- Test on a real device

---

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [SF Symbols App](https://developer.apple.com/sf-symbols/) (for icons)
- [Coolors](https://coolors.co/) (for color palettes)

---

Good luck building PlanPop! You've got this! 🎉
