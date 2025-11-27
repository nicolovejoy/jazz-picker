# Session Handoff - Nov 26, 2025

## ✅ Completed This Session

**Frontend:**
- Welcome screen with instrument picker
- LocalStorage persistence for instrument preference
- Deployed to Vercel: https://frontend-phi-khaki-43.vercel.app/
- GitHub CI/CD integration with Vercel

**Backend:**
- CORS enabled (all origins)
- Deployed to Fly.io: https://jazz-picker.fly.dev

## 🎯 Decision Made: Simplify Filters

**Eric approved this approach:**

1. **Remove Singer Range filter** from UI
2. **Show only Standard charts**, filtered by Instrument (C, Bb, Eb, Bass)
3. **Hide Alto/Baritone Voice PDFs** until dynamic LilyPond compilation is added

**Rationale:** The current data has incomplete coverage of key/instrument combinations. Once LilyPond runs on the backend, users can generate any song in any key for any instrument dynamically - making pre-generated voice range PDFs unnecessary.

## 📋 Next Steps

1. **Remove Singer Range filter** from Header.tsx
2. **Update backend** to only return Standard variations (exclude Alto/Baritone)
3. **Clean up frontend** types and filtering logic
4. Test all instrument filters work correctly
5. iPad optimizations
6. Future: LilyPond compilation for dynamic key/transposition

## 🔗 URLs

- **Frontend:** https://frontend-phi-khaki-43.vercel.app/
- **Backend:** https://jazz-picker.fly.dev
- **GitHub:** https://github.com/nicolovejoy/jazz-picker

## 📝 Future Vision

```
User Flow (Future):
1. Pick your instrument (Bb trumpet, Eb alto sax, etc.)
2. Browse songs (all in Standard reference)
3. Select a song → See PDF
4. Optional: Change key → LilyPond generates new PDF on demand
5. Optional: App suggests optimal key based on melody range
```

---

**Agent:** Claude Code (Opus 4.5)
**Date:** Nov 26, 2025
