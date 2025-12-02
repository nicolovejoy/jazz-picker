# Session Handoff - Dec 1, 2025

## Just Completed
- Native iOS app with Capacitor + TestFlight distribution
- Full-screen PDF viewing (status bar hidden)
- Dynamic build timestamp (PST)
- Web subdomain: jazzpicker.pianohouseproject.org

## Current Stack
| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS | TestFlight (Jazz Picker) |
| Backend | jazz-picker.fly.dev (Fly.io) |
| Auth/DB | Supabase |
| PDFs | AWS S3 |

## TestFlight Deploy
```bash
cd frontend && npm run build && npx cap sync ios
open ios/App/App.xcworkspace
# Xcode: "Any iOS Device (arm64)" → Product → Archive → Distribute
```

## Pending
- Eric's GitHub workflow failure (awaiting error details)

## Next Up
1. Setlist Edit mode (drag-drop, reorder, key +/-)
2. Spin the Dial (random song)
3. Offline PDF caching
