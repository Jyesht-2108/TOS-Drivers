# TOS Driver App - Project Structure

This Flutter application follows a feature-first architecture with clear separation of concerns.

## Folder Structure

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # Root application widget
├── core/                     # Core application infrastructure
│   ├── theme/               # Theme configuration (Material 3)
│   ├── routing/             # Navigation and routing (GoRouter)
│   └── constants/           # Application-wide constants
├── models/                   # Data models
│   ├── user.dart
│   ├── route.dart
│   ├── student.dart
│   ├── trip.dart
│   └── attendance_record.dart
├── services/                 # Business logic and mock services
│   ├── auth_service.dart
│   ├── route_service.dart
│   ├── trip_service.dart
│   └── attendance_service.dart
├── features/                 # Feature modules
│   ├── auth/                # Authentication feature
│   │   ├── screens/
│   │   └── widgets/
│   ├── routes/              # Route management feature
│   │   ├── screens/
│   │   └── widgets/
│   ├── trip/                # Trip management feature
│   │   ├── screens/
│   │   └── widgets/
│   └── attendance/          # Attendance tracking feature
│       ├── screens/
│       └── widgets/
└── shared/                   # Shared widgets and utilities
    └── widgets/
```

## Dependencies

- **flutter_riverpod**: State management
- **go_router**: Declarative routing
- **shared_preferences**: Local data persistence

## Design System

- Material 3 design system
- Deep blue primary color (#1565C0)
- White backgrounds for high contrast
- Optimized for outdoor visibility
