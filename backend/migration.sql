-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create components table
CREATE TABLE IF NOT EXISTS components (
    id SERIAL PRIMARY KEY,
    mpn TEXT NOT NULL,
    description TEXT,
    datasheet_url TEXT,
    specs JSONB DEFAULT '{}'::jsonb,
    category TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_components_mpn ON components(mpn);
CREATE INDEX IF NOT EXISTS idx_components_category ON components(category);

-- Full-text search index
CREATE INDEX IF NOT EXISTS idx_components_search ON components
    USING GIN(to_tsvector('english', COALESCE(mpn, '') || ' ' || COALESCE(description, '') || ' ' || COALESCE(category, '')));

-- Trigram index for fuzzy search (optional but useful)
CREATE INDEX IF NOT EXISTS idx_components_mpn_trgm ON components USING GIN (mpn gin_trgm_ops);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_components_updated_at
    BEFORE UPDATE ON components
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS)
ALTER TABLE components ENABLE ROW LEVEL SECURITY;

-- Allow public read access (adjust as needed for your auth requirements)
CREATE POLICY "Allow public read access on components"
    ON components FOR SELECT
    USING (true);

CREATE POLICY "Allow authenticated insert on components"
    ON components FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow authenticated update on components"
    ON components FOR UPDATE
    USING (true);

CREATE POLICY "Allow authenticated delete on components"
    ON components FOR DELETE
    USING (true);
