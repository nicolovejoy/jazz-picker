# Infrastructure

## Stack

- **Fly.io** — Flask backend (1 machine), PDF generation, catalog API
- **AWS S3** — Generated PDFs (~$1/mo)
- **Vercel** — Web frontend (free tier), env vars for Firebase config
- **Firebase** — Auth (Apple, Google, email), Firestore (user profiles, setlists)

## Auth

- **Web**: Firebase Auth → Firestore user profiles + setlists
- **iOS**: DeviceID (Keychain UUID) — migrating to Firebase in Phase 5

## Deployment

- Backend: `fly deploy`
- Frontend: Auto-deploy on push to main (Vercel)
- Firestore rules: `firebase deploy --only firestore:rules`
- iOS: Xcode → App Store Connect
