# Firestore Schema (MyUbatClone / MyUbatPlus)

## Overview
- All app data is nested under `users/{uid}`.
- UI code must not hardcode Firestore paths or field names.
- Shared schema entry points:
  - `lib/core/firestore/collections.dart`
  - `lib/core/firestore/paths.dart`
  - `lib/core/firestore/firestore_fields.dart`
  - `lib/data/repositories/*`

## Root Document: `users/{uid}`

| Field | Type | Required | Notes |
|---|---|---|---|
| uid | String | Yes | Firebase Auth UID |
| email | String | Yes | Login email |
| displayName | String | Yes | User display name |
| photoURL | String or null | No | Avatar URL |
| createdAt | Timestamp | Yes | Created time, written with `serverTimestamp` |
| updatedAt | Timestamp | Yes | Last update time, written with `serverTimestamp` |
| lastLoginAt | Timestamp | Yes | Last login time, written with `serverTimestamp` |

## Subcollection: `users/{uid}/appointments/{appointmentId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| title | String | Yes | Appointment title |
| startAt | Timestamp | Yes | Start time |
| endAt | Timestamp or null | No | End time |
| status | String | Yes | `scheduled`, `completed`, or `cancelled` |
| hospitalName | String or null | No | Hospital name |
| doctorName | String or null | No | Doctor name |
| locationText | String or null | No | Location text |
| notes | String or null | No | Notes |
| createdAt | Timestamp | Yes | Created time, `serverTimestamp` |
| updatedAt | Timestamp | Yes | Updated time, `serverTimestamp` |

## Subcollection: `users/{uid}/medications/{medicationId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| name | String | Yes | Medication name |
| dosage | String or null | No | Dosage text such as `500mg` |
| instructions | String or null | No | Usage instructions |
| times | List<String> | No | Times list such as `['08:00', '20:00']` |
| startDate | Timestamp or null | No | Start date |
| endDate | Timestamp or null | No | End date |
| isActive | bool | Yes | Active status |
| createdAt | Timestamp | Yes | Created time, `serverTimestamp` |
| updatedAt | Timestamp | Yes | Updated time, `serverTimestamp` |

## Subcollection: `users/{uid}/chats/{chatId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| title | String or null | No | Thread title |
| model | String or null | No | Model id, for example `gemini` |
| createdAt | Timestamp | Yes | Created time, `serverTimestamp` |
| updatedAt | Timestamp | Yes | Updated time, `serverTimestamp` |

## Subcollection: `users/{uid}/chats/{chatId}/messages/{messageId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| role | String | Yes | `user` or `assistant` |
| content | String | Yes | Message content |
| createdAt | Timestamp | Yes | Created time, `serverTimestamp` |

## Settings Document: `users/{uid}/settings/main`

| Field | Type | Required | Notes |
|---|---|---|---|
| notificationsEnabled | bool | Yes | Notification toggle |
| language | String | Yes | `en` or `zh` |
| theme | String | Yes | `system`, `light`, or `dark` |
| updatedAt | Timestamp | Yes | Updated time, `serverTimestamp` |

## Naming Rules
- Use `camelCase` for all fields.
- Use Firestore `Timestamp` for all time fields.
- `createdAt` and `updatedAt` must always use `FieldValue.serverTimestamp()`.
- Paths and collection names must be defined in `collections.dart` and `paths.dart`.

## Write Rules
- Firestore writes must go through `lib/data/repositories/`.
- UI code must not call direct hardcoded path chains like `FirebaseFirestore.instance.collection(...).doc(...)`.
- Any new field must update:
  - `lib/core/firestore/firestore_fields.dart`
  - The model `fromMap` and `toMap` logic
  - This schema document
