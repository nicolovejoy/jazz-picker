# Session Handoff - Dec 1, 2025

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
- Dynamic build timestamp in header (to the minute)
- TestFlight mention on login page
- New subdomain: jazzpicker.pianohouseproject.org

---

## Current State

**Distribution:**
| Platform | URL/Method |
|----------|------------|
| Web | https://jazzpicker.pianohouseproject.org |
| iOS (TestFlight) | Jazz Picker app via TestFlight invite |
| Backend API | https://jazz-picker.fly.dev |

**What Works:**
- Native iOS app with true fullscreen PDF viewing
- TestFlight distribution to testers
- All existing web/PWA features
- Automatic updates via TestFlight
- Dynamic build time in header

---

## iOS Development Setup

**Prerequisites:**
- Xcode (from Mac App Store)
- Apple Developer account ($99/year)
- CocoaPods: `brew install ruby && gem install cocoapods`
- Add pod to PATH: `export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"`

**Build & Run on Device:**
```bash
cd frontend
npm run build
npx cap sync ios
open ios/App/App.xcworkspace  # NOT .xcodeproj!
# In Xcode: Select your iPad, hit Play
```

**Deploy to TestFlight:**
```bash
cd frontend
npm run build
npx cap sync ios
open ios/App/App.xcworkspace
```
Then in Xcode:
1. Select "Any iOS Device (arm64)" from device dropdown
2. Product → Archive
3. When Organizer opens: Distribute App → App Store Connect → Upload
4. Wait ~15 min for processing in App Store Connect
5. Testers get automatic update notification in TestFlight app

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

**Pending:**
- Eric's GitHub workflow failure (waiting for error details)

---

## Key Files

```
frontend/
├── capacitor.config.ts           # Capacitor configuration
├── vite.config.ts                # Build config (dynamic __BUILD_TIME__)
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
│   ├── components/
│   │   ├── Header.tsx            # Uses __BUILD_TIME__ for version display
│   │   └── AuthGate.tsx          # Login page with TestFlight mention
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
- Build time injected at build via Vite `define` in vite.config.ts
