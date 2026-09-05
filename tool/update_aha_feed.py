import json
import re
import urllib.request
from html import unescape
from pathlib import Path

URL = 'https://cpr.heart.org/en/resources/faqs/course-updates'
OUT = Path(__file__).resolve().parents[1] / 'updates.json'

req = urllib.request.Request(URL, headers={'User-Agent': 'EMS-Protocols-AHA-Update-Feed/1.0'})
with urllib.request.urlopen(req, timeout=30) as r:
    html = r.read().decode('utf-8', errors='ignore')

# Convert enough HTML structure to text while preserving anchor URLs.
html = re.sub(r'<script.*?</script>', ' ', html, flags=re.I | re.S)
html = re.sub(r'<style.*?</style>', ' ', html, flags=re.I | re.S)
html = re.sub(r'\s+', ' ', html)

# Extract update notices from the public AHA course-updates page.
pattern = re.compile(
    r'UPDATED:\s*Change Notice:\s*([^<]{3,40})</[^>]+>\s*(?:<[^>]+>\s*)*([^<]{3,220})',
    re.I,
)
items = []
for m in pattern.finditer(html):
    date = unescape(m.group(1)).strip()
    title = re.sub(r'\s+', ' ', unescape(m.group(2))).strip(' -')
    if title and date:
        items.append({
            'source': 'AHA',
            'date': date,
            'title': f'{title} — Change Notice',
            'description': f'AHA lists a Change Notice dated {date} for {title}.',
            'url': URL,
        })

# Keep the feed useful even if AHA changes its HTML markup.
if not items:
    raise RuntimeError('No AHA update notices were parsed; refusing to overwrite the existing feed.')

# De-duplicate and keep newest-looking notices first.
seen = set()
clean = []
for item in items:
    key = (item['date'], item['title'])
    if key not in seen:
        seen.add(key)
        clean.append(item)

OUT.write_text(json.dumps(clean[:100], indent=2) + '\n', encoding='utf-8')
print(f'Wrote {len(clean[:100])} AHA updates to {OUT}')
