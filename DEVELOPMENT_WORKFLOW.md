# Development Workflow

Use Antigravity for both frontend and backend development.

## Git Workflow

```bash
# Start new feature
git checkout main
git pull
git checkout -b feature/descriptive-name

# Make changes, commit, push
git add -A
git commit -m "Description"
git push

# Merge when ready
git checkout main
git merge feature/descriptive-name
git push
```

## Running Locally

**Backend:**
```bash
python3 app.py  # Port 5001
```

**Frontend:**
```bash
cd frontend && npm run dev  # Port 5173
```

## Production

**Backend:** https://jazz-picker.fly.dev (Fly.io)  
**Frontend:** (TBD - Cloudflare Pages or Vercel)

Authentication configured via Fly secrets.
