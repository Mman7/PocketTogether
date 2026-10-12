# Flutter Finance App — Architecture

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Cloud Messaging (FCM)
- Cubit
- GoRouter

## Architecture

This project uses a **Feature-first + Layered Architecture**.

```text
UI / Page
   ↓
Cubit
   ↓
Repository
   ↓
Repository Implementation
   ↓
Firebase
```

### Main Layers

#### Presentation

Contains UI and state management.

```text
presentation/
├── cubit/
├── pages/
└── widgets/
```

- `pages/` — Screens
- `widgets/` — Reusable UI components
- `cubit/` — State management and application flow

#### Models

Defines the application's data structures.

```text
models/
├── expense.dart
├── room.dart
└── profile.dart
```

#### Data

Handles data access.

```text
data/
├── expense_repository.dart
└── expense_repository_impl.dart
```

- `Repository` — Defines available operations
- `RepositoryImpl` — Implements Firebase/Firestore operations

#### Services

Contains reusable business logic that should not belong inside the UI or Cubit.

Example:

```text
settlement/
└── services/
    └── settlement_calculator.dart
```

## Project Structure

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── firebase/
│   ├── notifications/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── rooms/
│   ├── expenses/
│   ├── statistics/
│   ├── settlement/
│   ├── activity/
│   └── profile/
│
└── shared/
    ├── enums/
    └── extensions/
```

## Data Flow

For example, adding an expense:

```text
AddExpensePage
      ↓
ExpensesCubit
      ↓
ExpenseRepository
      ↓
ExpenseRepositoryImpl
      ↓
Cloud Firestore
```

Realtime data flows back through the same layers:

```text
Firestore
    ↓
Repository
    ↓
Cubit
    ↓
State
    ↓
UI
```

## Principles

- UI should not directly access Firestore.
- Cubit manages state and application flow.
- Repository handles data access.
- Models represent application data.
- Complex business logic should be separated into services.
- Firebase Security Rules handle authorization and data protection.
- Keep the architecture simple and avoid unnecessary abstraction.

features/
└── expenses/
    ├── data/
    │   ├── expense_repository.dart
    │   └── expense_repository_impl.dart
    │
    ├── models/
    │   └── expense.dart
    │
    └── presentation/
        ├── cubit/
        │   ├── expense_cubit.dart
        │   └── expense_state.dart
        │
        ├── pages/
        │   ├── expenses_page.dart
        │   ├── add_expense_page.dart
        │   └── expense_detail_page.dart
        │
        └── widgets/
            ├── expense_card.dart
            └── category_bottom_sheet.dart

Each feature keeps its Cubit under `presentation/cubit/`. Auth uses its Cubit
to call `AuthRepository` and emit loading, success, and failure states. Other
feature Cubits should be added as their repository-backed workflows are built.