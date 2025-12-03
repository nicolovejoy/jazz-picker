# Debug Plan: TestFlight PDFs Not Rendering

## ✅ RESOLVED - Dec 3, 2025

**Root Cause:** Plugin registration timing issue. The `NativePDFPlugin` was being registered with a 0.5s delay in `didFinishLaunchingWithOptions`, which caused race conditions where JS called the plugin before it was registered.

**Fix Applied:**
1. Moved plugin registration to `applicationDidBecomeActive` (fires after UI is ready)
2. Added check for view in window hierarchy before presenting
3. Added handling for double-calls (dismiss existing before re-presenting)

**Files Changed:**
- `frontend/ios/App/App/AppDelegate.swift` - New registration timing
- `frontend/ios/App/App/NativePDFPlugin.swift` - Retry logic, double-call handling
- `frontend/ios/App/App/NativePDFViewController.swift` - Debug logging, full bleed attempts

---

## Original Problem Summary (for reference)

PDFs were not displaying in the TestFlight iOS app. Both Build 8 (with offline caching) and Build 9 (after revert, current code) failed to render PDFs.

## What Works

- Backend API is healthy (`https://jazz-picker.fly.dev/health` returns OK)
- PDF generation works (curl to `/api/v2/generate` returns valid S3 URLs)
- Songs list API works
- Web version (presumably works - needs confirmation)

## What's Broken

- Native iOS PDF viewer shows nothing (or error?) when trying to view a PDF
- Issue exists in both Build 8 and Build 9

## Key Questions to Answer

1. **What exactly do you see when tapping a song?**
   - Blank white screen?
   - Loading spinner that never stops?
   - Error message?
   - Black screen?
   - Does the close button (X) appear?

2. **Does the web version work?**
   - Test at https://jazzpicker.pianohouseproject.org
   - Can you view PDFs there?

3. **Is this ALL songs or specific songs?**
   - Try "502 Blues" - known working PDF
   - Try a song you haven't opened before

4. **Network connectivity from the app?**
   - Is the song list loading? (proves API connectivity)
   - Any iOS settings blocking the app's network access?

5. **When did it last work?**
   - Did PDFs ever work in TestFlight?
   - What build number was the last working version?

## Debugging Steps

### Step 1: Check Xcode Console Logs

Connect iPad to Mac, open Xcode, and run the app (or attach to running TestFlight app):
1. Window → Devices and Simulators
2. Select your iPad
3. Click "Open Console"
4. Filter for "Jazz" or "PDF"
5. Try to open a PDF and capture any errors

Look for:
- Network errors
- Plugin registration failures
- URL loading errors
- Any Swift crashes

### Step 2: Test with Safari Web Inspector

If the issue is in the WebView layer:
1. Settings → Safari → Advanced → Web Inspector (ON) on iPad
2. Open Jazz Picker app
3. On Mac: Safari → Develop → [iPad name] → Jazz Picker
4. Check Console tab for JavaScript errors

### Step 3: Verify Capacitor Plugin Registration

Check `AppDelegate.swift`:
```swift
// Should have NativePDFPlugin registered
```

Check that `NativePDFPlugin.swift` and `NativePDFViewController.swift` are in the Xcode project target.

### Step 4: Test PDF URL Directly

1. Generate a PDF URL via curl
2. Open that URL directly in Safari on iPad
3. Does it load? If yes, the issue is in the native viewer

### Step 5: Add Debug Logging

In `NativePDFPlugin.swift`, add logging:
```swift
print("NativePDF: open called with URL: \(urlString)")
```

In `NativePDFViewController.swift`:
```swift
print("NativePDF: loadPDF called")
print("NativePDF: URL = \(pdfURLString)")
// In the async block:
print("NativePDF: Document loaded: \(document != nil)")
```

Rebuild and check Xcode console.

## Likely Culprits

1. **S3 presigned URL expiry** - URLs expire after 15 min, but this shouldn't cause total failure

2. **App Transport Security** - iOS blocking HTTP or untrusted HTTPS
   - Check `Info.plist` for ATS settings

3. **Plugin not registered** - Capacitor plugin bridge broken
   - Would see "Plugin not found" in JS console

4. **PDF loading failure** - `PDFDocument(url:)` returns nil
   - Network issue, SSL issue, or malformed URL

5. **View controller not presented** - Plugin opens but VC never appears
   - Would see close button but no PDF content

## Files to Investigate

| File | Purpose |
|------|---------|
| `frontend/ios/App/App/NativePDFPlugin.swift` | Capacitor bridge |
| `frontend/ios/App/App/NativePDFViewController.swift` | PDF display |
| `frontend/ios/App/App/AppDelegate.swift` | Plugin registration |
| `frontend/ios/App/App/Info.plist` | App permissions, ATS |
| `frontend/src/components/PDFViewer.tsx` | React component that calls native |
| `frontend/src/plugins/NativePDF.ts` | TypeScript plugin interface |

## Quick Sanity Checks

```bash
# Verify backend is up
curl https://jazz-picker.fly.dev/health

# Generate a test PDF
curl -X POST https://jazz-picker.fly.dev/api/v2/generate \
  -H "Content-Type: application/json" \
  -d '{"song":"502 Blues","concert_key":"a","transposition":"C","clef":"treble"}'

# Copy the returned URL and test in browser
```

## After Debugging

Once root cause is found, update this document with:
- [ ] Root cause
- [ ] Fix applied
- [ ] Build number that fixed it
