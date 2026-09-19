-- ============================================================================
-- MOSAIC TIGER DATA (TIMESCALE / POSTGRESQL) SCHEMA
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth0_subject VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'consumer',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1b. API SOURCE-OF-TRUTH WORKSPACE STATE
-- Structured workflow state only; original PDFs remain in the iOS encrypted store.
CREATE TABLE IF NOT EXISTS workspace_states (
    auth0_subject VARCHAR(255) PRIMARY KEY REFERENCES users(auth0_subject) ON DELETE CASCADE,
    state_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. VERIFIED PUBLIC RECIPIENT DIRECTORY
-- This stores official business contact routes only, never report contents.
CREATE TABLE IF NOT EXISTS recipient_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issuer_name VARCHAR(255) NOT NULL,
    normalized_issuer_name VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(320) NOT NULL,
    source_url TEXT NOT NULL,
    source_label VARCHAR(255) NOT NULL,
    verification_status VARCHAR(32) NOT NULL DEFAULT 'pending',
    verified_at TIMESTAMPTZ,
    last_checked_at TIMESTAMPTZ,
    metadata_json JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS recipient_contacts_issuer_lookup
    ON recipient_contacts (normalized_issuer_name);

-- 3. REPORT SNAPSHOTS
CREATE TABLE IF NOT EXISTS report_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    local_fingerprint VARCHAR(128) NOT NULL,
    report_date DATE,
    imported_at TIMESTAMPTZ DEFAULT NOW(),
    page_count INT DEFAULT 1,
    storage_mode VARCHAR(50) DEFAULT 'local_only',
    is_synthetic BOOLEAN DEFAULT FALSE
);

-- 4. REPORT ACCOUNTS
CREATE TABLE IF NOT EXISTS report_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_id UUID REFERENCES report_snapshots(id) ON DELETE CASCADE,
    issuer_name VARCHAR(255) NOT NULL,
    account_last4 VARCHAR(10) NOT NULL,
    account_type VARCHAR(100) NOT NULL,
    opened_date VARCHAR(50),
    balance_cents BIGINT,
    status VARCHAR(100),
    payment_status VARCHAR(100),
    joint_indicator BOOLEAN DEFAULT FALSE,
    source_page INT DEFAULT 1,
    extraction_confidence NUMERIC(4, 3) DEFAULT 0.950,
    local_fingerprint VARCHAR(255)
);

-- 5. REPORT INQUIRIES
CREATE TABLE IF NOT EXISTS report_inquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_id UUID REFERENCES report_snapshots(id) ON DELETE CASCADE,
    inquirer_name VARCHAR(255) NOT NULL,
    inquiry_date VARCHAR(50),
    source_page INT DEFAULT 1,
    extraction_confidence NUMERIC(4, 3) DEFAULT 0.950
);

-- 6. REPORT ADDRESSES
CREATE TABLE IF NOT EXISTS report_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_id UUID REFERENCES report_snapshots(id) ON DELETE CASCADE,
    redacted_address_label VARCHAR(255) NOT NULL,
    address_hash VARCHAR(128) NOT NULL,
    reported_date VARCHAR(50),
    source_page INT DEFAULT 1
);

-- 7. CHANGE ITEMS
CREATE TABLE IF NOT EXISTS change_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    current_snapshot_id UUID REFERENCES report_snapshots(id) ON DELETE CASCADE,
    prior_snapshot_id UUID REFERENCES report_snapshots(id) ON DELETE SET NULL,
    change_type VARCHAR(100) NOT NULL,
    severity VARCHAR(50) DEFAULT 'review',
    summary TEXT NOT NULL,
    source_pages INT[] DEFAULT '{1}',
    confidence NUMERIC(4, 3) DEFAULT 0.950,
    classification VARCHAR(100),
    delta_summary TEXT,
    why_seeing_this TEXT,
    related_account_last4 VARCHAR(10),
    issuer_name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. RECOVERY PACKETS
CREATE TABLE IF NOT EXISTS recovery_packets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    change_item_id UUID REFERENCES change_items(id) ON DELETE CASCADE,
    classification_at_creation VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    item_name VARCHAR(255),
    item_last4 VARCHAR(10),
    source_page INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. PACKET DOCUMENTS
CREATE TABLE IF NOT EXISTS packet_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    packet_id UUID REFERENCES recovery_packets(id) ON DELETE CASCADE,
    document_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    draft_text TEXT NOT NULL,
    source_urls TEXT[],
    generated_by VARCHAR(100) DEFAULT 'gemini-3.6-flash',
    reviewed_by_user_at TIMESTAMPTZ
);

-- 10. TASKS (TIME-SERIES DEADLINE TRACKER)
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    packet_id UUID REFERENCES recovery_packets(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    recipient_type VARCHAR(100) DEFAULT 'bureau',
    due_at TIMESTAMPTZ,
    sent_date TIMESTAMPTZ,
    delivery_method VARCHAR(100),
    reference_number VARCHAR(100),
    expected_response_date TIMESTAMPTZ,
    response_received_date TIMESTAMPTZ,
    status VARCHAR(50) DEFAULT 'draft',
    notes TEXT,
    source_url TEXT,
    rule_version VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 11. AUDIT EVENTS
CREATE TABLE IF NOT EXISTS audit_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata_json JSONB
);

-- ============================================================================
-- 90-DAY SYNTHETIC SEED DATA
-- ============================================================================

INSERT INTO users (id, auth0_subject, role)
VALUES ('a0000000-0000-0000-0000-000000000001', 'auth0|demo_consumer_2026', 'consumer')
ON CONFLICT (auth0_subject) DO NOTHING;

-- Seed December Snapshot (Prior)
INSERT INTO report_snapshots (id, user_id, local_fingerprint, report_date, imported_at, page_count, storage_mode, is_synthetic)
VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'sha256:synth_dec_report_8f3d1b',
    '2025-12-10',
    NOW() - INTERVAL '90 days',
    3,
    'local_only',
    TRUE
) ON CONFLICT DO NOTHING;

-- Seed March Snapshot (Current)
INSERT INTO report_snapshots (id, user_id, local_fingerprint, report_date, imported_at, page_count, storage_mode, is_synthetic)
VALUES (
    'b0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000001',
    'sha256:synth_mar_report_3a9e22',
    '2026-03-15',
    NOW() - INTERVAL '3 days',
    3,
    'local_only',
    TRUE
) ON CONFLICT DO NOTHING;

-- Seed Change Items
INSERT INTO change_items (id, user_id, current_snapshot_id, prior_snapshot_id, change_type, severity, summary, source_pages, confidence, classification, delta_summary, why_seeing_this, related_account_last4, issuer_name)
VALUES
(
    'c0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'collection_or_chargeoff_change',
    'urgent_review',
    'Harbor Recovery Collections (**** 9812): New Collection Account',
    '{3}',
    0.98,
    'unrecognized',
    'New on this report with balance $2,140',
    'A collection agency or debt assignee appeared for the first time.',
    '9812',
    'Harbor Recovery Collections'
),
(
    'c0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'joint_or_authorized_user_change',
    'urgent_review',
    'First National Bank Card (**** 4421): Joint status changed',
    '{2}',
    0.98,
    'pressured_or_not_freely_agreed',
    'Changed from Individual to Joint account ($1,200 -> $8,700)',
    'Account status modified to indicate joint liability.',
    '4421',
    'First National Bank Card'
)
ON CONFLICT DO NOTHING;
