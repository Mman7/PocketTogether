# PocketTogether

PocketTogether is a Flutter expense-sharing app backed by Firebase.

## Room flow

Room creation, invite generation, and joining are handled by callable Functions:

- `createRoom` creates the room and its first seven-day invite.
- `createRoomInvite` creates another seven-day invite for the owner.
- `joinRoom` validates the invite and adds the signed-in user idempotently.

Room and invite writes are server-only. The client reads rooms through the signed-in user's `memberIds` membership query.

## Local Firebase emulators

Install the Firebase CLI and authenticate once with `firebase login`. From the repository root:

```powershell
firebase emulators:start
```

Run the Android app against the emulators with:

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

The configured emulator ports are Auth `9099`, Firestore `8080`, Functions `5001`, and the Emulator UI `4000`. Android uses `10.0.2.2` to reach the host machine.

## Checks

```powershell
flutter analyze
flutter test
Push-Location functions
npm test
Pop-Location
```

Deploy callable Functions and Firestore rules only after reviewing the target Firebase project:

```powershell
firebase deploy --only functions,firestore:rules
```
