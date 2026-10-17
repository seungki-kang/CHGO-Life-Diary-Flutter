-- CHGO PDV-003 Vault Data Model / DB Schema 1.0
-- STATUS: CANDIDATE — NOT EXECUTION-VALIDATED / NOT AN APPLIED MIGRATION
-- PostgreSQL candidate baseline. Diff against DEV-002A/DEV-002B before assigning immutable migration numbers.
-- CRITICAL: Raw Life Diary text MUST NOT be stored in these relational tables.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS pdv;
CREATE SCHEMA IF NOT EXISTS privacy;
CREATE SCHEMA IF NOT EXISTS growth_restricted;
CREATE SCHEMA IF NOT EXISTS audit;

-- This table is a minimal boundary placeholder only if the canonical identity table
-- is not already supplied by the integrated baseline. In integration, replace FK targets
-- with the authoritative identity table; do NOT duplicate the identity SoR.
CREATE TABLE IF NOT EXISTS pdv.identity_ref (
    personal_identity_id uuid PRIMARY KEY,
    lifecycle_state text NOT NULL DEFAULT 'ACTIVE'
        CHECK (lifecycle_state IN ('ACTIVE','RESTRICTED','RECOVERY','CLOSING','CLOSED')),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pdv.vault_provider_profile (
    provider_profile_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_identity_id uuid NOT NULL REFERENCES pdv.identity_ref(personal_identity_id) ON DELETE RESTRICT,
    provider_type text NOT NULL CHECK (provider_type IN ('CHGO_MANAGED','PERSONAL_CLOUD','LOCAL_ONLY')),
    provider_name text,
    capability_profile jsonb NOT NULL DEFAULT '{}'::jsonb,
    credential_secret_ref text, -- secret-manager opaque ref only; NEVER plaintext OAuth token
    status text NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','DISCONNECTED','MIGRATING','REVOKED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_vault_provider_owner ON pdv.vault_provider_profile(owner_identity_id);

CREATE TABLE IF NOT EXISTS pdv.vault (
    vault_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_identity_id uuid NOT NULL REFERENCES pdv.identity_ref(personal_identity_id) ON DELETE RESTRICT,
    provider_profile_id uuid REFERENCES pdv.vault_provider_profile(provider_profile_id) ON DELETE RESTRICT,
    state text NOT NULL DEFAULT 'ACTIVE'
        CHECK (state IN ('ACTIVE','LOCKED','MIGRATING','DELETE_PENDING','DELETED')),
    encryption_profile_ref text NOT NULL,
    retention_policy_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_vault_owner_state ON pdv.vault(owner_identity_id,state);

CREATE TABLE IF NOT EXISTS pdv.vault_entry_metadata (
    entry_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id uuid NOT NULL REFERENCES pdv.vault(vault_id) ON DELETE RESTRICT,
    current_version integer NOT NULL DEFAULT 1 CHECK (current_version >= 1),
    origin_context_ref text, -- provenance only; NEVER ownership/authorization proof
    retention_policy_id text,
    deletion_state text NOT NULL DEFAULT 'ACTIVE'
        CHECK (deletion_state IN ('ACTIVE','DELETE_PENDING','DELETED','RETAINED_RESTRICTED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_vault_entry_vault_created ON pdv.vault_entry_metadata(vault_id,created_at DESC);
CREATE INDEX IF NOT EXISTS ix_vault_entry_deletion ON pdv.vault_entry_metadata(deletion_state);

CREATE TABLE IF NOT EXISTS pdv.vault_entry_version (
    entry_version_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id uuid NOT NULL REFERENCES pdv.vault_entry_metadata(entry_id) ON DELETE RESTRICT,
    content_version integer NOT NULL CHECK (content_version >= 1),
    provider_object_ref text NOT NULL, -- opaque object pointer; not a public durable URL
    content_hash text,
    encrypted_size bigint CHECK (encrypted_size IS NULL OR encrypted_size >= 0),
    key_ref text NOT NULL, -- opaque KMS/key-vault reference only
    cipher_suite_version text NOT NULL,
    consent_policy_version text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(entry_id,content_version)
);

CREATE TABLE IF NOT EXISTS pdv.share_grant (
    grant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_identity_id uuid NOT NULL REFERENCES pdv.identity_ref(personal_identity_id) ON DELETE RESTRICT,
    grantee_type text NOT NULL CHECK (grantee_type IN ('COACH','AUTHORIZED_ACTOR','BOUNDED_ROLE_INSTANCE')),
    grantee_ref text NOT NULL,
    purpose_code text NOT NULL,
    valid_from timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    revoked_at timestamptz,
    ai_processing_allowed boolean NOT NULL DEFAULT false,
    audit_ref text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at IS NULL OR expires_at > valid_from)
);
CREATE INDEX IF NOT EXISTS ix_share_grant_owner ON pdv.share_grant(owner_identity_id);
CREATE INDEX IF NOT EXISTS ix_share_grant_grantee ON pdv.share_grant(grantee_type,grantee_ref,purpose_code);

CREATE TABLE IF NOT EXISTS pdv.share_grant_resource (
    grant_resource_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    grant_id uuid NOT NULL REFERENCES pdv.share_grant(grant_id) ON DELETE CASCADE,
    entry_id uuid NOT NULL REFERENCES pdv.vault_entry_metadata(entry_id) ON DELETE RESTRICT,
    scope_type text NOT NULL CHECK (scope_type IN ('ENTRY','QUESTION','SECTION','DERIVED_VIEW')),
    scope_ref text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(grant_id,entry_id,scope_type,scope_ref)
);

CREATE TABLE IF NOT EXISTS pdv.vault_deletion_job (
    deletion_job_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id uuid NOT NULL REFERENCES pdv.vault(vault_id) ON DELETE RESTRICT,
    requested_by_identity_id uuid NOT NULL REFERENCES pdv.identity_ref(personal_identity_id) ON DELETE RESTRICT,
    state text NOT NULL DEFAULT 'REQUESTED'
        CHECK (state IN ('REQUESTED','AUTHORIZED','OBJECTS','INDEXES','DERIVED_REVIEW','BACKUP_POLICY','COMPLETE','FAILED')),
    policy_ref text NOT NULL,
    failure_code text,
    requested_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz
);

CREATE TABLE IF NOT EXISTS pdv.vault_export_job (
    export_job_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id uuid NOT NULL REFERENCES pdv.vault(vault_id) ON DELETE RESTRICT,
    requested_by_identity_id uuid NOT NULL REFERENCES pdv.identity_ref(personal_identity_id) ON DELETE RESTRICT,
    state text NOT NULL DEFAULT 'REQUESTED'
        CHECK (state IN ('REQUESTED','STEP_UP_REQUIRED','PROCESSING','READY','DELIVERED','EXPIRED','FAILED')),
    step_up_ref text,
    delivery_ref text, -- opaque delivery metadata only; no raw export body
    requested_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    completed_at timestamptz
);

CREATE TABLE IF NOT EXISTS privacy.privacy_decision (
    decision_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    request_ref text NOT NULL,
    actor_ref text,
    purpose_code text NOT NULL,
    policy_version text NOT NULL,
    decision text NOT NULL CHECK (decision IN ('ALLOW','REDACT','DENY','SUPPRESS','HANDOFF')),
    reason_code text,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_privacy_decision_request ON privacy.privacy_decision(request_ref,created_at DESC);

CREATE TABLE IF NOT EXISTS growth_restricted.subject_link (
    subject_link_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    identity_id uuid NOT NULL REFERENCES pdv.identity_ref(personal_identity_id) ON DELETE RESTRICT,
    tenant_ref text,
    purpose_code text NOT NULL,
    subject_key_hash text NOT NULL,
    key_version integer NOT NULL DEFAULT 1 CHECK (key_version >= 1),
    status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','ROTATED','REVOKED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(tenant_ref,purpose_code,subject_key_hash,key_version)
);
CREATE INDEX IF NOT EXISTS ix_subject_link_identity ON growth_restricted.subject_link(identity_id,purpose_code,status);

CREATE TABLE IF NOT EXISTS audit.vault_audit_event (
    audit_event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_ref text,
    action_code text NOT NULL,
    resource_class text NOT NULL,
    resource_ref text,
    purpose_code text,
    decision_ref uuid REFERENCES privacy.privacy_decision(decision_id) ON DELETE SET NULL,
    outcome_code text,
    occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_vault_audit_resource ON audit.vault_audit_event(resource_class,resource_ref,occurred_at DESC);

-- Defense-in-depth RLS for USER/Vault-scoped metadata.
-- Application must set transaction-local app.current_identity to a verified UUID.
-- This does NOT replace service authorization, share/purpose checks, or Privacy Gateway.
ALTER TABLE pdv.vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdv.vault FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS vault_owner_policy ON pdv.vault;
CREATE POLICY vault_owner_policy ON pdv.vault
    USING (owner_identity_id = current_setting('app.current_identity')::uuid)
    WITH CHECK (owner_identity_id = current_setting('app.current_identity')::uuid);

ALTER TABLE pdv.vault_provider_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdv.vault_provider_profile FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS provider_owner_policy ON pdv.vault_provider_profile;
CREATE POLICY provider_owner_policy ON pdv.vault_provider_profile
    USING (owner_identity_id = current_setting('app.current_identity')::uuid)
    WITH CHECK (owner_identity_id = current_setting('app.current_identity')::uuid);

-- Entry access inherits Vault ownership at DB defense-in-depth level.
-- Explicit grantee/share reads should use a separately designed, least-privileged authorized service path;
-- do not weaken this owner policy into broad tenant access.
ALTER TABLE pdv.vault_entry_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdv.vault_entry_metadata FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS entry_owner_policy ON pdv.vault_entry_metadata;
CREATE POLICY entry_owner_policy ON pdv.vault_entry_metadata
    USING (EXISTS (
        SELECT 1 FROM pdv.vault v
        WHERE v.vault_id = vault_entry_metadata.vault_id
          AND v.owner_identity_id = current_setting('app.current_identity')::uuid
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM pdv.vault v
        WHERE v.vault_id = vault_entry_metadata.vault_id
          AND v.owner_identity_id = current_setting('app.current_identity')::uuid
    ));

-- Restricted subject mapping: do not grant ordinary app/pastor/admin roles access.
REVOKE ALL ON SCHEMA growth_restricted FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA growth_restricted FROM PUBLIC;

-- Schema safety assertions (candidate checks).
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n
  FROM information_schema.columns
  WHERE table_schema IN ('pdv','privacy','growth_restricted','audit')
    AND lower(column_name) IN (
      'raw_text','raw_payload','diary_body','reflection_text',
      'spiritual_score','spiritual_rank','spiritual_level','maturity_score'
    );
  IF n > 0 THEN
    RAISE EXCEPTION 'PDV-003 invariant violation: forbidden protected/raw/score column detected';
  END IF;
END $$;

COMMIT;

-- EXECUTION GATES BEFORE ACTIVE:
-- 1) Replace pdv.identity_ref with authoritative integrated identity FK if present.
-- 2) Verify deployed request role is NOT superuser and NOT BYPASSRLS.
-- 3) Use SET LOCAL / set_config(..., true) for verified identity/tenant context per transaction.
-- 4) Execute cross-user/cross-tenant negative tests using production-equivalent pooling/roles.
-- 5) Diff against DEV-002A/DEV-002B; assign immutable migration IDs only after approval.
-- 6) Verify no membership/tenant cascade can delete Personal Vault.
-- 7) Verify raw Life Diary body exists only in encrypted Vault object/provider.
