PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS life_diary_entry (
  entry_id TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL,
  season_number INTEGER NOT NULL CHECK (season_number >= 1),
  session_number INTEGER NOT NULL CHECK (session_number BETWEEN 1 AND 50),
  entry_date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('DRAFT','COMPLETED','REOPENED','DELETED')),
  schema_version TEXT NOT NULL DEFAULT '1.0.0',
  canonical_version TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  completed_at TEXT,
  UNIQUE(owner_user_id, season_number, session_number)
);

CREATE TABLE IF NOT EXISTS life_diary_answer (
  entry_id TEXT NOT NULL REFERENCES life_diary_entry(entry_id) ON DELETE CASCADE,
  question_id TEXT NOT NULL CHECK (question_id IN ('JL-LD-Q01','JL-LD-Q02','JL-LD-Q03','JL-LD-Q04','JL-LD-Q05','JL-LD-Q06','JL-LD-Q07')),
  payload_json TEXT NOT NULL,
  privacy_class TEXT NOT NULL DEFAULT 'PRIVATE_RAW',
  revision_number INTEGER NOT NULL DEFAULT 1 CHECK (revision_number >= 1),
  updated_at TEXT NOT NULL,
  PRIMARY KEY(entry_id, question_id, revision_number)
);

CREATE TABLE IF NOT EXISTS life_diary_revision_event (
  event_id TEXT PRIMARY KEY,
  entry_id TEXT NOT NULL REFERENCES life_diary_entry(entry_id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('CREATED','AUTOSAVED','COMPLETED','REOPENED','REVISITED_Q1_Q2','EXPORTED','SHARED','DELETED')),
  question_id TEXT,
  occurred_at TEXT NOT NULL,
  metadata_json TEXT NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS life_diary_consent_grant (
  grant_id TEXT PRIMARY KEY,
  entry_id TEXT NOT NULL REFERENCES life_diary_entry(entry_id) ON DELETE CASCADE,
  recipient_type TEXT NOT NULL,
  recipient_id TEXT NOT NULL,
  scope TEXT NOT NULL,
  purpose TEXT NOT NULL,
  granted_at TEXT NOT NULL,
  expires_at TEXT,
  revoked_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_life_diary_owner_date ON life_diary_entry(owner_user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_life_diary_event_entry ON life_diary_revision_event(entry_id, occurred_at);

