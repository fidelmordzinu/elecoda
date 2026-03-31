CREATE TABLE IF NOT EXISTS components (
    id SERIAL PRIMARY KEY,
    mpn TEXT NOT NULL,
    description TEXT,
    datasheet_url TEXT,
    specs JSONB,
    category TEXT
);

CREATE INDEX IF NOT EXISTS idx_components_mpn ON components(mpn);
CREATE INDEX IF NOT EXISTS idx_components_category ON components(category);

CREATE INDEX IF NOT EXISTS idx_components_search ON components
    USING GIN(to_tsvector('english', COALESCE(mpn, '') || ' ' || COALESCE(description, '') || ' ' || COALESCE(category, '')));
