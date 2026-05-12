-- ─────────────────────────────────────────────────────────────────
--  COURTSIDE — Full Database Schema
--  Run this in the Supabase SQL Editor in order.
--  Safe to re-run: all statements use IF NOT EXISTS / OR REPLACE.
-- ─────────────────────────────────────────────────────────────────

-- ── Extensions ────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- fuzzy venue search

-- ═════════════════════════════════════════════════════════════════
--  USER PROFILES
--  One row per auth.users user, created on first login via trigger.
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS user_profiles (
  id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username        text UNIQUE,
  full_name       text,
  avatar_url      text,
  bio             text,
  preferred_sports text[] DEFAULT '{}',
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO user_profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ═════════════════════════════════════════════════════════════════
--  VENUES
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS venues (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  address         text NOT NULL,
  area            text NOT NULL,
  lat             double precision NOT NULL,
  lng             double precision NOT NULL,
  sports          text[] NOT NULL DEFAULT '{}',
  rating          numeric(3,1) DEFAULT 0.0,
  review_count    integer DEFAULT 0,
  opening_time    text DEFAULT '6:00 AM',
  closing_time    text DEFAULT '10:00 PM',
  photo_url       text DEFAULT '',
  amenities       text[] DEFAULT '{}',
  has_the_box     boolean DEFAULT false,
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now()
);

-- GiST index for text search on name + area
CREATE INDEX IF NOT EXISTS venues_name_trgm  ON venues USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS venues_area_trgm  ON venues USING gin (area gin_trgm_ops);
CREATE INDEX IF NOT EXISTS venues_sports_gin ON venues USING gin (sports);
CREATE INDEX IF NOT EXISTS venues_active_idx ON venues (is_active);

-- ═════════════════════════════════════════════════════════════════
--  COURTS  (bookable sub-units inside a venue)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS courts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id          uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  sport             text NOT NULL,
  name              text NOT NULL,
  surface           text DEFAULT '',        -- 'Hardwood', 'Acrylic', 'Turf', etc.
  is_indoor         boolean DEFAULT false,
  price_per_slot    integer NOT NULL DEFAULT 0,   -- in INR
  slot_duration_min integer NOT NULL DEFAULT 60,
  has_the_box       boolean DEFAULT false,
  is_active         boolean DEFAULT true,
  created_at        timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS courts_venue_idx  ON courts (venue_id);
CREATE INDEX IF NOT EXISTS courts_sport_idx  ON courts (sport);
CREATE INDEX IF NOT EXISTS courts_active_idx ON courts (is_active);

-- ═════════════════════════════════════════════════════════════════
--  SLOTS  (a specific time window on a specific court + date)
--  Generated ahead of time per operating day. Status transitions:
--    available → booked (by book_slot RPC)
--    available → blocked (by venue admin)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS slots (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_court_id  uuid NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
  date            date NOT NULL,
  start_time      time NOT NULL,
  end_time        time NOT NULL,
  status          text NOT NULL DEFAULT 'available'
                    CHECK (status IN ('available', 'booked', 'blocked')),
  booked_count    integer DEFAULT 0,   -- incremented non-fatally after booking
  created_at      timestamptz DEFAULT now(),
  UNIQUE (venue_court_id, date, start_time)
);

CREATE INDEX IF NOT EXISTS slots_court_date_idx ON slots (venue_court_id, date);
CREATE INDEX IF NOT EXISTS slots_status_idx     ON slots (status);

-- ═════════════════════════════════════════════════════════════════
--  BOOKINGS
--  Written after Razorpay payment confirms.
--  cs_status lifecycle: upcoming → completed | cancelled
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS bookings (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  slot_id                 uuid NOT NULL REFERENCES slots(id),
  court_id                uuid REFERENCES courts(id),
  venue_id                uuid NOT NULL REFERENCES venues(id),
  venue_name              text NOT NULL,
  sport                   text NOT NULL,
  cs_status               text NOT NULL DEFAULT 'upcoming'
                            CHECK (cs_status IN ('upcoming', 'completed', 'cancelled')),
  amount_paid             integer NOT NULL,                  -- total in INR
  payment_id              text DEFAULT '',                   -- Razorpay payment ID
  time_slot               text DEFAULT '',                   -- "6:00 AM–7:00 AM" denorm
  phone_scoring_enabled   boolean DEFAULT false,
  qr_code                 text DEFAULT '',
  checked_in              boolean DEFAULT false,
  invited_user_ids        uuid[] DEFAULT '{}',
  is_public_game          boolean DEFAULT false,
  player_limit            integer DEFAULT 10,
  hardware_option_id      uuid,                              -- FK added after hardware_rentals created
  created_at              timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bookings_user_idx   ON bookings (user_id);
CREATE INDEX IF NOT EXISTS bookings_slot_idx   ON bookings (slot_id);
CREATE INDEX IF NOT EXISTS bookings_status_idx ON bookings (cs_status);
CREATE INDEX IF NOT EXISTS bookings_created_idx ON bookings (created_at DESC);

-- ═════════════════════════════════════════════════════════════════
--  PLAYER STATS
--  One row per (user, sport). Updated after each completed game.
--  stats JSONB holds sport-specific fields (ppg, rpg, apg, etc.)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS player_stats (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sport        text NOT NULL,
  games_played integer DEFAULT 0,
  wins         integer DEFAULT 0,
  stats        jsonb DEFAULT '{}',
  updated_at   timestamptz DEFAULT now(),
  UNIQUE (user_id, sport)
);

CREATE INDEX IF NOT EXISTS player_stats_user_idx  ON player_stats (user_id);
CREATE INDEX IF NOT EXISTS player_stats_sport_idx ON player_stats (sport);

-- ═════════════════════════════════════════════════════════════════
--  HARDWARE RENTALS  (THE BOX product catalogue per venue)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS hardware_rentals (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id        uuid REFERENCES venues(id) ON DELETE SET NULL,  -- NULL = all venues
  name            text NOT NULL,
  description     text DEFAULT '',
  icon            text DEFAULT '📦',
  price_per_game  integer NOT NULL,   -- INR
  original_price  integer,            -- for showing strikethrough
  is_bundle       boolean DEFAULT false,
  is_available    boolean DEFAULT true,
  sort_order      integer DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

-- Add FK from bookings to hardware_rentals now that it exists
ALTER TABLE bookings
  ADD CONSTRAINT fk_bookings_hardware
  FOREIGN KEY (hardware_option_id) REFERENCES hardware_rentals(id)
  ON DELETE SET NULL
  NOT VALID;

-- ═════════════════════════════════════════════════════════════════
--  PRODUCTS  (marketplace: equipment, hydration, nutrition, etc.)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS products (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  brand           text DEFAULT '',
  category        text NOT NULL,    -- 'Hydration','Nutrition','Equipment','Footwear','Apparel','Protection'
  price           integer NOT NULL,
  original_price  integer,
  rating          numeric(3,1) DEFAULT 0.0,
  review_count    integer DEFAULT 0,
  image_url       text DEFAULT '',
  description     text DEFAULT '',
  specifications  jsonb DEFAULT '{}',
  tags            text[] DEFAULT '{}',
  in_stock        boolean DEFAULT true,
  stock_qty       integer DEFAULT 0,
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS products_category_idx ON products (category);
CREATE INDEX IF NOT EXISTS products_active_idx   ON products (is_active);
CREATE INDEX IF NOT EXISTS products_name_trgm    ON products USING gin (name gin_trgm_ops);

-- ═════════════════════════════════════════════════════════════════
--  PRODUCT REVIEWS
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS product_reviews (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id     uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id        uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating         integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title          text DEFAULT '',
  comment        text DEFAULT '',
  verified       boolean DEFAULT false,    -- true if user purchased this product
  helpful_count  integer DEFAULT 0,
  created_at     timestamptz DEFAULT now(),
  UNIQUE (product_id, user_id)
);

CREATE INDEX IF NOT EXISTS product_reviews_product_idx ON product_reviews (product_id);
CREATE INDEX IF NOT EXISTS product_reviews_user_idx    ON product_reviews (user_id);

-- ═════════════════════════════════════════════════════════════════
--  DELIVERY ADDRESSES
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS delivery_addresses (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label       text DEFAULT 'Home',   -- 'Home', 'Work', 'Other'
  name        text NOT NULL,
  phone       text DEFAULT '',
  street      text NOT NULL,
  area        text DEFAULT '',
  city        text NOT NULL DEFAULT 'Bengaluru',
  pincode     text NOT NULL,
  is_default  boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS delivery_addresses_user_idx ON delivery_addresses (user_id);

-- ═════════════════════════════════════════════════════════════════
--  ORDERS  (marketplace purchases)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS orders (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  address_id      uuid REFERENCES delivery_addresses(id) ON DELETE SET NULL,
  status          text NOT NULL DEFAULT 'placed'
                    CHECK (status IN ('placed','confirmed','shipped','out_for_delivery','delivered','cancelled','returned')),
  items           jsonb NOT NULL DEFAULT '[]',   -- [{product_id, name, price, qty, image_url}]
  subtotal        integer NOT NULL DEFAULT 0,
  delivery_fee    integer NOT NULL DEFAULT 0,
  total           integer NOT NULL DEFAULT 0,
  payment_id      text DEFAULT '',
  tracking_id     text DEFAULT '',
  placed_at       timestamptz DEFAULT now(),
  delivered_at    timestamptz,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS orders_user_idx   ON orders (user_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders (status);

-- ═════════════════════════════════════════════════════════════════
--  FRIENDS  (social graph — bidirectional via two rows or one)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS friends (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status        text NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','accepted','blocked')),
  created_at    timestamptz DEFAULT now(),
  UNIQUE (user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS friends_user_idx   ON friends (user_id, status);
CREATE INDEX IF NOT EXISTS friends_friend_idx ON friends (friend_id, status);

-- ═════════════════════════════════════════════════════════════════
--  PICKUP GAMES  (public bookings strangers can join)
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS pickup_games (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id      uuid REFERENCES bookings(id) ON DELETE CASCADE,
  creator_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  venue_id        uuid NOT NULL REFERENCES venues(id),
  sport           text NOT NULL,
  title           text NOT NULL,
  start_time      timestamptz NOT NULL,
  spots_total     integer NOT NULL DEFAULT 10,
  spots_filled    integer NOT NULL DEFAULT 1,
  skill_level     text DEFAULT 'all'
                    CHECK (skill_level IN ('all','beginner','intermediate','competitive')),
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS pickup_games_venue_idx  ON pickup_games (venue_id);
CREATE INDEX IF NOT EXISTS pickup_games_sport_idx  ON pickup_games (sport);
CREATE INDEX IF NOT EXISTS pickup_games_time_idx   ON pickup_games (start_time);
CREATE INDEX IF NOT EXISTS pickup_games_active_idx ON pickup_games (is_active);

-- ═════════════════════════════════════════════════════════════════
--  SEED: Hardware rental options (mirrors fake_data.dart)
-- ═════════════════════════════════════════════════════════════════
INSERT INTO hardware_rentals (id, name, description, icon, price_per_game, original_price, is_bundle, sort_order)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'THE BOX Scorer Pro',     'Auto-capture scores, assists & rebounds via AI camera', '📦', 99,  NULL, false, 1),
  ('00000000-0000-0000-0000-000000000002', '1080p Camera Mount',     'Full-court recording with AI highlight detection',         '📷', 149, NULL, false, 2),
  ('00000000-0000-0000-0000-000000000003', 'Bundle: Scorer + Camera','Best value — scoring + full-court video in one',           '🎁', 199, 248, true,  3),
  ('00000000-0000-0000-0000-000000000004', 'CCTV Highlight Clip',    '60-second highlight reel from existing venue CCTV',        '🎬', 49,  NULL, false, 4)
ON CONFLICT (id) DO NOTHING;
