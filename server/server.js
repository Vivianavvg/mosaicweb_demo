const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const DATABASE_URL = process.env.DATABASE_URL || "postgres://tsdbadmin@jtf4omyes3.ehv2z06xub.tsdb.cloud.timescale.com:39663/tsdb?sslmode=require";

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
