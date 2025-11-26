# Jazz Picker

A modern web interface for browsing and viewing jazz lead sheets, optimized for iPad music stands.

## 🚀 Quick Start

### 1. Backend (Flask)
```bash
pip install -r requirements.txt
python3 app.py
# Runs on http://localhost:5001
```

### 2. Frontend (React + Vite)
```bash
cd frontend
npm install
npm run dev
# Runs on http://localhost:5173
```

---

## 🛠️ Workflow & Deployment

**Development:**
- **Git:** Feature branches off `main`.
- **Sync PDFs:** `python3 build_catalog.py` then `./sync_pdfs_to_s3.sh`.

**Deployment:**
- **Backend:** `fly deploy` (Fly.io)
- **Frontend:** Cloudflare Pages (Coming soon)
- **S3:** Stores PDFs (`jazz-picker-pdfs`)

**Docker:** `docker-compose up --build`

---

## 📚 Documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: System design, API reference, and Data Model.
- **[ROADMAP.md](ROADMAP.md)**: Current plan and next steps.
