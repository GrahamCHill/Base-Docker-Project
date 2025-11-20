-- ============================================================
-- AUDIT LOG TABLE — For Compliance (SOC2, ISO, HIPAA, POPIA)
-- ============================================================

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    service TEXT NOT NULL,
    user_id TEXT,
    action TEXT NOT NULL,
    entity TEXT,
    entity_id TEXT,
    request_ip TEXT,
    details JSONB,
    immutable BOOLEAN GENERATED ALWAYS AS (true) STORED
);

-- ============================================================
-- Prevent Updates — Audit logs must be IMMUTABLE
-- ============================================================

CREATE OR REPLACE FUNCTION prevent_audit_updates()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'Audit log entries cannot be updated';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_no_update
BEFORE UPDATE ON audit_log
FOR EACH ROW EXECUTE FUNCTION prevent_audit_updates();

-- ============================================================
-- Prevent Deletes — Audit logs must be APPEND-ONLY
-- ============================================================

CREATE OR REPLACE FUNCTION prevent_audit_deletes()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'Audit log entries cannot be deleted';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_no_delete
BEFORE DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION prevent_audit_deletes();
