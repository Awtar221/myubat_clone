# Firebase Team Collaboration Guide

## 1) Use One Shared Firebase Project
- Open the target project in Firebase Console (for example `myubatplus`).
- Go to `Project settings` -> `Users and permissions`.
- Add teammates with the minimum required role:
  - `Editor` for active development and configuration work.
  - `Viewer` for read-only access.

## 2) Mobile Config File Sharing
- Android file `android/app/google-services.json` should stay in Git for team consistency.
- If iOS is enabled, `ios/Runner/GoogleService-Info.plist` should also be tracked in Git.
- Do not add these files to `.gitignore`, otherwise teammates cannot run the app easily.

## 3) Secrets That Must Not Be Shared
- Never commit:
  - Gemini API keys
  - Custom backend secrets
  - Private credentials such as service account private keys or JWT secrets
- Manage secrets in secure runtime environments (for example Cloud Functions environment variables).

## 4) Track Rules and Indexes in Repo
- Firestore security rules file: `firestore.rules`
- Firestore indexes file: `firestore.indexes.json`
- Keep both files versioned and reviewed in pull requests to avoid environment drift.

## 5) Index Workflow
- `firestore.indexes.json` currently uses the default empty structure.
- When complex queries require indexes, Firestore Console will show an index creation prompt.
- After creating indexes, export and commit updates to `firestore.indexes.json`.

## 6) Data Write Ownership
- All Firestore writes must go through `lib/data/repositories/`.
- UI pages must not hardcode paths or field name strings to prevent schema drift.
