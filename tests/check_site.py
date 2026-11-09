"""Checks packaging and core safety signals; not a browser or legal audit."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
site = root / 'public'
for filename in ('index.html', 'catalogue-auto.html'):
    html = (site / filename).read_text(encoding='utf-8')
    assert '<!doctype html>' in html.lower(), filename
    assert '</html>' in html.lower(), filename
    assert '<title>' in html, filename
    assert 'V0.6' in html, filename
    assert 'service_role' not in html and 'sk_live_' not in html, filename
assert (root / 'vercel.json').exists()
assert (root / 'backend/0001_repart_base.sql').exists()
print('PASS static packaging checks: 2 HTML documents and expected assets')
