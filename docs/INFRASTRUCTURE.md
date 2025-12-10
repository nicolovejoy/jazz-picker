# Infrastructure

## Stack

- **Fly.io** — Flask backend (1GB RAM, ~$10/mo)
- **AWS S3** — Generated PDFs (~$1/mo)
- **Vercel** — Web frontend (free tier)
- **Firebase** — Auth + Firestore

## Deployment

- Backend: `fly deploy`
- Frontend: Auto-deploy on push to main (Vercel)
- Firestore rules: `firebase deploy --only firestore:rules`
- iOS: Xcode → App Store Connect

## Auth

- **Web:** Firebase Auth (Apple, Google, email) → Firestore
- **iOS:** Firebase Auth (Apple Sign-In) → Firestore (Phase 5 in progress)
- **Backend:** Token verification disabled

## Secrets

**Fly.io** (`fly secrets list`):
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `FIREBASE_PROJECT_ID`

**Vercel:**
- `VITE_BACKEND_URL` = `https://jazz-picker.fly.dev`
