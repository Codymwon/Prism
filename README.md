# Prism

A markdown note-taking and journaling app with bidirectional links, backlink indexing, and an interactive graph view to explore connections between ideas.

---

## Features

- **Markdown Editor**: Live formatting toolbar, bracket auto-pairing, `#tag` indexing, and `[[wikilink]]` note suggestions.
- **Interactive Graph View**: Force-directed graph visualization with node physics, tag filtering, chronological replay, and neighborhood highlighting.
- **Daily Journal**: Dedicated journal tab with daily note creation and habit streak tracking.
- **Fast Search**: Instant full-text search powered by SQLite FTS4.
- **Organization**: Virtual folders, tag filtering, and customizable note templates.
- **Themes & Customization**: Multiple color themes, font scaling, and custom editor preferences.

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Riverpod (v2)](https://riverpod.dev)
- **Database**: [SQLite (`sqflite`)](https://pub.dev/packages/sqflite) with WAL mode and FTS4
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.22+)
- Android Studio / VS Code with Flutter extension
- Android/iOS emulator or connected physical device

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/Codymwon/Meridian.git
   cd Meridian
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (for Riverpod providers and models):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---

## Testing & Quality

Run the test suite:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

---

## Project Structure

```text
lib/
├── core/             # Database, router, theme, and shared services
├── features/
│   ├── editor/       # Markdown editor, live preview, and audio bookmarks
│   ├── folders/      # Virtual folder categorization
│   ├── graph/        # Force-directed graph view and physics engine
│   ├── journal/      # Daily journaling and streak grid
│   ├── notes/        # Note listings, parsing, and repositories
│   ├── onboarding/   # Setup wizard and storage initialization
│   ├── settings/     # App preferences, cloud sync, and vault export
│   └── subscription/ # Pro features and paywall integration
└── shared/           # Design system tokens and reusable UI widgets
```

---

## License

This project is licensed under the MIT License.
