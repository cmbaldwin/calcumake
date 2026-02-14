# AI Ops Usage, Archive, and Backup Plan

## Goals
1. Track OpenAI/Claude-style usage windows and trend them over time.
2. Keep a durable, queryable archive of conversations.
3. Generate charts for weekly/monthly review.
4. Maintain robust backups (local + iCloud).
5. Keep the system automation-friendly for future OpenClaw-to-OpenClaw workflows.

## Current Status
- Session-level usage exists via OpenClaw session logs (`~/.openclaw/agents/**/sessions/*.jsonl`) and `/status` snapshots.
- We do **not** yet have consolidated analytics charts or a durable database mirror.

## Architecture (efficient first, robust path)

### Phase 1 (Now): File-native analytics + SQLite (no Docker required)
- Source of truth: OpenClaw JSONL session logs.
- ETL script:
  - Parse usage blocks from assistant messages.
  - Aggregate by hour/day/model/provider.
  - Export:
    - CSV (`analytics/usage/usage_events.csv`)
    - JSON (`analytics/usage/usage_rollups.json`)
    - PNG charts (`analytics/usage/charts/*.png`)
- Durable store:
  - SQLite DB (`analytics/archive/openclaw_archive.sqlite3`)
  - Tables: `sessions`, `messages`, `usage_events`, `cron_runs` (optional).
- Scheduling:
  - Cron agent turn every 30–60 minutes to run ETL.

### Phase 2: Optional Docker Postgres mirror
- Add Dockerized Postgres only if/when:
  - query volume grows,
  - we need BI tooling,
  - we need multi-process concurrent writes.
- Keep SQLite as hot backup export target either way.

## Backups

### Primary backup set
- `analytics/`
- `memory/`
- `skills/`
- selected `docs/`

### Strategy
1. Local rotating snapshots (timestamped tar.gz).
2. iCloud mirror copy (for off-device resilience).
3. Weekly verification task (checksum + restore test on sample files).

### Suggested iCloud target path
`~/Library/Mobile Documents/com~apple~CloudDocs/OpenClawBackups/`

## AI-First Integration Contract
- Keep all exported artifacts machine-readable:
  - JSON schemas for rollups.
  - Stable file naming and timestamps.
- Add a small MCP-style wrapper later exposing:
  - `get_usage_window`
  - `get_cost_trend`
  - `list_recent_conversations`
  - `search_conversation_archive`
- This will make integration with other OpenClaw instances straightforward.

## Security and Safety
- Do not store raw secrets in archive DB.
- Redact known secret patterns before durable write.
- Keep archived conversation access local by default.
- Encrypt backups if moved beyond local+iCloud trusted account.

## Immediate Next Steps
1. Add usage ETL + chart script (phase 1 bootstrap).
2. Add cron job to run ETL every hour.
3. Add backup script to create daily snapshots + iCloud mirror.
4. Add weekly verification script.
5. Add a dashboard markdown report generated from latest rollups.

## Notes on Dedicated Google Account
A dedicated Google account for Escalante is a good move for:
- clean credential boundaries,
- safer app-password/API key hygiene,
- future Gmail/Calendar workflow automation isolation.
