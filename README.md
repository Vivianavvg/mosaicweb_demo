# Mosaic — Credit Health iOS Agent

Mosaic is a privacy-first, native iPhone application for the **FinanceHER** hackathon track that helps consumers detect, understand, and organize actions around credit report changes.

```text
import credit-report PDF (or synthetic fixture)
  -> extract & redact report facts on-device
  -> identify normalized report differences with source pages
  -> user classifies each item (recognized, unrecognized, pressured, not sure, ignore)
  -> generate source-linked recovery packets & dispute drafts
  -> track statutory FCRA deadlines and certified mail
  -> live progress analytics powered by Tiger Data & Timescale
```

---

## Requirements

- Xcode 16+
- iOS 17.0+ (iOS 16.0+ backward compatible)
- macOS with Swift 5.9+

---

## Quick Start & Running the App

1. Open the project in Xcode:
   ```bash
   open Mosaic.xcodeproj
   ```
2. Select any iPhone simulator (e.g. **iPhone 17** or **iPhone 18 Pro**) and press **Cmd + R**.
3. On the Welcome screen:
   - Tap **"Use Synthetic Demo Data"** to instantly test the end-to-end judging flow without needing login setup.
   - Or tap **"Continue with Auth0"** to sign in with Auth0 Universal Login.

---

## Credentials & Configuration Guide

### 1. Auth0 Setup
- **Domain**: `skmpe.us.auth0.com`
- **Client ID**: `U7jFSU34Rfu3DJOCIcUzWCWxG08PwgCL`
- **Bundle Identifier**: `com.hackhers.mosaic`
- **Apple Team ID**: `L22992699P`

**In the Auth0 Management Dashboard** ([manage.auth0.com](https://manage.auth0.com/)):
Go to **Applications ▸ Applications ▸ [Your App] ▸ Settings** and ensure:
1. **Application Type**: Native
2. **Token Endpoint Authentication Method**: None
3. **Allowed Callback URLs**:
   ```text
   https://skmpe.us.auth0.com/ios/com.hackhers.mosaic/callback, com.hackhers.mosaic://skmpe.us.auth0.com/ios/com.hackhers.mosaic/callback
   ```
4. **Allowed Logout URLs**:
   ```text
   https://skmpe.us.auth0.com/ios/com.hackhers.mosaic/callback, com.hackhers.mosaic://skmpe.us.auth0.com/ios/com.hackhers.mosaic/callback
   ```

To reconfigure or update Auth0 keys via CLI:
```bash
swift Configure.swift \
  --domain skmpe.us.auth0.com \
  --client-id U7jFSU34Rfu3DJOCIcUzWCWxG08PwgCL \
  --bundle-id com.hackhers.mosaic \
  --team-id L22992699P
```

---

### 2. Google Gemini API
- **Model**: `models/gemini-3.6-flash`
- **API Key**: Already configured and active in `Mosaic/Services/GeminiService.swift` and `server/.env.example`.
- To swap or provide a new key:
  - In iOS: update `apiKey` in `Mosaic/Services/GeminiService.swift`
  - In Backend: set `GEMINI_API_KEY` in `server/.env`

---

### 3. Tiger Data (Timescale Cloud)
- **Database**: `tsdb`
- **Host**: `jtf4omyes3.ehv2z06xub.tsdb.cloud.timescale.com`
- **Port**: `39663`
- **User**: `tsdbadmin`
- **SSL**: `require`
- **What to put in**: Password for `tsdbadmin` in `server/.env`:
  ```bash
  TIGER_DATA_PASSWORD=your_password_here
  ```
- Run schema migration on Timescale:
  ```bash
  psql "postgres://tsdbadmin:YOUR_PASSWORD@jtf4omyes3.ehv2z06xub.tsdb.cloud.timescale.com:39663/tsdb?sslmode=require" -f server/schema.sql
  ```
- Run the Node.js API server:
  ```bash
  cd server && npm install && npm start
  ```

---

## Core Privacy & Security Principles

- **On-Device Only**: The original PDF document never leaves the device container.
- **Strict Identifier Redaction**: SSNs, full account numbers (retaining only `**** [last4]`), full street addresses, phone numbers, and emails are redacted locally prior to any cloud processing.
- **Never Claims Fraud**: The app never claims that fraud, abuse, or identity theft occurred; it uses neutral terms ("changed", "new on this report", "needs review").
- **Drafts for Personal Review**: All dispute letters, worksheets, and checklists are drafts for the consumer to review and verify before submitting. No automatic submissions.
