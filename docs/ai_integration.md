# AI Integration (Gemini + Firestore Chat)

## Runtime configuration
Run with API key provided at runtime:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
```

`GEMINI_API_KEY` is read via `const String.fromEnvironment('GEMINI_API_KEY')`.
No API key is hardcoded.

## Model behavior
- Primary: `gemini-2.5-flash`
- Fallback on model-not-found / 404: `gemini-pro`
- If both fail, UI falls back to mock assistant response.

## How it works
- User message is stored at `users/{uid}/chats/default/messages/{messageId}`.
- App builds compact `UserContext` from repositories (profile + next appointments + today's medications).
- Gemini reply is generated and stored back to Firestore.
- If Gemini fails (missing key, quota, network, API error), mock reply is still stored.

## Risks
- API key can be extracted from client builds.
- Quota can be exhausted.
- User context is sent to model inference.
