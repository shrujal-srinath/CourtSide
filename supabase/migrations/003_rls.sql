-- ─────────────────────────────────────────────────────────────────
--  COURTSIDE — Row Level Security Policies
--  Run AFTER 002_functions.sql
-- ─────────────────────────────────────────────────────────────────

-- ═════════════════════════════════════════════════════════════════
--  VENUES & COURTS  — public read, admin write
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE courts ENABLE ROW LEVEL SECURITY;
ALTER TABLE slots  ENABLE ROW LEVEL SECURITY;

-- Public read
DROP POLICY IF EXISTS "venues: public read"  ON venues;
CREATE POLICY "venues: public read"
  ON venues FOR SELECT USING (true);

DROP POLICY IF EXISTS "courts: public read"  ON courts;
CREATE POLICY "courts: public read"
  ON courts FOR SELECT USING (true);

DROP POLICY IF EXISTS "slots: public read"   ON slots;
CREATE POLICY "slots: public read"
  ON slots FOR SELECT USING (true);

-- Service-role / admin write (INSERT/UPDATE/DELETE) is allowed by
-- default when using the service_role key — no explicit policy needed.
-- Anon and authenticated users get only the SELECT above.

-- ═════════════════════════════════════════════════════════════════
--  BOOKINGS  — owner reads own; book_slot RPC writes (SECURITY DEFINER)
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bookings: owner read"   ON bookings;
CREATE POLICY "bookings: owner read"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

-- Direct INSERT is blocked for authenticated users; all writes
-- happen through the book_slot() SECURITY DEFINER function.
-- This prevents users from writing fake bookings.

-- ═════════════════════════════════════════════════════════════════
--  USER PROFILES  — owner read/write
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles: owner read"  ON user_profiles;
CREATE POLICY "profiles: owner read"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles: owner update" ON user_profiles;
CREATE POLICY "profiles: owner update"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- Public read of username + avatar (for friend search)
DROP POLICY IF EXISTS "profiles: public username read" ON user_profiles;
CREATE POLICY "profiles: public username read"
  ON user_profiles FOR SELECT
  USING (username IS NOT NULL);

-- ═════════════════════════════════════════════════════════════════
--  PLAYER STATS  — public read, service-role write only
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "player_stats: public read" ON player_stats;
CREATE POLICY "player_stats: public read"
  ON player_stats FOR SELECT USING (true);

-- Writes happen server-side (BOX hardware or admin) via service_role key

-- ═════════════════════════════════════════════════════════════════
--  HARDWARE RENTALS  — public read
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE hardware_rentals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "hardware: public read" ON hardware_rentals;
CREATE POLICY "hardware: public read"
  ON hardware_rentals FOR SELECT USING (is_available = true);

-- ═════════════════════════════════════════════════════════════════
--  PRODUCTS & REVIEWS  — public read; authenticated users insert reviews
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE products         ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_reviews  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "products: public read"   ON products;
CREATE POLICY "products: public read"
  ON products FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "product_reviews: public read"   ON product_reviews;
CREATE POLICY "product_reviews: public read"
  ON product_reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "product_reviews: auth insert"   ON product_reviews;
CREATE POLICY "product_reviews: auth insert"
  ON product_reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "product_reviews: owner update"  ON product_reviews;
CREATE POLICY "product_reviews: owner update"
  ON product_reviews FOR UPDATE
  USING (auth.uid() = user_id);

-- ═════════════════════════════════════════════════════════════════
--  DELIVERY ADDRESSES  — owner read/write
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE delivery_addresses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "addresses: owner read"   ON delivery_addresses;
CREATE POLICY "addresses: owner read"
  ON delivery_addresses FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "addresses: owner insert" ON delivery_addresses;
CREATE POLICY "addresses: owner insert"
  ON delivery_addresses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "addresses: owner update" ON delivery_addresses;
CREATE POLICY "addresses: owner update"
  ON delivery_addresses FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "addresses: owner delete" ON delivery_addresses;
CREATE POLICY "addresses: owner delete"
  ON delivery_addresses FOR DELETE
  USING (auth.uid() = user_id);

-- ═════════════════════════════════════════════════════════════════
--  ORDERS  — owner read/write
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orders: owner read"   ON orders;
CREATE POLICY "orders: owner read"
  ON orders FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "orders: owner insert" ON orders;
CREATE POLICY "orders: owner insert"
  ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ═════════════════════════════════════════════════════════════════
--  FRIENDS  — owner read/write
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "friends: owner read"   ON friends;
CREATE POLICY "friends: owner read"
  ON friends FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS "friends: owner insert" ON friends;
CREATE POLICY "friends: owner insert"
  ON friends FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "friends: owner update" ON friends;
CREATE POLICY "friends: owner update"
  ON friends FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- ═════════════════════════════════════════════════════════════════
--  PICKUP GAMES  — public read; creator write
-- ═════════════════════════════════════════════════════════════════
ALTER TABLE pickup_games ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pickup: public read"    ON pickup_games;
CREATE POLICY "pickup: public read"
  ON pickup_games FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "pickup: creator insert" ON pickup_games;
CREATE POLICY "pickup: creator insert"
  ON pickup_games FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "pickup: creator update" ON pickup_games;
CREATE POLICY "pickup: creator update"
  ON pickup_games FOR UPDATE
  USING (auth.uid() = creator_id);
