-- ============================================================
-- INITIAL DATABASE SETUP
-- This file is executed ONCE when the database is created.
-- ============================================================

-- ================================
-- EXTENSIONS (HIGHLY RECOMMENDED)
-- ================================

-- UUID support for stable primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic hashing functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- JSON indexing performance improvements
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- ================================
-- APPLICATION DATABASES / SCHEMA
-- (Optional — depending on your structure)
-- ================================

-- Create a clean namespace for all tables
CREATE SCHEMA IF NOT EXISTS app;

-- ================================
-- Example user table (optional)
-- This is where authenticated users live
-- and is useful for referencing user_id in audit logs
-- ================================

CREATE TABLE IF NOT EXISTS app.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================
-- Example cases table (optional)
-- Your system handles case files
-- ================================

CREATE TABLE IF NOT EXISTS app.cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES app.users(id),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Automatically update updated_at column
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_cases_timestamp
BEFORE UPDATE ON app.cases
FOR EACH ROW EXECUTE FUNCTION update_timestamp();
