import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / 'app_updates_seed.json'
OUT = ROOT / 'app_updates.json'

entries = []
if SEED.exists():
    entries = json.loads(SEED.read_text(encoding='utf-8'))

# Add recent human-authored Git commits so the feed can reflect future app work
# automatically after changes are pushed to GitHub.
try:
    raw = subprocess.check_output(
        ['git', 'log', '-n', '20', '--pretty=format:%H%x1f%ad%x1f%s', '--date=iso-strict'],
        cwd=ROOT,
        text=True,
    )
    existing_titles = {str(e.get('title', '')).strip().lower() for e in entries}
    for line in raw.splitlines():
        parts = line.split('\x1f', 2)
        if len(parts) != 3:
            continue
        sha, iso_date, subject = parts
        subject = subject.strip()
        lowered = subject.lower()
        if not subject or lowered.startswith('update aha feed') or lowered.startswith('merge '):
            continue
        if lowered in existing_titles:
            continue
        try:
            dt = datetime.fromisoformat(iso_date.replace('Z', '+00:00')).astimezone(timezone.utc)
            date_text = dt.strftime('%B %-d, %Y')
        except Exception:
            date_text = iso_date[:10]
        entries.append({
            'source': 'APP',
            'date': date_text,
            'title': subject,
            'description': f'App change recorded in GitHub commit {sha[:7]}.',
            'url': '',
        })
        existing_titles.add(lowered)
except Exception:
    pass

# Keep newest-looking entries first, with seed entries retained at the top.
def sort_key(item):
    try:
        return datetime.strptime(item.get('date', ''), '%B %d, %Y')
    except ValueError:
        return datetime.min

# Deduplicate exact title/date pairs.
seen = set()
deduped = []
for item in entries:
    key = (item.get('title', ''), item.get('date', ''))
    if key in seen:
        continue
    seen.add(key)
    deduped.append(item)

# Put seed/current feature entries first, then commit-derived entries.
seed_count = len(json.loads(SEED.read_text(encoding='utf-8'))) if SEED.exists() else 0
seed_part = deduped[:seed_count]
commit_part = deduped[seed_count:]
commit_part.sort(key=sort_key, reverse=True)
result = seed_part + commit_part[:20]
OUT.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(f'Wrote {len(result)} app updates to {OUT}')
