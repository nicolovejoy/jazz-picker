# Development Workflow

This project uses **separate AI tools for backend and frontend development** to avoid conflicts and maintain clean separation of concerns.

## Tool Assignment

### Claude CLI (this tool)
**Scope:** Backend development only
- Python/Flask backend (`app.py`, `build_catalog.py`)
- API endpoints
- S3 integration
- Backend utilities and scripts
- Backend documentation

### Antigravity
**Scope:** Frontend development only
- React/TypeScript frontend (`frontend/`)
- Components, hooks, and UI
- CSS/styling
- Frontend utilities
- Frontend-specific documentation

## Git Branching Strategy

To prevent merge conflicts when using different tools:

### Branch Naming Convention

```
main                    # Stable code, both backend and frontend
├── backend/*           # Claude CLI branches (backend work)
│   ├── backend/api-improvements
│   ├── backend/s3-optimization
│   └── backend/bug-fixes
│
└── frontend/*          # Antigravity branches (frontend work)
    ├── frontend/pdf-viewer
    ├── frontend/ui-improvements
    └── frontend/bug-fixes
```

### Workflow Rules

1. **Starting new work:**
   - Backend work (Claude CLI): Create branch from `main` with `backend/` prefix
     ```bash
     git checkout main
     git pull
     git checkout -b backend/feature-name
     ```
   - Frontend work (Antigravity): Create branch from `main` with `frontend/` prefix
     ```bash
     git checkout main
     git pull
     git checkout -b frontend/feature-name
     ```

2. **During development:**
   - Claude CLI only works on `backend/*` branches
   - Antigravity only works on `frontend/*` branches
   - Never mix backend and frontend changes in the same branch

3. **Merging to main:**
   - Test locally to ensure backend + frontend work together
   - Create PR/merge when feature is complete
   - Pull latest `main` before starting next feature

4. **Cross-cutting changes:**
   - If both backend and frontend need updates:
     - Create `backend/feature-name` branch first
     - Merge to `main`
     - Then create `frontend/feature-name` branch from updated `main`

## Quick Reference

### Current Branch Check
```bash
git branch --show-current
```

### Claude CLI Session Start
```bash
# Ensure you're on a backend branch
git checkout -b backend/my-feature

# Or switch to existing backend branch
git checkout backend/existing-feature
```

### Antigravity Session Start
```bash
# Ensure you're on a frontend branch
git checkout -b frontend/my-feature

# Or switch to existing frontend branch
git checkout frontend/existing-feature
```

### Switching Tools Mid-Development
If you need to switch from one tool to another:

```bash
# Save current work
git add .
git commit -m "WIP: Description of changes"
git push

# Switch to the other tool's branch
git checkout <other-branch>
```

## File Ownership

### Backend (Claude CLI)
```
app.py
build_catalog.py
catalog.json
*.md (project docs, not frontend/)
lilypond-data/
venv/
requirements.txt
Dockerfile
docker-compose.yml
```

### Frontend (Antigravity)
```
frontend/src/
frontend/public/
frontend/index.html
frontend/package.json
frontend/tsconfig.json
frontend/vite.config.ts
frontend/tailwind.config.js
frontend/README.md
```

### Shared (coordinate changes)
```
README.md (update both sections)
ARCHITECTURE.md (architectural changes)
.gitignore
```

## Example Workflows

### Scenario 1: Adding a new API endpoint
**Tool:** Claude CLI
**Branch:** `backend/new-endpoint`
```bash
git checkout -b backend/new-endpoint
# Claude CLI makes changes to app.py
git add app.py
git commit -m "Add new endpoint for feature X"
git push
# Merge to main when ready
```

### Scenario 2: Improving PDF viewer UI
**Tool:** Antigravity
**Branch:** `frontend/pdf-viewer-enhancements`
```bash
git checkout -b frontend/pdf-viewer-enhancements
# Antigravity makes changes to frontend/src/components/PDFViewer.tsx
git add frontend/
git commit -m "Add fullscreen and swipe tutorials to PDF viewer"
git push
# Merge to main when ready
```

### Scenario 3: New feature requiring both backend and frontend
**Tools:** Both (sequential)
**Approach:**
```bash
# Step 1: Backend changes (Claude CLI)
git checkout -b backend/feature-x-api
# ... backend work ...
git commit -m "Add API support for feature X"
git push
# Merge backend/feature-x-api to main

# Step 2: Frontend changes (Antigravity)
git checkout main
git pull  # Get the merged backend changes
git checkout -b frontend/feature-x-ui
# ... frontend work ...
git commit -m "Add UI for feature X"
git push
# Merge frontend/feature-x-ui to main
```

## Benefits

- **No conflicts:** Tools never work on the same files simultaneously
- **Clear history:** Git log shows whether change is backend or frontend
- **Easy rollback:** Can revert backend or frontend changes independently
- **Clean separation:** Each tool stays in its domain of expertise

## Current Status

**Active Branch:** `main` (recently pushed frontend PDF enhancements)

**Recommendation:**
- For next backend work: `git checkout -b backend/<feature-name>`
- For next frontend work: `git checkout -b frontend/<feature-name>` (use Antigravity)
