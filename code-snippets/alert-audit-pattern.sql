-- SIEM database project - illustrative excerpt only.
-- This is a compact portfolio snippet, not the full project source.

CREATE OR REPLACE FUNCTION calculate_alert_risk(
    severity integer,
    source_reputation integer,
    asset_criticality integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    risk_score integer;
BEGIN
    risk_score :=
        LEAST(100,
            (severity * 10)
          + (source_reputation * 4)
          + (asset_criticality * 6)
        );

    RETURN risk_score;
END;
$$;

CREATE OR REPLACE FUNCTION audit_alert_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- The full project chains audit entries with cryptographic hashes.
    INSERT INTO alert_audit(alert_id, action_name, changed_at)
    VALUES (NEW.id, TG_OP, now());

    RETURN NEW;
END;
$$;

