-- ============================================================
-- AIScope — Supabase PostgreSQL Schema
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- USERS (extends Supabase auth.users)
-- ============================================================
CREATE TABLE public.users (
  id            UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT        NOT NULL UNIQUE,
  full_name     TEXT,
  company_name  TEXT,
  avatar_url    TEXT,
  role          TEXT        NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SERVICES (solution categories)
-- ============================================================
CREATE TABLE public.services (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT        NOT NULL UNIQUE,
  slug        TEXT        NOT NULL UNIQUE,
  description TEXT,
  icon        TEXT,
  sort_order  INTEGER     DEFAULT 0,
  is_active   BOOLEAN     DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- LISTINGS (core entity)
-- ============================================================
CREATE TABLE public.listings (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id              UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Identity
  name                  TEXT        NOT NULL,
  slug                  TEXT        NOT NULL UNIQUE,
  listing_type          TEXT        NOT NULL DEFAULT 'agency'
                          CHECK (listing_type IN ('agency','saas','consulting','other')),
  tagline               TEXT        NOT NULL CHECK (char_length(tagline) <= 160),
  description           TEXT,

  -- Contact & Web
  website_url           TEXT        NOT NULL,
  contact_email         TEXT,
  contact_email_public  BOOLEAN     DEFAULT FALSE,
  contact_phone         TEXT,
  contact_form_url      TEXT,
  linkedin_url          TEXT,
  twitter_url           TEXT,

  -- Media
  logo_url              TEXT,
  og_image_url          TEXT,

  -- Company Info
  founded_year          SMALLINT    CHECK (founded_year > 1990 AND founded_year < 2100),
  team_size             TEXT        CHECK (team_size IN ('1','2-10','11-50','51-200','201-500','500+')),
  hq_country            TEXT,
  hq_city               TEXT,

  -- Pricing
  pricing_model         TEXT        CHECK (pricing_model IN (
                          'free','freemium','subscription','project-based',
                          'retainer','custom','contact'
                        )),
  pricing_starts_at     NUMERIC,

  -- Status & Trust
  status                TEXT        NOT NULL DEFAULT 'draft'
                          CHECK (status IN ('draft','pending_review','published','suspended')),
  is_claimed            BOOLEAN     DEFAULT FALSE,
  is_verified           BOOLEAN     DEFAULT FALSE,
  last_verified_at      TIMESTAMPTZ,

  -- Monetization
  listing_tier          TEXT        NOT NULL DEFAULT 'free'
                          CHECK (listing_tier IN ('free','featured','sponsored','enterprise')),
  tier_expires_at       TIMESTAMPTZ,
  featured_order        INTEGER,

  -- Scoring & Stats
  profile_completeness  SMALLINT    DEFAULT 0 CHECK (profile_completeness BETWEEN 0 AND 100),
  avg_rating            NUMERIC(3,2) DEFAULT 0,
  review_count          INTEGER     DEFAULT 0,
  view_count            INTEGER     DEFAULT 0,

  -- SEO
  meta_title            TEXT        CHECK (char_length(meta_title) <= 70),
  meta_description      TEXT        CHECK (char_length(meta_description) <= 160),

  -- Full-text search vector
  search_vector         TSVECTOR,

  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- LISTING_SERVICES (many-to-many junction)
-- ============================================================
CREATE TABLE public.listing_services (
  listing_id  UUID  NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  service_id  UUID  NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  PRIMARY KEY (listing_id, service_id)
);

-- ============================================================
-- PORTFOLIO_ITEMS
-- ============================================================
CREATE TABLE public.portfolio_items (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id  UUID        NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  owner_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title       TEXT,
  description TEXT,
  media_url   TEXT        NOT NULL,
  media_type  TEXT        DEFAULT 'image' CHECK (media_type IN ('image','video','pdf')),
  sort_order  INTEGER     DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_listings_status          ON public.listings(status);
CREATE INDEX idx_listings_slug            ON public.listings(slug);
CREATE INDEX idx_listings_owner           ON public.listings(owner_id);
CREATE INDEX idx_listings_tier            ON public.listings(listing_tier);
CREATE INDEX idx_listings_completeness    ON public.listings(profile_completeness DESC);
CREATE INDEX idx_listings_created         ON public.listings(created_at DESC);
CREATE INDEX idx_listings_search          ON public.listings USING GIN(search_vector);
CREATE INDEX idx_listing_services_listing ON public.listing_services(listing_id);
CREATE INDEX idx_listing_services_service ON public.listing_services(service_id);
CREATE INDEX idx_portfolio_listing        ON public.portfolio_items(listing_id);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER listings_updated_at
  BEFORE UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- search_vector auto-update
CREATE OR REPLACE FUNCTION update_listing_search_vector()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    COALESCE(NEW.name, '')        || ' ' ||
    COALESCE(NEW.tagline, '')     || ' ' ||
    COALESCE(NEW.description, '') || ' ' ||
    COALESCE(NEW.hq_city, '')     || ' ' ||
    COALESCE(NEW.hq_country, '')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER listings_search_vector
  BEFORE INSERT OR UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION update_listing_search_vector();

-- profile completeness auto-calculate
CREATE OR REPLACE FUNCTION calculate_profile_completeness()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE score INTEGER := 0;
BEGIN
  IF NEW.logo_url       IS NOT NULL                                     THEN score := score + 15; END IF;
  IF NEW.description    IS NOT NULL AND char_length(NEW.description) > 100 THEN score := score + 20; END IF;
  IF NEW.website_url    IS NOT NULL                                     THEN score := score + 10; END IF;
  IF NEW.tagline        IS NOT NULL                                     THEN score := score + 10; END IF;
  IF NEW.contact_email  IS NOT NULL                                     THEN score := score + 10; END IF;
  IF NEW.pricing_model  IS NOT NULL                                     THEN score := score + 10; END IF;
  IF NEW.linkedin_url   IS NOT NULL                                     THEN score := score + 5;  END IF;
  IF NEW.hq_country     IS NOT NULL                                     THEN score := score + 5;  END IF;
  IF NEW.team_size      IS NOT NULL                                     THEN score := score + 5;  END IF;
  IF NEW.founded_year   IS NOT NULL                                     THEN score := score + 5;  END IF;
  -- Note: +5 for portfolio items is handled app-side (can't query related table in trigger easily)
  NEW.profile_completeness := LEAST(score, 95); -- max 95 from this trigger; +5 for portfolio via app
  RETURN NEW;
END;
$$;

CREATE TRIGGER listings_completeness
  BEFORE INSERT OR UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION calculate_profile_completeness();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.users           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services        ENABLE ROW LEVEL SECURITY;

-- Admin helper function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER AS $$
  SELECT COALESCE(
    (SELECT role = 'admin' FROM public.users WHERE id = auth.uid()),
    FALSE
  );
$$;

-- USERS policies
CREATE POLICY "users_select" ON public.users FOR SELECT
  USING (auth.uid() = id OR is_admin());
CREATE POLICY "users_insert" ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);
CREATE POLICY "users_update" ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- LISTINGS policies
CREATE POLICY "listings_select_public" ON public.listings FOR SELECT
  USING (status = 'published' OR auth.uid() = owner_id OR is_admin());
CREATE POLICY "listings_insert" ON public.listings FOR INSERT
  WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "listings_update" ON public.listings FOR UPDATE
  USING (auth.uid() = owner_id OR is_admin());
CREATE POLICY "listings_delete" ON public.listings FOR DELETE
  USING (auth.uid() = owner_id OR is_admin());

-- SERVICES policies (public read, admin write)
CREATE POLICY "services_select" ON public.services FOR SELECT USING (TRUE);
CREATE POLICY "services_all_admin" ON public.services FOR ALL USING (is_admin());

-- LISTING_SERVICES policies
CREATE POLICY "listing_services_select" ON public.listing_services FOR SELECT USING (TRUE);
CREATE POLICY "listing_services_all" ON public.listing_services FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.listings
      WHERE id = listing_id AND owner_id = auth.uid()
    ) OR is_admin()
  );

-- PORTFOLIO_ITEMS policies
CREATE POLICY "portfolio_select" ON public.portfolio_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.listings
      WHERE id = listing_id AND status = 'published'
    ) OR auth.uid() = owner_id OR is_admin()
  );
CREATE POLICY "portfolio_all" ON public.portfolio_items FOR ALL
  USING (auth.uid() = owner_id OR is_admin());

-- ============================================================
-- STORAGE BUCKETS
-- Run these in: Supabase Dashboard → Storage → New bucket
-- Or via SQL below (may need to use UI depending on Supabase version)
-- ============================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('logos', 'logos', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('portfolio', 'portfolio', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- Storage policies for logos bucket
-- CREATE POLICY "logos_public_read" ON storage.objects FOR SELECT USING (bucket_id = 'logos');
-- CREATE POLICY "logos_owner_upload" ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'logos' AND auth.uid()::text = (storage.foldername(name))[1]);
-- CREATE POLICY "logos_owner_delete" ON storage.objects FOR DELETE
--   USING (bucket_id = 'logos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for portfolio bucket
-- CREATE POLICY "portfolio_public_read" ON storage.objects FOR SELECT USING (bucket_id = 'portfolio');
-- CREATE POLICY "portfolio_owner_upload" ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'portfolio' AND auth.role() = 'authenticated');
-- CREATE POLICY "portfolio_owner_delete" ON storage.objects FOR DELETE
--   USING (bucket_id = 'portfolio' AND auth.role() = 'authenticated');

-- ============================================================
-- SEED: Solution Categories
-- ============================================================
INSERT INTO public.services (name, slug, description, icon, sort_order) VALUES
  ('Lead Generation',      'lead-generation',     'AI-powered prospecting, outreach & sales automation', '🎯', 1),
  ('Voice Agents',         'voice-agents',         'AI voice assistants, receptionists & phone automation', '📞', 2),
  ('Customer Support',     'customer-support',     'AI chatbots, helpdesk automation & support workflows', '💬', 3),
  ('CRM Automation',       'crm-automation',       'CRM integration, pipeline automation & data enrichment', '🔄', 4),
  ('Appointment Booking',  'appointment-booking',  'AI scheduling, calendar automation & booking systems', '📅', 5),
  ('Marketing Automation', 'marketing-automation', 'AI content, email campaigns & social media automation', '📣', 6),
  ('Internal Operations',  'internal-operations',  'Workflow automation, document processing & internal tools', '⚙️', 7);

-- ============================================================
-- AUTO-CREATE USER PROFILE ON SIGNUP
-- Run this in SQL editor to create the trigger
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, company_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'company_name'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
