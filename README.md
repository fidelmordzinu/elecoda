# Elecoda

Flutter + FastAPI app for electronic component search, local inventory, and AI-generated circuits.

## Project Structure

```
elecoda/
├── backend/          # FastAPI + Supabase + Gemini API
├── frontend/         # Flutter + Drift + Provider
└── test/             # Backend (pytest) + Frontend (flutter_test)
```

## Quick Start

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env  # edit with your Supabase + Gemini keys
uvicorn main:app --reload
```

### Frontend

```bash
cd frontend
flutter pub get
dart run build_runner build
flutter run
```

## Services Used

- **Supabase** – PostgreSQL database for component search
- **Gemini API** – AI circuit generation (gemini-1.5-flash, free tier)
- **Render** – Backend hosting (free tier)
- **Drift** – Local SQLite inventory in Flutter

## Documentation

- [Backend README](backend/README.md)
- [Frontend README](frontend/README.md)
