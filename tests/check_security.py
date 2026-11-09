from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'backend'/'0001_repart_base.sql').read_text(encoding='utf-8')
tables=['profiles','sellers','listings','listing_destinations','orders','order_items','disputes']
for name in tables:
 assert f'ALTER TABLE public.repart_{name} ENABLE ROW LEVEL SECURITY;' in s
assert "verification_state='pending'" in s
assert "publication_state='draft' AND fitment_verified=false" in s
assert 'CREATE POLICY repart_orders_buyer_read' in s
assert 'CREATE POLICY repart_listings_insert_draft' in s
assert 'GRANT INSERT ON public.repart_orders' not in s
assert 'GRANT UPDATE ON public.repart_listings' not in s
assert 'CREATE POLICY repart_sellers_update' not in s
print('PASS static SQL checks: 7 tables RLS enabled, no browser approval/payout/stock-write grants')
