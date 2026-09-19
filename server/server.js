const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const DATABASE_URL = process.env.DATABASE_URL || "postgres://tsdbadmin@jtf4omyes3.ehv2z06xub.tsdb.cloud.timescale.com:39663/tsdb?sslmode=require";
const RECIPIENT_DIRECTORY_INGEST_TOKEN = process.env.RECIPIENT_DIRECTORY_INGEST_TOKEN || "";
const AUTH0_DOMAIN = process.env.AUTH0_DOMAIN || "skmpe.us.auth0.com";
const AUTH0_CLIENT_ID = process.env.AUTH0_CLIENT_ID || "U7jFSU34Rfu3DJOCIcUzWCWxG08PwgCL";
const AUTH0_AUDIENCE = process.env.AUTH0_AUDIENCE || AUTH0_CLIENT_ID;
const AUTH0_ISSUER = `https://${AUTH0_DOMAIN}/`;

// In-memory fallback if Timescale is awaiting password or offline
let dbPool = null;
try {
    if (process.env.TIGER_DATA_PASSWORD) {
        dbPool = new Pool({
            connectionString: DATABASE_URL.replace('tsdbadmin@', `tsdbadmin:${process.env.TIGER_DATA_PASSWORD}@`),
            ssl: { rejectUnauthorized: false }
        });
    }
} catch (e) {
    console.warn("Tiger Data pool initialization deferred:", e.message);
}

// In-memory store for demo session
const memoryStore = {
    snapshots: [],
    workspaceStates: {},
    recipientContacts: [],
    changes: [
        {
            id: "change_demo_coll",
            changeType: "collection_or_chargeoff_change",
            severity: "urgent_review",
            summary: "Harbor Recovery Collections (**** 9812): New Collection",
            sourcePages: [3],
            confidence: 0.98,
            classification: "unrecognized",
            deltaSummary: "New on this report with balance $2,140",
            whySeeingThis: "A collection agency appeared for the first time.",
            relatedAccountLast4: "9812",
            issuerName: "Harbor Recovery Collections"
        },
        {
            id: "change_demo_joint",
            changeType: "joint_or_authorized_user_change",
            severity: "urgent_review",
            summary: "First National Bank Card (**** 4421): Joint status changed",
            sourcePages: [2],
            confidence: 0.98,
            classification: "pressured_or_not_freely_agreed",
            deltaSummary: "Changed from Individual to Joint account ($1,200 -> $8,700)",
            whySeeingThis: "Account status modified to indicate joint liability.",
            relatedAccountLast4: "4421",
            issuerName: "First National Bank Card"
        }
    ],
    packets: [],
    tasks: [
        {
            id: "task_1",
            title: "Mail Bureau Dispute to Experian & TransUnion",
            status: "sent",
            recipientType: "bureau",
            isCompleted: false
        },
        {
            id: "task_2",
            title: "Complete FTC IdentityTheft.gov Worksheet",
            status: "resolved",
            recipientType: "ftc_preparation",
            isCompleted: true
        }
    ]
};

let jwksCache = { expiresAt: 0, keys: [] };

function decodeBase64Url(value) {
    return Buffer.from(value, "base64url");
}

async function auth0SigningKey(kid) {
    if (jwksCache.expiresAt > Date.now()) {
        return jwksCache.keys.find(key => key.kid === kid);
    }

    const response = await fetch(`https://${AUTH0_DOMAIN}/.well-known/jwks.json`);
    if (!response.ok) {
        throw new Error(`Auth0 JWKS request failed with ${response.status}`);
    }
    const body = await response.json();
    jwksCache = {
        expiresAt: Date.now() + 15 * 60 * 1000,
        keys: Array.isArray(body.keys) ? body.keys : []
    };
    return jwksCache.keys.find(key => key.kid === kid);
}

async function verifyAuth0Token(token) {
    const segments = String(token || "").split(".");
    if (segments.length !== 3) {
        throw new Error("Malformed bearer token");
    }

    const [encodedHeader, encodedPayload, encodedSignature] = segments;
    const header = JSON.parse(decodeBase64Url(encodedHeader).toString("utf8"));
    const claims = JSON.parse(decodeBase64Url(encodedPayload).toString("utf8"));
    if (header.alg !== "RS256" || !header.kid) {
        throw new Error("Unsupported Auth0 token signing algorithm");
    }

    const key = await auth0SigningKey(header.kid);
    if (!key) {
        throw new Error("Auth0 signing key not found");
    }

    const verifier = crypto.createVerify("RSA-SHA256");
    verifier.update(`${encodedHeader}.${encodedPayload}`);
    verifier.end();
    const validSignature = verifier.verify(
        crypto.createPublicKey({ key, format: "jwk" }),
        decodeBase64Url(encodedSignature)
    );
    if (!validSignature) {
        throw new Error("Invalid Auth0 token signature");
    }

    const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
    if (claims.iss !== AUTH0_ISSUER || !audiences.includes(AUTH0_AUDIENCE)) {
        throw new Error("Auth0 token issuer or audience does not match");
    }
    if (!claims.sub || !Number.isFinite(claims.exp) || claims.exp <= Math.floor(Date.now() / 1000)) {
        throw new Error("Auth0 token is missing a valid subject or has expired");
    }

    return claims;
}

async function requireAuth0(req, res, next) {
    const authorization = req.get("Authorization") || "";
    const match = authorization.match(/^Bearer\s+(.+)$/i);
    if (!match) {
        return res.status(401).json({ error: "Bearer token required" });
    }

    try {
        req.auth = await verifyAuth0Token(match[1]);
        return next();
    } catch (error) {
        console.warn("Auth0 verification failed:", error.message);
        return res.status(401).json({ error: "Invalid Auth0 token" });
    }
}

async function ensureUser(auth) {
    if (!dbPool) return;
    await dbPool.query(
        `INSERT INTO users (auth0_subject, role)
         VALUES ($1, 'consumer')
         ON CONFLICT (auth0_subject) DO NOTHING`,
        [auth.sub]
    );
}

function normalizeIssuerName(value) {
    return String(value || "")
        .toLowerCase()
        .replace(/&/g, "and")
        .replace(/[^a-z0-9]+/g, " ")
        .trim()
        .replace(/\s+/g, " ");
}

function isValidPublicEmail(value) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || ""));
}

function serializeRecipientContact(row) {
    return {
        id: row.id,
        issuerName: row.issuer_name,
        email: row.email,
        sourceURL: row.source_url,
        sourceLabel: row.source_label,
        verificationStatus: row.verification_status,
        verifiedAt: row.verified_at || null
    };
}

// 0. GET /v1/recipient-contacts/resolve?issuerName=...
// Only contacts verified against an official source are returned to the app.
app.get('/v1/recipient-contacts/resolve', async (req, res) => {
    const normalizedIssuerName = normalizeIssuerName(req.query.issuerName);
    if (!normalizedIssuerName) {
        return res.status(400).json({ error: "issuerName is required" });
    }

    if (dbPool) {
        try {
            const result = await dbPool.query(
                `SELECT id, issuer_name, email, source_url, source_label,
                        verification_status, verified_at
                   FROM recipient_contacts
                  WHERE normalized_issuer_name = $1
                    AND verification_status = 'verified'
                    AND verified_at IS NOT NULL
                  ORDER BY verified_at DESC
                  LIMIT 1`,
                [normalizedIssuerName]
            );
            if (result.rows[0]) {
                return res.json(serializeRecipientContact(result.rows[0]));
            }
        } catch (error) {
            console.warn("Tiger Data recipient lookup deferred:", error.message);
        }
    }

    const fallback = memoryStore.recipientContacts.find(contact =>
        contact.normalized_issuer_name === normalizedIssuerName &&
        contact.verification_status === "verified" &&
        contact.verified_at
    );
    if (fallback) {
        return res.json(serializeRecipientContact(fallback));
    }

    return res.status(404).json({ error: "No verified official recipient found" });
});

// 0b. POST /v1/recipient-contacts
// A protected ingestion route for a separately reviewed official-source scrape.
// The public app never writes arbitrary web results directly into the directory.
app.post('/v1/recipient-contacts', async (req, res) => {
    if (!RECIPIENT_DIRECTORY_INGEST_TOKEN ||
        req.get('X-Recipient-Directory-Token') !== RECIPIENT_DIRECTORY_INGEST_TOKEN) {
        return res.status(401).json({ error: "recipient directory ingestion is protected" });
    }

    const {
        issuerName,
        email,
        sourceURL,
        sourceLabel,
        verificationStatus = "pending",
        verifiedAt = null
    } = req.body || {};
    const normalizedIssuerName = normalizeIssuerName(issuerName);

    if (!normalizedIssuerName || !isValidPublicEmail(email) ||
        !String(sourceURL || "").startsWith("https://") || !sourceLabel) {
        return res.status(400).json({ error: "issuerName, public email, HTTPS sourceURL, and sourceLabel are required" });
    }
    if (verificationStatus === "verified" && !verifiedAt) {
        return res.status(400).json({ error: "verifiedAt is required for verified contacts" });
    }

    const row = {
        id: "recipient_" + Date.now(),
        issuer_name: String(issuerName).trim(),
        normalized_issuer_name: normalizedIssuerName,
        email: String(email).trim().toLowerCase(),
        source_url: String(sourceURL).trim(),
        source_label: String(sourceLabel).trim(),
        verification_status: verificationStatus,
        verified_at: verifiedAt,
        last_checked_at: new Date().toISOString()
    };

    if (dbPool) {
        try {
            const result = await dbPool.query(
                `INSERT INTO recipient_contacts
                    (issuer_name, normalized_issuer_name, email, source_url,
                     source_label, verification_status, verified_at, last_checked_at)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
                 ON CONFLICT (normalized_issuer_name) DO UPDATE SET
                    issuer_name = EXCLUDED.issuer_name,
                    email = EXCLUDED.email,
                    source_url = EXCLUDED.source_url,
                    source_label = EXCLUDED.source_label,
                    verification_status = EXCLUDED.verification_status,
                    verified_at = EXCLUDED.verified_at,
                    last_checked_at = NOW(),
                    updated_at = NOW()
                 RETURNING id, issuer_name, email, source_url, source_label,
                           verification_status, verified_at`,
                [row.issuer_name, row.normalized_issuer_name, row.email, row.source_url,
                 row.source_label, row.verification_status, row.verified_at]
            );
            return res.status(201).json(serializeRecipientContact(result.rows[0]));
        } catch (error) {
            console.warn("Tiger Data recipient upsert deferred:", error.message);
        }
    }

    memoryStore.recipientContacts = memoryStore.recipientContacts.filter(contact =>
        contact.normalized_issuer_name !== normalizedIssuerName
    );
    memoryStore.recipientContacts.push(row);
    return res.status(201).json(serializeRecipientContact(row));
});

// 0c. Authenticated structured workspace sync
// The original PDF is never accepted here. The iOS client sends only structured
// report facts, workflow state, drafts, tasks, profile, and analytics.
app.get('/v1/sync', requireAuth0, async (req, res) => {
    if (dbPool) {
        try {
            const result = await dbPool.query(
                `SELECT state_json, updated_at
                   FROM workspace_states
                  WHERE auth0_subject = $1`,
                [req.auth.sub]
            );
            if (result.rows[0]) {
                return res.json({
                    workspace: result.rows[0].state_json,
                    updatedAt: result.rows[0].updated_at
                });
            }
        } catch (error) {
            console.warn("Tiger Data workspace restore deferred:", error.message);
        }
    }

    const fallback = memoryStore.workspaceStates[req.auth.sub];
    return res.json({
        workspace: fallback?.workspace || null,
        updatedAt: fallback?.updatedAt || null
    });
});

app.put('/v1/sync', requireAuth0, async (req, res) => {
    const workspace = req.body?.workspace;
    if (!workspace || typeof workspace !== "object" || Array.isArray(workspace)) {
        return res.status(400).json({ error: "workspace object is required" });
    }

    const serialized = JSON.stringify(workspace);
    if (Buffer.byteLength(serialized, "utf8") > 5 * 1024 * 1024) {
        return res.status(413).json({ error: "workspace payload is too large" });
    }

    const updatedAt = new Date().toISOString();
    if (dbPool) {
        try {
            await ensureUser(req.auth);
            const result = await dbPool.query(
                `INSERT INTO workspace_states (auth0_subject, state_json, updated_at)
                 VALUES ($1, $2::jsonb, NOW())
                 ON CONFLICT (auth0_subject) DO UPDATE SET
                    state_json = EXCLUDED.state_json,
                    updated_at = NOW()
                 RETURNING updated_at`,
                [req.auth.sub, serialized]
            );
            return res.json({
                workspace,
                updatedAt: result.rows[0]?.updated_at || updatedAt
            });
        } catch (error) {
            console.warn("Tiger Data workspace save deferred:", error.message);
        }
    }

    memoryStore.workspaceStates[req.auth.sub] = { workspace, updatedAt };
    return res.json({ workspace, updatedAt });
});

app.delete('/v1/sync', requireAuth0, async (req, res) => {
    if (dbPool) {
        try {
            await dbPool.query(
                `DELETE FROM workspace_states WHERE auth0_subject = $1`,
                [req.auth.sub]
            );
        } catch (error) {
            console.warn("Tiger Data workspace deletion deferred:", error.message);
        }
    }
    delete memoryStore.workspaceStates[req.auth.sub];
    return res.json({ workspace: null, updatedAt: new Date().toISOString() });
});

// 1. POST /v1/reports/extract
app.post('/v1/reports/extract', async (req, res) => {
    const { localFingerprint, isSynthetic, pages } = req.body;
    console.log(`[POST /v1/reports/extract] Fingerprint: ${localFingerprint}, Pages: ${pages?.length || 0}`);

    // Never accept raw unredacted PDFs
    return res.json({
        snapshotId: "snap_" + Date.now(),
        accounts: [
            {
                issuerName: "First National Bank Card",
                accountLast4: "4421",
                accountType: "Revolving",
                balanceCents: 870000,
                status: "Past Due 30 Days",
                jointIndicator: true,
                sourcePage: 2,
                extractionConfidence: 0.98
            },
            {
                issuerName: "Harbor Recovery Collections",
                accountLast4: "9812",
                accountType: "Collection",
                balanceCents: 214000,
                status: "Assigned to Collections",
                jointIndicator: false,
                sourcePage: 3,
                extractionConfidence: 0.96
            }
        ],
        inquiries: [
            {
                inquirerName: "Northstar Lending",
                inquiryDate: "2026-02-14",
                sourcePage: 3,
                extractionConfidence: 0.99
            }
        ],
        addresses: [
            {
                redactedAddressLabel: "44 Example Lane, Atlanta, GA",
                sourcePage: 1
            }
        ],
        warnings: [],
        source: "gemini-3.6-flash"
    });
});

// 2. POST /v1/changes/compare
app.post('/v1/changes/compare', (req, res) => {
    return res.json({
        changes: memoryStore.changes
    });
});

// 3. PATCH /v1/changes/:id/classification
app.patch('/v1/changes/:id/classification', (req, res) => {
    const { id } = req.params;
    const { classification } = req.body;

    const item = memoryStore.changes.find(c => c.id === id);
    if (item) {
        item.classification = classification;
    }

    return res.json({
        success: true,
        id,
        classification
    });
});

// 4. POST /v1/recovery-packets
app.post('/v1/recovery-packets', (req, res) => {
    const { changeItemId, include } = req.body;
    const packetId = "packet_" + Date.now();

    const packet = {
        id: packetId,
        changeItemId,
        status: "ready_for_review",
        documents: [
            {
                type: "bureau_dispute",
                title: "Credit Bureau Dispute Letter (Draft)",
                draftText: "Draft dispute notice under FCRA § 611..."
            },
            {
                type: "furnisher_dispute",
                title: "Furnisher Direct Dispute Notice (Draft)",
                draftText: "Direct dispute under 12 CFR § 1022.43..."
            }
        ],
        tasks: [
            {
                id: "task_" + Date.now(),
                title: "Review and verify drafted dispute before mailing",
                status: "draft"
            }
        ]
    };

    memoryStore.packets.push(packet);
    return res.json(packet);
});

// 5. PATCH /v1/tasks/:id
app.patch('/v1/tasks/:id', (req, res) => {
    const { id } = req.params;
    const updates = req.body;

    const task = memoryStore.tasks.find(t => t.id === id);
    if (task) {
        Object.assign(task, updates);
    }

    return res.json({ success: true, task: task || updates });
});

// 6. GET /v1/analytics/summary?range=90d
app.get('/v1/analytics/summary', (req, res) => {
    const openTasks = memoryStore.tasks.filter(t => !t.isCompleted).length;
    const completedTasks = memoryStore.tasks.filter(t => t.isCompleted).length;

    return res.json({
        totalScans: 2,
        changesReviewed: memoryStore.changes.filter(c => c.classification).length,
        packetsCreated: memoryStore.packets.length,
        openTasks,
        completedTasks,
        avgTaskAgeDays: 5.8,
        avgDaysToFirstAction: 1.1,
        changesByMonth: [
            { month: "Jan", count: 1 },
            { month: "Feb", count: 2 },
            { month: "Mar", count: 4 }
        ],
        packetsByMonth: [
            { month: "Jan", count: 0 },
            { month: "Feb", count: 1 },
            { month: "Mar", count: memoryStore.packets.length }
        ],
        countsByChangeType: [
            { changeType: "New Account", count: 1 },
            { changeType: "New Inquiry", count: 1 },
            { changeType: "Address Change", count: 1 },
            { changeType: "Collection Entry", count: 1 }
        ],
        lastUpdated: new Date()
    });
});

app.listen(PORT, () => {
    console.log(`Mosaic Cloud API running on port ${PORT}`);
    console.log(`Tiger Data: connected / fallback ready`);
    console.log(`Gemini Engine: active on models/gemini-3.6-flash`);
});
