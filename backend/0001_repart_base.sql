-- REPART: migration préparatoire, non exécutée (Supabase PostgreSQL).
-- OBJECTIF: données privées isolées, marketplace fail-closed, pas de paiement en V0.6.
-- Exécuter uniquement dans un NOUVEAU projet REPART dédié après revue.
BEGIN;

CREATE TABLE IF NOT EXISTS public.repart_profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text CHECK (char_length(display_name) <= 80),
  preferred_language text NOT NULL DEFAULT 'fr' CHECK (preferred_language IN ('fr','nl','en','ar')),
  country char(2) CHECK (country ~ '^[A-Z]{2}$'),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.repart_sellers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_type text NOT NULL CHECK (seller_type IN ('professional','individual')),
  display_name text NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 100),
  country char(2) NOT NULL CHECK (country ~ '^[A-Z]{2}$'),
  kvk text CHECK (char_length(kvk) <= 24),
  vat_id text CHECK (char_length(vat_id) <= 36),
  verification_state text NOT NULL DEFAULT 'pending' CHECK (verification_state IN ('pending','verified','rejected','suspended')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(owner_id)
);
CREATE INDEX IF NOT EXISTS repart_sellers_public_idx ON public.repart_sellers(verification_state,country);

CREATE TABLE IF NOT EXISTS public.repart_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES public.repart_sellers(id) ON DELETE RESTRICT,
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL CHECK (char_length(title) BETWEEN 3 AND 160),
  oem_reference text CHECK (char_length(oem_reference) <= 80),
  manufacturer_reference text CHECK (char_length(manufacturer_reference) <= 80),
  vehicle_make text CHECK (char_length(vehicle_make) <= 100),
  vehicle_model text CHECK (char_length(vehicle_model) <= 100),
  vehicle_year smallint CHECK (vehicle_year BETWEEN 1950 AND 2035),
  engine_code text CHECK (char_length(engine_code) <= 60),
  description text CHECK (char_length(description) <= 5000),
  condition_grade text NOT NULL CHECK (condition_grade IN ('used_good','used_fair','for_parts')),
  price_minor bigint NOT NULL CHECK (price_minor BETWEEN 1 AND 99999999999),
  currency char(3) NOT NULL DEFAULT 'EUR' CHECK (currency IN ('EUR','MAD')),
  quantity smallint NOT NULL DEFAULT 1 CHECK (quantity = 1),
  ship_from char(2) NOT NULL CHECK (ship_from ~ '^[A-Z]{2}$'),
  publication_state text NOT NULL DEFAULT 'draft' CHECK (publication_state IN ('draft','pending_review','published','rejected','removed','sold')),
  fitment_verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS repart_listings_public_idx ON public.repart_listings(publication_state,ship_from,created_at DESC);
CREATE INDEX IF NOT EXISTS repart_listings_seller_idx ON public.repart_listings(seller_id,created_at DESC);

CREATE TABLE IF NOT EXISTS public.repart_listing_destinations (
  listing_id uuid NOT NULL REFERENCES public.repart_listings(id) ON DELETE CASCADE,
  destination_country char(2) NOT NULL CHECK (destination_country ~ '^[A-Z]{2}$'),
  PRIMARY KEY (listing_id,destination_country)
);

CREATE TABLE IF NOT EXISTS public.repart_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'created' CHECK (status IN ('created','awaiting_payment','paid','shipped','delivered','disputed','closed','cancelled','refunded')),
  total_minor bigint NOT NULL CHECK (total_minor >= 0),
  currency char(3) NOT NULL CHECK (currency IN ('EUR','MAD')),
  destination_country char(2) NOT NULL CHECK (destination_country ~ '^[A-Z]{2}$'),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- No payment detail/token is stored. Settlement comes later from an authorized PSP.
CREATE TABLE IF NOT EXISTS public.repart_order_items (
  order_id uuid NOT NULL REFERENCES public.repart_orders(id) ON DELETE CASCADE,
  listing_id uuid NOT NULL REFERENCES public.repart_listings(id) ON DELETE RESTRICT,
  seller_id uuid NOT NULL REFERENCES public.repart_sellers(id) ON DELETE RESTRICT,
  price_minor bigint NOT NULL CHECK (price_minor >= 0),
  PRIMARY KEY (order_id,listing_id)
);

CREATE TABLE IF NOT EXISTS public.repart_disputes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.repart_orders(id) ON DELETE RESTRICT,
  raised_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  state text NOT NULL DEFAULT 'open' CHECK (state IN ('open','review','resolved','closed')),
  reason text NOT NULL CHECK (char_length(reason) BETWEEN 5 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Data API access is explicit and RLS is on EVERY exposed table.
ALTER TABLE public.repart_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repart_sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repart_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repart_listing_destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repart_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repart_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repart_disputes ENABLE ROW LEVEL SECURITY;

-- Profiles: strictly self-service.
CREATE POLICY repart_profiles_read_self ON public.repart_profiles FOR SELECT TO authenticated USING ((SELECT auth.uid())=user_id);
CREATE POLICY repart_profiles_insert_self ON public.repart_profiles FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid())=user_id);
CREATE POLICY repart_profiles_update_self ON public.repart_profiles FOR UPDATE TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id);

-- Sellers: only owner can read account data. Public store profile needs a later curated safe view; never expose KVK/VAT blindly.
CREATE POLICY repart_sellers_read_self ON public.repart_sellers FOR SELECT TO authenticated USING ((SELECT auth.uid())=owner_id);
CREATE POLICY repart_sellers_insert_pending ON public.repart_sellers FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid())=owner_id AND verification_state='pending');
-- No UPDATE/DELETE for sellers from browser; verification needs privileged and audited admin operation.

-- Listings: buyers can see only published items, owners can see their drafts.
CREATE POLICY repart_listings_public_read ON public.repart_listings FOR SELECT TO anon,authenticated USING (publication_state='published');
CREATE POLICY repart_listings_owner_read ON public.repart_listings FOR SELECT TO authenticated USING ((SELECT auth.uid())=owner_id);
CREATE POLICY repart_listings_insert_draft ON public.repart_listings FOR INSERT TO authenticated WITH CHECK (
  (SELECT auth.uid())=owner_id AND publication_state='draft' AND fitment_verified=false AND
  EXISTS(SELECT 1 FROM public.repart_sellers s WHERE s.id=seller_id AND s.owner_id=(SELECT auth.uid()) AND s.verification_state IN ('pending','verified'))
);
-- No UPDATE/DELETE from browser: moderation and stock changes must go through validated server workflows.

CREATE POLICY repart_destinations_read_public ON public.repart_listing_destinations FOR SELECT TO anon,authenticated
USING (EXISTS (SELECT 1 FROM public.repart_listings l WHERE l.id=listing_id AND l.publication_state='published'));
CREATE POLICY repart_destinations_owner_read ON public.repart_listing_destinations FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.repart_listings l WHERE l.id=listing_id AND l.owner_id=(SELECT auth.uid())));
CREATE POLICY repart_destinations_owner_insert ON public.repart_listing_destinations FOR INSERT TO authenticated
WITH CHECK (EXISTS (SELECT 1 FROM public.repart_listings l WHERE l.id=listing_id AND l.owner_id=(SELECT auth.uid()) AND l.publication_state='draft'));

-- Payment/order flows: only server can create/update; buyers can see their own orders/disputes.
CREATE POLICY repart_orders_buyer_read ON public.repart_orders FOR SELECT TO authenticated USING ((SELECT auth.uid())=buyer_id);
CREATE POLICY repart_items_buyer_read ON public.repart_order_items FOR SELECT TO authenticated
USING (EXISTS(SELECT 1 FROM public.repart_orders o WHERE o.id=order_id AND o.buyer_id=(SELECT auth.uid())));
CREATE POLICY repart_disputes_buyer_read ON public.repart_disputes FOR SELECT TO authenticated
USING (EXISTS(SELECT 1 FROM public.repart_orders o WHERE o.id=order_id AND o.buyer_id=(SELECT auth.uid())));

GRANT SELECT,INSERT,UPDATE ON public.repart_profiles TO authenticated;
GRANT SELECT,INSERT ON public.repart_sellers TO authenticated;
GRANT SELECT ON public.repart_listings TO anon;
GRANT SELECT,INSERT ON public.repart_listings TO authenticated;
GRANT SELECT ON public.repart_listing_destinations TO anon;
GRANT SELECT,INSERT ON public.repart_listing_destinations TO authenticated;
GRANT SELECT ON public.repart_orders,public.repart_order_items,public.repart_disputes TO authenticated;
-- Privileged moderation workflows use server-side role, never a public client key.
COMMIT;
