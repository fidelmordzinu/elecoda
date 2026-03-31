# Elecoda Backend

FastAPI backend for electronic component search and AI-generated circuits.

## Setup

1. **Create a virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up environment variables**:
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Fill in your Supabase `DATABASE_URL` and `GEMINI_API_KEY`.

4. **Run database migration** (Supabase SQL Editor):
   Run the SQL in `migration.sql` to create the `components` table with full-text search support.

## Running Locally

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at `http://localhost:8000/docs`.

## Deploying to Render

1. Create a new Web Service on [Render](https://render.com).
2. Connect your GitHub repository.
3. Set the build command: `pip install -r requirements.txt`
4. Set the start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables in Render dashboard:
   - `DATABASE_URL` (from Supabase)
   - `GEMINI_API_KEY` (from Google AI Studio)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Root info |
| GET | `/health` | Health check |
| GET | `/search?q=...&limit=20` | Full-text component search |
| GET | `/component/{id}` | Get component details |
| POST | `/generate_circuit` | Generate circuit with Gemini AI |

## Database Schema

The `components` table (created via `migration.sql`):

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PK | Auto-increment ID |
| mpn | TEXT NOT NULL | Manufacturer part number |
| description | TEXT | Component description |
| datasheet_url | TEXT | Link to datasheet |
| specs | JSONB | Parametric specifications |
| category | TEXT | Component category |
