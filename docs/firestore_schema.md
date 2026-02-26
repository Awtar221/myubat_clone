# Firestore Schema (MyUbatClone / MyUbatPlus)

## Canonical Paths
- `users/{uid}`
- `users/{uid}/appointments/{appointmentId}`
- `users/{uid}/medications/{medicationId}`
- `users/{uid}/medications/{medicationId}/intakes/{intakeId}`
- `users/{uid}/settings/main`
- `users/{uid}/chats/{chatId}`
- `users/{uid}/chats/{chatId}/messages/{messageId}`

## Source of Truth
- Path constants: `lib/core/firestore/collections.dart`, `lib/core/firestore/paths.dart`
- Field constants: `lib/core/firestore/firestore_fields.dart`
- Firestore access: `lib/data/repositories/*`

## Warning
- Do not invent ad-hoc field names in UI or feature code.
- Always add new fields to `lib/core/firestore/firestore_fields.dart` first, then update models/repositories/docs.

## Root Document: `users/{uid}`

| Field | Type | Required | Notes |
|---|---|---|---|
| uid | String | Yes | Firebase Auth uid |
| email | String | Yes | Account email |
| displayName | String | Yes | Display name shown in Home/Profile |
| photoURL | String or null | No | Optional avatar URL |
| profileCompleted | bool | Yes | Profile gate control |
| personal | Map<String, dynamic> or null | No | Personal profile map |
| health | Map<String, dynamic> or null | No | Health profile map |
| emergency | Map<String, dynamic> or null | No | Emergency profile map |
| createdAt | Timestamp | Yes | `serverTimestamp` on create |
| updatedAt | Timestamp | Yes | `serverTimestamp` on updates |
| lastLoginAt | Timestamp | Yes | `serverTimestamp` on login touch |

### `personal` map keys
- `fullName` (String)
- `dateOfBirth` (Timestamp or null)
- `gender` (String or null)
- `phoneNumber` (String or null)
- `address` (String or null)

### `health` map keys
- `bloodType` (String or null)
- `heightCm` (int or null)
- `weightKg` (int or null)
- `allergies` (String or null)
- `medicalConditions` (String or null)

### `emergency` map keys
- `contactName` (String or null)
- `contactNumber` (String or null)

## Appointments: `users/{uid}/appointments/{appointmentId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| title | String | Yes | Appointment title |
| eventDateTime | Timestamp | Yes | Canonical schedule datetime used by reminders |
| scheduledAt | Timestamp | Yes | Canonical appointment datetime |
| startAt | Timestamp | No | Legacy compatibility field mirroring `scheduledAt` |
| endAt | Timestamp or null | No | Optional end time |
| status | String | Yes | `scheduled` \| `completed` \| `cancelled` |
| hospitalName | String or null | No | Optional hospital |
| doctorName | String or null | No | Optional doctor |
| locationName | String or null | No | Canonical location |
| locationText | String or null | No | Legacy compatibility location |
| notes | String or null | No | Optional notes |
| remindersEnabled | bool | Yes | Defaults to `true` when missing (backfill-safe) |
| createdAt | Timestamp | Yes | `serverTimestamp` |
| updatedAt | Timestamp | Yes | `serverTimestamp` |

### Reminders (Notifications)
- `remindersEnabled`: bool, defaults to `true` when missing (backward compatible).
- `eventDateTime`: Timestamp for reminder datetime (fallback to existing datetime fields in model parsing).
- Canonical UI/home datetime usage should go through `appointment.scheduledAt` getter.
- Reminder offsets: `3h`, `1h`, `30m` before event time; offsets already in the past are skipped.

## Medications: `users/{uid}/medications/{medicationId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| name | String | Yes | Medication name |
| dosageText | String or null | No | Canonical dosage text |
| dosage | String or null | No | Legacy compatibility field mirroring `dosageText` |
| instructions | String or null | No | Free text instructions |
| scheduleTimes | List<String> | No | Canonical times in `HH:mm` |
| times | List<String> | No | Legacy compatibility field mirroring `scheduleTimes` |
| intakeDateTime | Timestamp or null | No | Primary reminder time (fallback to `startDate`) |
| daysOfWeek | List<int> | No | Optional recurrence days (`1..7`, Monday=1) |
| startDate | Timestamp or null | No | Optional medication start |
| endDate | Timestamp or null | No | Optional medication end |
| isActive | bool | Yes | Active/inactive medication |
| remindersEnabled | bool | Yes | Defaults to `true` when missing (backfill-safe) |
| createdAt | Timestamp | Yes | `serverTimestamp` |
| updatedAt | Timestamp | Yes | `serverTimestamp` |

### Reminders (Notifications)
- `remindersEnabled`: bool, defaults to `true` when missing (backward compatible).
- `intakeDateTime`: optional Timestamp used for reminder datetime (repository has fallback behavior).
- Reminder offsets: `3h`, `1h`, `30m` before intake time; offsets already in the past are skipped.
- Notes: reminder scheduling/cancellation runs during CRUD flow (create/update/delete) after Firestore write succeeds.

## Medication Intakes: `users/{uid}/medications/{medicationId}/intakes/{intakeId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| scheduledAt | Timestamp | Yes | Intended intake datetime |
| taken | bool | Yes | Taken state |
| takenAt | Timestamp or null | No | Actual taken time |
| createdAt | Timestamp | Yes | `serverTimestamp` |
| updatedAt | Timestamp | No | `serverTimestamp` when toggled |

- Deterministic `intakeId` format: `YYYYMMDD_HHMM`
- Example: `20260218_0900`

## Settings: `users/{uid}/settings/main`

| Field | Type | Required | Notes |
|---|---|---|---|
| notificationsEnabled | bool | Yes | Notification toggle |
| language | String | Yes | Example: `en`, `zh` |
| theme | String | Yes | `system` \| `light` \| `dark` |
| updatedAt | Timestamp | Yes | `serverTimestamp` |

## Chats: `users/{uid}/chats/{chatId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| title | String or null | No | Thread title |
| model | String or null | No | LLM model label |
| createdAt | Timestamp | Yes | `serverTimestamp` |
| updatedAt | Timestamp | Yes | `serverTimestamp` |

## Messages: `users/{uid}/chats/{chatId}/messages/{messageId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| role | String | Yes | `user` \| `assistant` |
| content | String | Yes | Message content |
| createdAt | Timestamp | Yes | `serverTimestamp` |

## Write Ownership Rules
- UI must not call Firestore directly.
- All reads/writes must go through repository classes.
- `createdAt` and `updatedAt` are repository-managed (`FieldValue.serverTimestamp()`).

## Local Reminder Scheduling Notes
- Local reminders are scheduled for each event at:
  - 3 hours before
  - 1 hour before
  - 30 minutes before
- Reminder IDs are deterministic and typed:
  - `baseId = stableHash("$type:$eventId") % 100000`
  - reminder IDs: `baseId + 1`, `baseId + 2`, `baseId + 3`
- Update flow is cancel then reschedule to avoid duplicates.

## Intended Background Writes
- `SplashScreen` non-blocking touch updates `users/{uid}.lastLoginAt` and `updatedAt`.
- `HomeScreen` profile-gate fallback may create `users/{uid}` with minimal profile fields if the profile document is missing.
- Home medication stream ensures today's missing intake docs idempotently in repository (`ensureTodayIntakes`).
- These are intentional and required for Home progress/demo behavior.
