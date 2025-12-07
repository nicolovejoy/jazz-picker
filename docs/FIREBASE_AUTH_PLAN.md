# Firebase Auth Plan

*2025-12-06*

## Goal

Add multi-provider authentication while keeping the rest of the stack simple.

## Problem

- iOS users want Apple Sign-In (native, frictionless)
- Non-Apple users need email/password (web access for band members)
- Both should get the same capabilities (setlists, sync)

## Approach

**Add Firebase Auth. Keep everything else as-is.**

| What | Decision |
|------|----------|
| Auth | Firebase (Apple Sign-In + email/password) |
| Backend | Fly.io (keep Flask, SQLite, PDF gen) |
| Storage | S3 (keep) |
| Database | SQLite on 1 Fly machine (keep) |

Firebase handles identity only. No Firestore migration planned.

## Phases

| # | What | Platform | Status |
|---|------|----------|--------|
| 1 | Firebase Auth | iOS | Planned |
| 2 | Firebase Auth | Web | Planned |

Work in small increments. Each phase is independently deployable.

---

## Phase 1: iOS

### Steps
1. Create Firebase project, enable Auth
2. Configure Apple Sign-In (Firebase + Apple Developer Portal)
3. Add Firebase SDK via SPM
4. Create `AuthService.swift` wrapper
5. Update `APIClient.swift` to send Bearer token
6. Update Flask backend to verify Firebase tokens
7. Add sign-in UI in Settings

### Files
| File | Change |
|------|--------|
| `JazzPicker.xcodeproj` | Add Firebase SPM |
| `GoogleService-Info.plist` | New |
| `JazzPicker/App/JazzPickerApp.swift` | FirebaseApp.configure() |
| `JazzPicker/Services/AuthService.swift` | New |
| `JazzPicker/Services/APIClient.swift` | Bearer token |
| `JazzPicker/Views/Settings/SettingsView.swift` | Sign-in UI |
| `app.py` | Token verification |
| `requirements.txt` | firebase-admin |

---

## Phase 2: Web

### Steps
1. Add Firebase SDK to React app
2. Create AuthContext
3. Add login/register form
4. Update API calls to send token

### Files
| File | Change |
|------|--------|
| `frontend/package.json` | firebase |
| `frontend/src/firebase.ts` | New |
| `frontend/src/contexts/AuthContext.tsx` | New |
| `frontend/src/components/LoginForm.tsx` | New |
| `frontend/src/App.tsx` | AuthProvider |
