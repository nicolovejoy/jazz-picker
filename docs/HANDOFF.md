# Session Handoff

## What Changed This Session

1. **Phase 3 complete: Offline PDF caching**
   - New file: `Services/PDFCacheService.swift`
   - PDFs cached in Documents/PDFCache/ with JSON manifest
   - ETag-based freshness (conditional GET with If-None-Match)
   - Serves cached PDF immediately while checking for updates

2. **Auto-download setlist songs**
   - When opening a setlist, uncached songs download in background
   - File: `Views/Setlists/SetlistDetailView.swift`

3. **Subtle cache indicators**
   - Small download icon on cached songs (Browse cards, list rows, setlist rows)
   - Files: `Views/Browse/SongCard.swift`, `Views/Browse/SongRow.swift`, `Views/Setlists/SetlistDetailView.swift`

4. **Cache management in Settings**
   - Shows cached song count and storage used
   - Clear Cache button with confirmation
   - File: `Views/Settings/SettingsView.swift`

## Known Issues

- Spin tab placeholder briefly visible before PDF appears
- New keys don't show as pills until app refresh

## Ready to Test

- View some songs → they get cached
- Open a setlist → songs auto-download
- Check Settings → see cache count and size
- Go offline → cached songs still work
- Clear cache → verify it clears

## Next Steps

Phase 4: Shared setlists (backend API + device ID auth)
