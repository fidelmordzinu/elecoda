# Elecoda Frontend

Flutter app for electronic component search, local inventory management, and AI-generated circuits.

## Setup

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate Drift database code**:
   ```bash
   dart run build_runner build
   ```

3. **Set up environment variables**:
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Set `BACKEND_URL` to your running backend (local or Render URL).

4. **Run the app**:
   ```bash
   flutter run
   ```

## Features

- **Component Search** – Full-text search against the backend component database.
- **Inventory Management** – Add/remove components to local Drift (SQLite) inventory.
- **Circuit Generator** – Describe a circuit in natural language, get AI-generated component list with inventory matching.
- **Schematic Viewer** – Basic visual representation of generated circuits.

## Architecture

```
lib/
├── main.dart                     # App entry point, providers
├── database/
│   ├── database.dart             # Drift table definitions
│   └── app_database.dart         # Database class with CRUD methods
├── models/
│   ├── component_model.dart      # Component data model
│   └── circuit_model.dart        # Circuit response models
├── services/
│   └── api_service.dart          # HTTP client for backend
├── providers/
│   ├── search_provider.dart      # Search state management
│   ├── inventory_provider.dart   # Inventory state management
│   └── circuit_provider.dart     # Circuit generation state
├── screens/
│   ├── home_screen.dart          # Search + results
│   ├── component_detail_screen.dart
│   ├── inventory_screen.dart
│   └── circuit_generator_screen.dart
└── widgets/
    └── schematic_painter.dart    # CustomPainter for circuit drawing
```

## Running with Backend

1. Start the backend (local or deployed on Render).
2. Set `BACKEND_URL` in `.env` to the backend URL.
3. Run `flutter run`.

## Platforms

Tested on Android, iOS, Windows, Linux, macOS, and Web.
