# Session Handoff - Nov 30, 2025 (Late Night)

## Completed This Session

**Native iOS App via Capacitor:**
- Added Capacitor to wrap React app as native iOS app
- Created native Swift PDF viewer with PDFKit
- Status bar now hides completely when viewing PDFs (the main goal!)
- App deployed to TestFlight for beta testing
- Bundle ID: `org.pianohouseproject.jazzpicker`

**Native PDF Viewer Features:**
- Full-screen mode with hidden status bar and home indicator
- Auto-hiding controls (2s timeout)
- Swipe gestures for setlist navigation
- Native PDFKit rendering (smoother than PDF.js)

**Web App Improvements:**
- Removed "cached" debug badge from PDF viewer bottom-left
- API service detects native vs web and uses correct backend URL

---

## Current State

**Distribution:**
| Platform | URL/Method |
|----------|------------|
| Web | https://pianohouseproject.org |
| iOS (TestFlight) | Jazz Picker app via TestFlight invite |
| Backend API | https://jazz-picker.fly.dev |

**What Works:**
- Native iOS app with true fullscreen PDF viewing
- TestFlight distribution to testers
- All existing web/PWA features
- Automatic updates via TestFlight

---

## iOS Development Setup

**Prerequisites:**
- Xcode (from Mac App Store)
- Apple Developer account ($99/year)
- CocoaPods: `brew install ruby && gem install cocoapods`

**Build & Run:**
```bash
cd frontend
npm run build
npx cap sync ios
open ios/App/App.xcworkspace  # NOT .xcodeproj!
# In Xcode: Select device, hit Play
```

**Deploy to TestFlight:**
1. In Xcode: Select "Any iOS Device (arm64)"
2. Product → Archive
3. Distribute App → App Store Connect → Upload
4. Wait ~15 min for processing
5. Testers get automatic update notification

---

## What's Next

**Priority:**
1. Setlist Edit mode (drag-drop, search-to-add, key +/-)
2. Spin the Dial context
3. Native setlist navigation in PDF viewer (partially implemented)
4. Offline/cached PDFs for gigs

**iOS-Specific:**
- Test setlist swipe navigation in native viewer
- Consider native song list for even smoother scrolling
- App Store submission (when ready for public release)

---

## Key Files Added/Changed

```
frontend/
├── capacitor.config.ts           # Capacitor configuration
├── ios/
│   └── App/
│       ├── App.xcworkspace       # Open this in Xcode!
│       ├── App/
│       │   ├── AppDelegate.swift      # Plugin registration
│       │   ├── NativePDFPlugin.swift  # Capacitor bridge
│       │   └── NativePDFViewController.swift  # Native PDF viewer
│       ├── Podfile
│       └── Podfile.lock
├── src/
│   ├── plugins/
│   │   └── NativePDF.ts          # TypeScript plugin interface
│   └── services/
│       └── api.ts                # Native platform detection for API URL
```

---

## Technical Notes

- Plugin registration uses delayed dispatch in AppDelegate (0.5s) to ensure bridge is ready
- Native viewer uses PDFKit with `usePageViewController` for smooth paging
- `prefersStatusBarHidden` and `prefersHomeIndicatorAutoHidden` return true
- Web viewer continues to work (fallback if native plugin fails)
- API URL: Native app uses full `https://jazz-picker.fly.dev`, web uses relative URLs
