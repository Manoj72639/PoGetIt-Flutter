# PoGetIt – Flutter Quest App

PoGetIt is a Flutter-based Android application prototype that encourages users to explore, stay active, and complete real-world quests.

The project is being developed in stages, beginning with **Running/Jogging** and **Café Exploration** quests.

## Features

### Day 1 – Running & Jogging

- Start, pause, and finish running quests.
- Track elapsed time and GPS distance.
- Validate quest requirements.
- Display Passed, Failed, or Incomplete results.
- Save quest attempt history.

**Running Quests**

| Quest ID | Quest Name | Requirement |
|---|---|---|
| RUN-01 | The 7-Minute Escape | 7 minutes and 400 m |
| RUN-02 | The Explorer's Loop | 12 minutes, 1 km, return within 150 m of starting point |
| RUN-03 | The Momentum Challenge | Complete 400 m + 800 m + 400 m stages |

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
| CE-E008 | Quiet Corner | Check in, wait 10 minutes, and check out at the same café |
| CE-H001 | Three Café Expedition | Complete check-ins at three different designated cafés |

### Café Attempt History

- View saved café quest events.
- Display Accepted, Rejected, and In Progress statuses.
- View timestamps, GPS distances, and validation reasons.
- Open attached photos in a full-screen viewer.
- Refresh saved history.

## Technology Stack

- **Flutter** – Mobile application framework
- **Dart** – Programming language
- **Geolocator** – GPS location tracking
- **Image Picker** – Photo capture
- **Shared Preferences** – Local prototype storage
- **Path Provider** – Local file storage

## Project Structure

```text
lib/
├── main.dart
├── models/
│   ├── running_quest.dart
│   └── cafe_quest.dart
├── screens/
│   ├── home_screen.dart
│   ├── quest_list_screen.dart
│   ├── running_screen.dart
│   ├── cafe_list_screen.dart
│   ├── cafe_screen.dart
│   └── cafe_attempt_events_screen.dart
├── services/
│   ├── location_service.dart
│   └── running_tracker.dart
├── validators/
│   ├── running_validator.dart
│   └── cafe_validator.dart
└── storage/
    ├── attempt_repository.dart
    └── cafe_attempt_repository.dart
```

*The structure above describes the intended integrated prototype. Verify filenames against your local project.*

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
git clone https://github.com/YOUR_USERNAME/PoGetIt-Flutter.git
cd PoGetIt-Flutter
```

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

The application requires location permissions for GPS validation. Camera access may also be required depending on the configured image capture workflow.

Configure the necessary permissions in `android/app/src/main/AndroidManifest.xml`.

## Testing

Run static analysis:

```bash
flutter analyze
```

Run available automated tests:

```bash
flutter test
```

Physical-device testing is recommended for GPS accuracy, permission handling, café radius validation, and photo capture.

## Quest Validation

Quest results are classified as:

- **Accepted / Passed:** Required conditions are satisfied with valid evidence.
- **Rejected / Failed:** A completed validation action does not meet the required conditions.
- **In Progress / Incomplete:** The quest is unfinished or sufficient evidence is unavailable.

GPS confirms reported location measurements but does not prove continuous presence, a purchase, or the user's physical activity type. Photo attachment confirms evidence submission, not the content or authenticity of the image.

## Development Roadmap

- [x] Day 1 – Running/Jogging prototype
- [x] Day 2 – Café Exploration prototype


*Checked items indicate implemented prototype scope, not independently verified production readiness.*

## Current Limitations

- Café locations must be configured before real-world testing.
- GPS accuracy can vary by device and environment.
- Photo evidence is stored locally in the prototype.
- Local history is not synchronized across devices.
- Production authentication, trusted XP awarding, and backend validation are planned for later development.

## Future Improvements

- Firebase Authentication
- Cloud Firestore integration
- Personalized quest recommendations
- XP and rewards system
- Photography and Mindfulness quests
- Improved GPS reliability and testing
- Production-ready Android APK

## Project Status

**Active Development – Flutter Android Prototype**

The current focus is implementing and testing quest validation workflows before full backend integration.

---

**PoGetIt** – Explore more. Move more. Complete quests.