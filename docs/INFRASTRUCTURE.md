# Infrastructure

## Stack

- **Fly.io** — Flask backend, PDF generation (~$10/mo)
- **AWS S3** — PDF cache (~$1/mo)
- **Vercel** — Web frontend (free)
- **Firebase** — Auth + Firestore (free tier)

## Deployment

- Backend: `fly deploy`
- Frontend: Auto on push to main (Vercel)
- Firestore rules: `firebase deploy --only firestore:rules`
- iOS: Xcode → Archive → App Store Connect

## Secrets

**Fly.io** (`fly secrets list`):
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

**iOS**: GoogleService-Info.plist (gitignored, get from Firebase Console)
