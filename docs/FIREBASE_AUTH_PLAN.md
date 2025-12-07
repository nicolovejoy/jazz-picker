# Firebase Auth + Firestore Plan

## Status

- [x] Phase 1: Web auth
- [ ] Phase 2: Flask token verification
- [ ] Phase 3: Firestore user profiles
- [ ] Phase 4: Firestore setlists
- [ ] Phase 5: iOS auth

## Architecture

```
┌──────────────┐     ┌──────────────┐
│  React/Vite  │     │   iOS App    │
└──────┬───────┘     └──────┬───────┘
       │                    │
       └────────┬───────────┘
                │
         Firebase Auth
                │
       ┌────────┴───────────┐
       │                    │
       ▼                    ▼
   Firestore            Flask (Fly.io)
   - setlists           - catalog API
   - user prefs         - PDF generation
                              │
                              ▼
                           S3 (PDFs)
```

## Key Decisions

- Apple Sign-In on both platforms (required for cross-device sync)
- Instrument in user profile drives auto-transposition
- Catalog stays in Flask/SQLite (read-only, coupled to PDF gen)
- Setlists move to Firestore (real-time sync, offline)

## Firestore Schema

```
users/{uid}
  - instrument: string
  - createdAt: timestamp

setlists/{setlistId}
  - ownerId: string
  - title: string
  - songs: [{ songId, concertKey, octaveOffset }]
  - sharedWith: [uid] (TBD)
  - updatedAt: timestamp
```

## Next Steps

**Phase 2: Flask token verification**
1. Add `firebase-admin` to requirements.txt
2. Middleware to verify ID tokens
3. Extract uid for user context
4. Deploy to Fly.io

**Phase 3: Firestore user profiles**
1. Enable Firestore in console
2. Deploy security rules
3. Create profile on first sign-in
4. Instrument picker in onboarding

**Phase 4: Firestore setlists**
1. Add Firestore SDK to web (`getFirestore`)
2. Replace `setlistService.ts` with Firestore queries
3. Real-time listeners (`onSnapshot`)
4. Remove setlist endpoints from Flask
5. Enable offline persistence

**Phase 5: iOS auth**
1. Add Firebase SDK via SPM (FirebaseAuth, FirebaseFirestore)
2. Create `GoogleService-Info.plist` from Firebase console
3. Implement Apple Sign-In in `AuthService.swift`
4. Replace `SetlistStore.swift` with Firestore
5. Remove DeviceID auth from `APIClient.swift`
