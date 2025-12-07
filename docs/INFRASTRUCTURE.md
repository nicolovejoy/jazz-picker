# Infrastructure Problem Statement

*Created: 2025-12-06*

## Current Issue

Octave offset persistence not working. The iOS app saves to the API, but data doesn't persist because:

- 2 Fly machines run independently with separate SQLite files
- Request may hit machine A (write), then machine B (read) → data appears lost
- This affects any setlist data, not just octave offset

## Current Services

| Service | Purpose | Cost |
|---------|---------|------|
| **Fly.io** | Backend API (Flask) | Free tier |
| **AWS S3** | Generated PDF storage | ~$1/mo |
| **Vercel** | Web frontend hosting | Free tier |
| **Supabase** | *Unused* - configured but no code references | - |

## Database Options

### Option A: Scale to 1 Fly machine
```bash
fly scale count 1
```
- **Pros:** Immediate fix, no code changes
- **Cons:** No redundancy (acceptable for personal app)

### Option B: LiteFS (distributed SQLite)
- **Pros:** Keeps SQLite simplicity, Fly-native
- **Cons:** Setup complexity, eventual consistency

### Option C: Migrate to Postgres
- **Fly Postgres:** Co-located, fast, another service to manage
- **Supabase Postgres:** Already have account, consolidates infra
- **Pros:** Proper multi-machine support, enables future features
- **Cons:** Migration effort, schema changes

## Auth Status

| Platform | Current | Future? |
|----------|---------|---------|
| iOS | DeviceID (Keychain UUID) | Apple Sign-In (backlog) |
| Web | None | None planned |

Device-based auth works for personal use. Apple Sign-In would enable:
- Cross-device setlist sync
- Sharing setlists between band members with identity

## Recommendation

**Short-term:** Scale to 1 machine (`fly scale count 1`) to unblock octave persistence.

**Long-term:** Evaluate whether Apple Sign-In is needed. If yes, Supabase provides both Auth + Postgres in one service.
