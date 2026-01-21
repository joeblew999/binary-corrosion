-- Key-Value store schema for corrosion demo
-- CRDTs require non-nullable primary keys

CREATE TABLE IF NOT EXISTS kv (
    key TEXT NOT NULL PRIMARY KEY,
    value TEXT,
    updated_at INTEGER DEFAULT (strftime('%s', 'now'))
);
