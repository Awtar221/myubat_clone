# Firebase Team Collaboration + Runbook

## Shared Firebase Project
- Use one shared Firebase project for all teammates.
- Firebase Console -> `Project settings` -> `Users and permissions`:
  - `Editor`: active development and config updates
  - `Viewer`: read-only access

## Mobile Firebase Config Files
- Keep these files in Git:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist` (if iOS is enabled)
- Do not put these files in `.gitignore`.

## Local Run (AVD + Commands)

### AVD requirements
- Android Studio with an emulator image (recommended Pixel API 34+).
- Start emulator before running Flutter.

### Commands
```bash
flutter pub get
flutter run
```

## Gemini Usage Notes
- Runtime key injection:
```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
```
- If key is missing/invalid/quota-exhausted/network-failed:
  - chatbot falls back to mock assistant text
  - assistant reply is still persisted to Firestore
- Current model behavior:
  - primary model: `gemini-2.5-flash`
  - fallback model on model-not-found/404: `gemini-pro`
- `GEMINI_MODEL` runtime override is **not implemented** right now.

## Home Demo Verification (Firestore-backed)

### 1) Create medication master docs
Path: `users/{uid}/medications/{medicationId}`

Minimum fields:
- `name`: string
- `isActive`: true
- `scheduleTimes`: array of `HH:mm` strings, e.g. `['09:00','20:00']`

Optional fields:
- `dosageText`, `instructions`, `daysOfWeek`, `startDate`, `endDate`

Expected result on Home:
- `Today's Medications` shows generated intake rows
- `Today x/y Taken` updates from intake states

### 2) Create one future appointment
Path: `users/{uid}/appointments/{appointmentId}`

Minimum fields:
- `title`: string
- `scheduledAt`: future timestamp
- `status`: `scheduled`

Expected result on Home:
- `Next` card shows nearest upcoming appointment time (or empty state if none)

### 3) Welcome header
Path: `users/{uid}`

Minimum fields:
- `displayName` or `email`

Expected result on Home:
- Header shows `displayName` first, fallback to email prefix

## Firebase Safety Notes
- Intended background writes:
  - Splash touch: updates `lastLoginAt` / `updatedAt` (non-blocking)
  - Home profile-gate fallback: creates minimal `users/{uid}` if missing
  - Home intake ensure: creates missing daily intake docs idempotently
- These writes are expected and required for demo behavior.

## Teammate Checklist (Kelvin / Jaff)
1. `git pull`
2. `flutter pub get`
3. Run without Gemini key (fallback mode): `flutter run`
4. Run with Gemini key: `flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY`
5. Verify Home:
   - dynamic welcome
   - next appointment card
   - today medication list and taken toggle
6. Do **not** modify schema ad-hoc:
   - use `lib/core/firestore/firestore_fields.dart`
   - use `lib/core/firestore/paths.dart`
   - keep all Firestore access in `lib/data/repositories/*`
7. If adding new fields, update:
   - model `fromMap`/`toMap`
   - `docs/firestore_schema.md`
   - rules/indexes if query shape changed
