# PoGetIt – Flutter Quest App

**Explore more. Move more. Complete quests.**

PoGetIt is a Flutter-based Android application prototype that encourages users to explore their surroundings, stay active, develop creative habits, and complete real-world quests.

The application includes four development stages:

- **Day 1:** Running / Jogging
- **Day 2:** Café Exploration
- **Day 3:** Photography and Mindfulness / Reset
- **Day 4:** Personalized Quest Recommendations, Test Profiles, Progression, and XP

The current prototype uses local storage and predefined test profiles to demonstrate the quest experience before backend integration.

---

## Features

### Day 1 – Running & Jogging

- Start, pause, and finish running quests.
- Track elapsed time and GPS distance.
- Validate quest-specific requirements.
- Display Passed, Failed, or Incomplete results.
- Save quest attempt history.

**Running Quests**

| Quest ID | Quest Name | Requirement |
|---|---|---|
| RUN-01 | The 7-Minute Escape | Complete at least 7 minutes and 400 m |
| RUN-02 | The Explorer's Loop | Complete at least 12 minutes and 1 km, finishing within 150 m of the starting point |
| RUN-03 | The Momentum Challenge | Complete sequential 400 m + 800 m + 400 m stages |

### Day 2 – Café Exploration

- GPS-based café check-ins.
- Validate distance from configured café locations.
- Capture photo evidence.
- Track café visit duration.
- Validate visits to multiple distinct cafés.
- Save café attempt events.

**Café Quests**

| Quest ID | Quest Name | Requirement |
|---|---|---|
| CE-E001 | Coffee Break Outside | Check in within 150 m and attach a photo |
| CE-E008 | Quiet Corner | Check in, wait at least 10 minutes, and check out at the same café |
| CE-H001 | Three Café Expedition | Complete check-ins at three distinct designated cafés |

**Café Attempt History**

- View saved café quest events.
- Display Accepted, Rejected, and In Progress statuses.
- View timestamps, GPS distances, and validation reasons.
- Open attached photos in a full-screen viewer.
- Refresh saved history.

### Day 3 – Photography

Photography quests encourage users to observe their surroundings and explore creative techniques.

**Photography Quests**

| Quest ID | Quest Name | Difficulty | Requirement |
|---|---|---|---|
| PHOTO-E001 | Bench Portrait | Easy | Photograph an unoccupied public bench and submit one image |
| PHOTO-M001 | One-Object Reinvention | Medium | Submit three photos of the same object using different angles or lighting |
| PHOTO-H001 | Street Story in Five Frames | Hard | Submit five ordered photos telling a simple story |

**Features**

- Capture and attach photos.
- Track the number of submitted photos.
- Validate required photo counts.
- Display quest completion results.

Photo validation confirms the required number of attachments, not the visual content or authenticity of the photographs.

### Day 3 – Mindfulness / Reset

Mindfulness quests encourage simple, low-pressure activities and everyday habits.

**Mindfulness Quests**

| Quest ID | Quest Name | Difficulty | Requirement |
|---|---|---|---|
| RESET-E001 | Bedside Reset | Easy | Put away three unrelated items near the sleeping area and confirm completion |
| RESET-M001 | Handwritten Words | Medium | Write a page of meaningful everyday words and complete the checklist |
| RESET-H001 | Two-Option Pause | Hard | Create a four-option pause menu, test the options, and record sessions |

**Features**

- Display activity instructions.
- Support checklist-based completion.
- Track session-based requirements where applicable.
- Display completion status.

The prototype does not require users to submit private journals, mood information, or photographs of their home interiors.

### Day 4 – Personalized Quest Recommendations

Day 4 introduces personalized quest suggestions based on user preferences and activity levels.

**Recommendation Inputs**

- Selected interests.
- Activity level.
- Minimum and maximum preferred duration.
- Weekly quest goal.
- Valid quest completion history for progression.

**Supported Interests**

- Running / Jogging
- Café Exploration
- Photography
- Mindfulness / Reset

**Activity Levels**

- Beginner
- Occasionally Active
- Fairly Consistent

**Recommendation Rules**

- Recommend quests matching the selected interests.
- Exclude quests whose known estimated duration exceeds the preferred maximum.
- Prioritize Easy quests for beginners.
- Offer Easy and Medium quests to occasionally active users.
- Allow Hard quests for consistent users when other criteria match.
- Alternate categories for users with multiple interests.
- Use validated Easy Running completions to determine progression.

Quest duration estimates are used for recommendations only. Actual quest completion is determined by each quest's validator.

---

## Five Predefined Test Profiles

The Day 4 prototype includes five fictional profiles to test recommendation behavior.

| Profile | Description | Interests | Activity Level | Duration | Weekly Goal |
|---|---|---|---|---|---|
| A | New to activity | Running | Beginner | 10–15 min | 3 |
| B | Local explorer | Café | Occasional | 20–30 min | 2 |
| C | Creative explorer | Photography | Consistent | 15–30 min | 4 |
| D | Low-energy reset | Mindfulness | Beginner | 5–10 min | 3 |
| E | Mixed interests | Running + Photography | Occasional | 15–30 min | 4 |

### Expected Recommendations

| Profile | Expected Quest IDs |
|---|---|
| A | RUN-01 |
| B | CE-E001, CE-E008 |
| C | PHOTO-E001, PHOTO-M001, PHOTO-H001 |
| D | RESET-E001 |
| E | RUN-01, PHOTO-E001, RUN-02, PHOTO-M001 |

These are the expected initial recommendations using the current prototype catalogue and duration estimates.

### Progression

The intended Running progression rule is:

1. Complete two distinct Easy Running quests with valid results.
2. Unlock Medium Running recommendations.
3. Keep Easy Running quests available after unlocking Medium.

**Current limitation:** The existing catalogue contains only one Easy Running quest (`RUN-01`). A second approved Easy Running quest is required to fully test this progression rule.

### XP and Completion Tracking

The Day 4 prototype includes a progress service for storing quest progression and XP information.

The intended XP rules are:

- Award XP only after successful quest validation.
- Do not award XP for failed or incomplete attempts.
- Do not award XP twice for the same completion.
- Persist completion records so progression can be restored.

The full validator-to-XP integration and duplicate-award prevention still require verification across all quest categories.

---

## Application Navigation

The prototype uses a profile-first testing flow.

**Home Screen**

Displays the five predefined profiles: A, B, C, D, and E.

**Recommended Quests Screen**

After selecting a profile, the app displays:

- Recommended quests.
- Quest difficulty.
- Estimated duration, when available.
- Weekly goal.
- Stored XP total.
- Navigation to the selected quest's activity screen.

**All Quests Screen**

A top-right navigation icon on the Recommended Quests screen opens the Day 1–Day 4 overview:

- Day 1 – Running / Jogging
- Day 2 – Café Exploration
- Day 3 – Photography
- Day 3 – Mindfulness / Reset
- Day 4 – Recommendations

Day 4 is the recommendation and progression stage, not a separate Mindfulness quest category.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Android application UI |
| Dart | Application programming language |
| Geolocator | GPS location tracking |
| Image Picker | Photo capture and attachment |
| Shared Preferences | Local prototype preferences and progress storage |
| Path Provider | Local file storage |
| Material Design 3 | UI components and styling |

---

## Project Structure

The expanded project structure includes the following files and modules:

```text
lib/
├── main.dart
├── data/
│   └── sample_quest_profiles.dart
├── models/
│   ├── running_quest.dart
│   ├── cafe_quest.dart
│   ├── day3_quest.dart
│   └── quest_profile.dart
├── screens/
│   ├── home_screen.dart
│   ├── quest_preferences_screen.dart
│   ├── recommended_quests_screen.dart
│   ├── all_quests_screen.dart
│   ├── sample_profiles_screen.dart
│   ├── quest_list_screen.dart
│   ├── running_screen.dart
│   ├── cafe_list_screen.dart
│   ├── cafe_screen.dart
│   ├── cafe_attempt_events_screen.dart
│   ├── day3_quest_list_screen.dart
│   ├── day3_photography_screen.dart
│   └── day3_reset_screen.dart
├── services/
│   ├── location_service.dart
│   ├── running_tracker.dart
│   ├── quest_recommendation_service.dart
│   └── quest_progress_service.dart
├── validators/
│   ├── running_validator.dart
│   └── cafe_validator.dart
└── storage/
    ├── attempt_repository.dart
    └── cafe_attempt_repository.dart
```

**Note:** This represents the intended integrated project structure based on the development work discussed. Verify the filenames and presence of each file in your local project before treating the structure as final.

---

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- VS Code or Android Studio
- Android emulator or physical Android device
- Git

### Installation

Clone the repository:

```bash
git clone https://github.com/Manoj72639/PoGetIt-Flutter
cd PoGetIt-Flutter
```

Replace `YOUR_USERNAME` with the actual GitHub username or repository owner.

Install dependencies:

```bash
flutter pub get
```

Check the Flutter environment:

```bash
flutter doctor
```

Run the application:

```bash
flutter run
```

### Android Permissions

Location permissions are required for GPS-based quests. Camera access may be required depending on the photo capture workflow.

Configure the necessary permissions in:

`android/app/src/main/AndroidManifest.xml`

---

## Testing

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

### Recommended Manual Tests

**Day 1 – Running**

- Verify elapsed time and distance tracking.
- Verify pass and fail conditions.
- Verify the return-to-start requirement.
- Verify attempt history.

**Day 2 – Café**

- Verify GPS check-in radius.
- Verify photo attachment.
- Verify dwell time.
- Verify distinct café check-ins.
- Verify saved event history.

**Day 3 – Photography and Mindfulness**

- Verify required photo counts.
- Verify checklist completion.
- Verify session recording.
- Verify incomplete and successful results.

**Day 4 – Recommendations**

- Select each predefined profile A–E.
- Compare the recommendations against the expected results.
- Verify mixed-interest balancing.
- Verify progression after valid Easy Running completions once a second Easy quest is available.
- Verify that repeated processing of the same completion does not award duplicate XP.
- Verify stored progress after restarting the app.

Physical-device testing is recommended for GPS accuracy, permission handling, and photo capture.

---

## Quest Validation

Quest results are classified as:

| Status | Meaning |
|---|---|
| Accepted / Passed | Required conditions are satisfied |
| Rejected / Failed | Validation conditions are not met |
| In Progress / Incomplete | The quest is unfinished or evidence is insufficient |

GPS confirms reported location measurements but does not independently prove continuous presence, a purchase, or the user's physical activity type.

Photo attachment confirms evidence submission, not image content or authenticity.

---

## Development Roadmap

- [x] Day 1 – Running / Jogging prototype
- [x] Day 2 – Café Exploration prototype
- [x] Day 3 – Photography and Mindfulness quest definitions and prototype screens
- [x] Day 4 – Quest profile model and predefined test profiles


Checked items indicate implemented or supplied prototype scope, not independently verified production readiness.



---

## Future Improvements

- Firebase Authentication.
- Cloud Firestore integration.
- FastAPI backend for trusted quest completion and XP.
- Duplicate-safe XP transactions.
- Expanded quest catalogue.
- Improved recommendation ranking and progression.
- User profiles and cross-device synchronization.
- Improved GPS reliability.
- Automated integration tests.
- Production-ready Android APK.

---

## Project Status

**Active Development – Flutter Android Prototype**

**Current focus:** Completing Day 4 integration, testing the five predefined profiles, fixing navigation issues, and verifying quest completion, progression, and XP behavior.