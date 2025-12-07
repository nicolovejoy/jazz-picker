# Infrastructure

## Current Stack

| Service | Purpose | Notes |
|---------|---------|-------|
| **Fly.io** | Backend API (Flask, 1 machine) | SQLite, PDF generation |
| **AWS S3** | Generated PDFs | ~$1/mo |
| **Vercel** | Web frontend | Free tier |

## Auth

| Platform | Method |
|----------|--------|
| iOS | DeviceID (Keychain UUID) |
| Web | None |

Planned: Firebase Auth for Apple Sign-In + email/password. See [FIREBASE_AUTH_PLAN.md](FIREBASE_AUTH_PLAN.md).

## Scaling

Single Fly machine is fine for this personal app. If needed later:
- **LiteFS** for distributed SQLite
- **Fly Postgres** for multi-machine
- **Firestore** to replace backend
