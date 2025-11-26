# Session Handoff - Nov 26, 2025

## ✅ Completed This Session

**Frontend UX:**
- Welcome screen with instrument picker (required before browsing)
- LocalStorage persistence for instrument selection
- "Change my instrument" in Settings menu

**Deployment:**
- Frontend on Vercel: https://frontend-ommxkfowi-nico-lovejoys-projects.vercel.app
- Backend on Fly.io: https://jazz-picker.fly.dev
- CORS enabled (allow all origins)
- Env var: `VITE_BACKEND_URL=https://jazz-picker.fly.dev`

## ⚠️ Known Issue (To Test Tomorrow)

PDF loading should work now after env var fix. Need to redeploy and test:
```bash
cd frontend && vercel --prod --yes
```

## 📋 Next Steps

1. Test PDF loading in production
2. Connect GitHub repo to Vercel for CI/CD (Settings → Git)
3. Custom domain (optional)
4. iPad optimizations
5. Setlist feature (LocalStorage)

## 🔧 Current State

- Backend: ✅ Production on Fly.io (CORS enabled)
- Frontend: ✅ On Vercel (needs redeploy for PDF fix)
- Auth: None (public API for now)

## 🔗 URLs

- **Frontend:** https://frontend-ommxkfowi-nico-lovejoys-projects.vercel.app
- **Backend API:** https://jazz-picker.fly.dev
- **Local dev:** http://localhost:5173

## 📝 Environment Variables (Vercel)

| Var | Value |
|-----|-------|
| `VITE_BACKEND_URL` | `https://jazz-picker.fly.dev` |

---

**Agent:** Claude Code (Opus 4.5)
**Date:** Nov 25, 2025
