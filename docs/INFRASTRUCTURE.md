# Infrastructure

## Stack

- **Fly.io** — Flask backend (1 machine), PDF generation, catalog API
- **AWS S3** — Generated PDFs (~$1/mo)
- **Vercel** — Web frontend (free tier)
- **Firebase** — Auth (Apple, Google, email), Firestore (in progress)

## Auth

- **Web**: Firebase Auth (Apple Sign-In, Google, email/password)
- **iOS**: DeviceID (Keychain UUID) — migrating to Firebase

## Deployment

- Backend: `fly deploy`
- Frontend: Auto-deploy on push to main (Vercel)
- iOS: Xcode → App Store Connect
