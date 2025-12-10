# Infrastructure

## Stack

- **Fly.io** — Flask backend (1GB RAM, always-on ~$10/mo), PDF generation, catalog API
- **AWS S3** — Generated PDFs (~$1/mo)
- **Vercel** — Web frontend (free tier)
- **Firebase** — Auth (Apple, Google, email), Firestore (user profiles, setlists)

## Secrets

**Fly.io** (`fly secrets list`):
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` — S3 access
- `FIREBASE_PROJECT_ID` — Firebase project
- `GOOGLE_APPLICATION_CREDENTIALS_JSON` — NOT SET (token verification disabled)

**Vercel**:
- `VITE_BACKEND_URL` — should be `https://jazz-picker.fly.dev`

## Auth

- **Web**: Firebase Auth (Apple, Google, email) → Firestore profiles
- **iOS**: Firebase Auth (Apple Sign-In) → Firestore profiles — Phase 5 in progress
  - Previously: DeviceID (Keychain) — being replaced
  - Setlists: Still Flask API with Firebase UID (Phase 6 will migrate to Firestore)
- **Backend**: Token verification disabled (no GCP credentials)

## Deployment

- Backend: `fly deploy`
- Frontend: Auto-deploy on push to main (Vercel)
- Firestore rules: `firebase deploy --only firestore:rules`
- iOS: Xcode → App Store Connect
