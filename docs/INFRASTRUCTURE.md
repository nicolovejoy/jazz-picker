# Infrastructure

*Updated: 2025-12-06*

## Current State

| Service | Purpose | Notes |
|---------|---------|-------|
| **Fly.io** | Backend API (Flask, 1 machine) | SQLite, PDF generation |
| **AWS S3** | Generated PDFs | ~$1/mo |
| **Vercel** | Web frontend | Free tier |

## Recent Changes

**2025-12-06:** Scaled Fly to 1 machine (`fly scale count 1`). This should fix SQLite consistency, but octave persistence is still not working - may be a separate issue.

## Auth (Current)

| Platform | Method |
|----------|--------|
| iOS | DeviceID (Keychain UUID) |
| Web | None |

## Auth (Planned)

Firebase Auth will add:
- Apple Sign-In for iOS users
- Email/password for non-Apple users (web)

See [FIREBASE_AUTH_PLAN.md](FIREBASE_AUTH_PLAN.md) for details.

## Scaling Notes

Single Fly machine is fine for this personal app. If needed later:
- **LiteFS** for distributed SQLite
- **Fly Postgres** for proper multi-machine support
- **Firestore** to replace backend entirely

Keep it simple until there's a reason not to.
