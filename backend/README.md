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
   Run the SQL in `migration.sql` to create all 21 tables (`all_components` + 20 category tables) with full-text search, trigram indexes, and RLS policies.

## Running Locally

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at `http://localhost:8000/docs`.

## Deploying to Render

1. Create a new Web Service on [Render](https://render.com).
2. Connect your GitHub repository.
3. Set the root directory to `backend`.
4. Set the build command: `pip install -r requirements.txt`
5. The `Procfile` handles the start command automatically.
6. Add environment variables in Render dashboard:
   - `DATABASE_URL` (from Supabase, use the pooler URL on port 6543)
   - `GEMINI_API_KEY` (from Google AI Studio)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Root info |
| GET | `/health` | Health check (database connectivity) |
| GET | `/categories` | List component categories with counts |
| GET | `/search?q=...&category=...&limit=20&offset=0` | Full-text component search |
| GET | `/suggestions?q=...&limit=5` | Autocomplete suggestions |
| GET | `/component/{id}` | Get component details |
| GET | `/component/{id}/details` | Get detailed specs from category table |
| POST | `/generate_circuit` | Generate circuit with Gemini AI (rate-limited: 5/min) |

## Database Schema

The database has one main table and 20 category-specific tables for KiCad library data.

### `all_components` (main table)

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PK | Auto-increment ID |
| part_number | TEXT NOT NULL UNIQUE | Manufacturer part number |
| manufacturer | TEXT NOT NULL | Component manufacturer |
| category | TEXT | Category code (e.g., `res`, `cap`, `dio`) |
| attributes | JSONB | Parametric specifications |

### Category tables (`g-res`, `g-cap`, `g-dio`, etc.)

Each category table stores KiCad-specific data (symbol, footprint, datasheet, electrical params) for that component type. They are linked to `all_components` via `part_number`/`mpn`.

| Category | Table | Key Columns |
|----------|-------|-------------|
| Resistors | `g-res` | resistance, voltage, power, tolerance |
| Capacitors | `g-cap` | capacitance, voltage, material, tolerance |
| Diodes | `g-dio` | current, voltage |
| Inductors | `g-ind` | inductance, current |
| Connectors | `g-con` | pins |
| ICs | `g-ics` | symbol, footprint |
| MCUs | `g-mcu` | symbol, footprint |
| Optoelectronics | `g-opt` | color, i-forward-max, v-forward, wavelength |
| Oscillators | `g-osc` | frequency, stability, load |
| Regulators | `g-reg` | voltage, current |
| + 10 more | See `migration.sql` | symbol, footprint, datasheet |
