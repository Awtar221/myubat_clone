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

## Local Notifications (Android)
- Notification stack:
  - `flutter_local_notifications`
  - `timezone` + `flutter_timezone`
- Android 13+ requires runtime notification permission (`POST_NOTIFICATIONS`).
- Reminder schedule policy:
  - 3h before event
  - 1h before event
  - 30m before event
- Reminder IDs are deterministic and typed: `stableHash("$type:$eventId") % 100000` with offsets `+1/+2/+3`.
- Notification payload type:
  - medication: `{"type":"medication","eventId":"..."}`
  - appointment: `{"type":"appointment","eventId":"..."}`
- If reminder time is already in the past, it is skipped automatically.

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

### 2.1) Reminder fields for medication/appointment docs
- Medication document (`users/{uid}/medications/{medicationId}`):
  - `remindersEnabled` (bool, default `true` if missing)
  - `intakeDateTime` (Timestamp, optional; fallback to `startDate`)
- Appointment document (`users/{uid}/appointments/{appointmentId}`):
  - `remindersEnabled` (bool, default `true` if missing)
  - `eventDateTime` (Timestamp; canonical reminder datetime)

### 2.2) Notification verification
1. Open app on Android emulator/device and allow notification permission.
2. Create a medication or appointment with a future datetime and reminders enabled.
3. Update the same item and change time:
   - Expected: old reminders canceled, only new reminders remain.
4. Delete the item:
   - Expected: associated reminders are canceled.
5. Debug quick test:
   - Settings -> Developer -> `Test Reminder (1 min)` (debug build only).

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

## Notifications & Reminders (Android Demo)
- Required Android permissions/settings:
  - Android 13+: `Settings -> Apps -> (App) -> Notifications -> Allow`
  - Android 12+: `Settings -> Apps -> Special app access -> Alarms & reminders (Exact alarms) -> Allow`
  - Recommended: disable battery optimization for the app (`Not optimized`) for better reliability.
- Reminder behavior:
  - For each medication/appointment event, reminders are scheduled at `3h`, `1h`, `30m` before event time.
  - Offsets already in the past are skipped.
  - Update flow is cancel then reschedule; delete cancels reminders.
- Quick tests:
  - `Settings -> Developer -> Test Reminder (1 min)` for a near-1-minute notification check.
  - Scaled 3-reminder test:
    - Run: `flutter run --dart-define=DEBUG_REMINDER_SCALE=true`
    - Then tap `Settings -> Developer -> Test 3 reminders (10/20/30s)`
    - Expected: three notifications around `~10s`, `~20s`, `~30s`.
  - Without `DEBUG_REMINDER_SCALE=true`, production offsets stay `3h/1h/30m`.
- Device note:
  - Validate reminders on a real device whenever possible; emulator behavior can differ due to OS policies.

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
