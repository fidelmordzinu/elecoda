-- Migration for Supabase: electronics_db schema
-- This creates the all_components table and category-specific tables
-- matching the existing local PostgreSQL structure.

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Main components table (unified view of all components)
CREATE TABLE IF NOT EXISTS all_components (
    id SERIAL PRIMARY KEY,
    part_number TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    category TEXT,
    attributes JSONB,
    CONSTRAINT unq_all_components_part_number UNIQUE (part_number),
    CONSTRAINT unq_all_components_part_number_manufacturer UNIQUE (part_number, manufacturer)
);

-- Indexes for all_components
CREATE INDEX IF NOT EXISTS idx_all_components_part_number ON all_components(part_number);
CREATE INDEX IF NOT EXISTS idx_all_components_category ON all_components(category);
CREATE INDEX IF NOT EXISTS idx_components_attributes ON all_components USING GIN(attributes);

-- Trigram index for fuzzy search on part_number
CREATE INDEX IF NOT EXISTS idx_all_components_part_number_trgm ON all_components USING GIN (part_number gin_trgm_ops);

-- Category-specific tables for detailed component data
-- Each table stores KiCad library data for that component type

CREATE TABLE IF NOT EXISTS "g-ana" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT,
    sim_library TEXT,
    sim_name TEXT,
    sim_device TEXT,
    sim_pins TEXT
);

CREATE TABLE IF NOT EXISTS "g-art" (
    ipn TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    comments TEXT,
    mpn TEXT
);

CREATE TABLE IF NOT EXISTS "g-asy" (
    ipn TEXT,
    description TEXT,
    mpn TEXT
);

CREATE TABLE IF NOT EXISTS "g-cap" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    capacitance TEXT,
    voltage TEXT,
    material TEXT,
    tolerance TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-con" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    pins DOUBLE PRECISION,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-cpd" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-dio" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    current TEXT,
    voltage TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-fan" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-ics" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-ind" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    inductance TEXT,
    current TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-mcu" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-mpu" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-opt" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    color TEXT,
    "i-forward-max" TEXT,
    "v-forward" TEXT,
    wavelength TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-osc" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    frequency TEXT,
    stability TEXT,
    load TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-pwr" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-reg" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    voltage TEXT,
    current TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-res" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    resistance TEXT,
    voltage TEXT,
    power TEXT,
    tolerance TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-rfm" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-swi" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    form TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

CREATE TABLE IF NOT EXISTS "g-xtr" (
    ipn TEXT,
    mpn TEXT,
    manufacturer TEXT,
    description TEXT,
    symbol TEXT,
    footprint TEXT,
    datasheet TEXT
);

-- Row Level Security (RLS)
-- NOTE: The backend connects via the postgres service role which bypasses RLS.
-- RLS policies below are for direct client access via Supabase client libraries.
ALTER TABLE all_components ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on all_components"
    ON all_components FOR SELECT
    USING (true);

CREATE POLICY "Allow authenticated insert on all_components"
    ON all_components FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update on all_components"
    ON all_components FOR UPDATE
    USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated delete on all_components"
    ON all_components FOR DELETE
    USING (auth.role() = 'authenticated');

-- Apply RLS to all category tables
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'g-ana', 'g-art', 'g-asy', 'g-cap', 'g-con', 'g-cpd',
        'g-dio', 'g-fan', 'g-ics', 'g-ind', 'g-mcu', 'g-mpu',
        'g-opt', 'g-osc', 'g-pwr', 'g-reg', 'g-res', 'g-rfm',
        'g-swi', 'g-xtr'
    ]
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR SELECT USING (true)',
            'read_' || replace(tbl, '-', '_'), tbl
        );
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR ALL USING (auth.role() = ''authenticated'')',
            'write_' || replace(tbl, '-', '_'), tbl
        );
    END LOOP;
END $$;
