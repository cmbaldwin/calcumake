#!/usr/bin/env python3
import json
import re
from pathlib import Path
from datetime import datetime, UTC
from collections import defaultdict

BASE = Path.home() / '.openclaw' / 'agents'
OUT = Path(__file__).resolve().parents[1] / 'analytics' / 'usage'
OUT.mkdir(parents=True, exist_ok=True)

usage_events = []

for p in BASE.glob('**/sessions/*.jsonl'):
    try:
        with p.open('r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                if obj.get('type') != 'message':
                    continue
                msg = obj.get('message') or {}
                usage = msg.get('usage')
                if not usage:
                    continue
                ts = obj.get('timestamp')
                model = msg.get('model') or 'unknown'
                provider = msg.get('provider') or 'unknown'
                usage_events.append({
                    'timestamp': ts,
                    'model': model,
                    'provider': provider,
                    'input': usage.get('input', 0),
                    'output': usage.get('output', 0),
                    'cacheRead': usage.get('cacheRead', 0),
                    'cacheWrite': usage.get('cacheWrite', 0),
                    'totalTokens': usage.get('totalTokens', 0),
                    'costTotal': ((usage.get('cost') or {}).get('total') if isinstance(usage.get('cost'), dict) else None) or 0,
                    'sessionFile': str(p),
                })
    except Exception:
        continue

usage_events.sort(key=lambda x: x['timestamp'] or '')

# CSV export
csv_path = OUT / 'usage_events.csv'
with csv_path.open('w', encoding='utf-8') as f:
    f.write('timestamp,provider,model,input,output,cacheRead,cacheWrite,totalTokens,costTotal,sessionFile\n')
    for e in usage_events:
        row = [
            e['timestamp'], e['provider'], e['model'], str(e['input']), str(e['output']),
            str(e['cacheRead']), str(e['cacheWrite']), str(e['totalTokens']), str(e['costTotal']), e['sessionFile']
        ]
        esc = [r.replace('"', '""') if isinstance(r, str) else str(r) for r in row]
        f.write(','.join([f'"{r}"' for r in esc]) + '\n')

# Daily rollup
by_day = defaultdict(lambda: {'tokens': 0, 'cost': 0.0, 'events': 0})
for e in usage_events:
    ts = e['timestamp'] or ''
    day = ts[:10] if len(ts) >= 10 else 'unknown'
    by_day[day]['tokens'] += int(e.get('totalTokens', 0) or 0)
    by_day[day]['cost'] += float(e.get('costTotal', 0) or 0)
    by_day[day]['events'] += 1

rollup = {
    'generatedAt': datetime.now(UTC).isoformat().replace('+00:00', 'Z'),
    'eventCount': len(usage_events),
    'daily': dict(sorted(by_day.items())),
}
json_path = OUT / 'usage_rollups.json'
json_path.write_text(json.dumps(rollup, ensure_ascii=False, indent=2), encoding='utf-8')

# Markdown report with ascii bars
md = []
md.append('# OpenClaw Usage Report')
md.append('')
md.append(f'- Generated: {rollup["generatedAt"]}')
md.append(f'- Events: {rollup["eventCount"]}')
md.append('')
md.append('## Daily Tokens')
max_tokens = max([v['tokens'] for v in by_day.values()], default=1)
for day, vals in sorted(by_day.items()):
    bars = int((vals['tokens'] / max_tokens) * 30) if max_tokens else 0
    md.append(f'- {day}: {vals["tokens"]:,} | ' + ('█' * bars))
md.append('')
md.append('## Daily Cost (estimated from event usage cost.total)')
max_cost = max([v['cost'] for v in by_day.values()], default=1.0)
for day, vals in sorted(by_day.items()):
    bars = int((vals['cost'] / max_cost) * 30) if max_cost else 0
    md.append(f'- {day}: ${vals["cost"]:.4f} | ' + ('█' * bars))

(OUT / 'USAGE_REPORT.md').write_text('\n'.join(md) + '\n', encoding='utf-8')
print(f'Wrote {csv_path}')
print(f'Wrote {json_path}')
print(f'Wrote {OUT / "USAGE_REPORT.md"}')
