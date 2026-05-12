-- ─────────────────────────────────────────────────────────────────
--  COURTSIDE — Seed Data + Missing Tables
--  Run AFTER 003_rls.sql
--  Safe to re-run: all inserts use ON CONFLICT DO NOTHING.
-- ─────────────────────────────────────────────────────────────────

-- ═══════════════════════════════════════════════════════════════
--  PRODUCTS TABLE  (missing from earlier migration)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS products (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  brand           text DEFAULT '',
  category        text NOT NULL,
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

-- ═══════════════════════════════════════════════════════════════
--  PRODUCT REVIEWS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS product_reviews (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id     uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id        uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating         integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title          text DEFAULT '',
  comment        text DEFAULT '',
  verified       boolean DEFAULT false,
  helpful_count  integer DEFAULT 0,
  created_at     timestamptz DEFAULT now(),
  UNIQUE (product_id, user_id)
);

CREATE INDEX IF NOT EXISTS product_reviews_product_idx ON product_reviews (product_id);
CREATE INDEX IF NOT EXISTS product_reviews_user_idx    ON product_reviews (user_id);

-- ═══════════════════════════════════════════════════════════════
--  DELIVERY ADDRESSES TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS delivery_addresses (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label       text DEFAULT 'Home',
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

-- ═══════════════════════════════════════════════════════════════
--  ORDERS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS orders (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  address_id      uuid REFERENCES delivery_addresses(id) ON DELETE SET NULL,
  status          text NOT NULL DEFAULT 'placed'
                    CHECK (status IN ('placed','confirmed','shipped','out_for_delivery','delivered','cancelled','returned')),
  items           jsonb NOT NULL DEFAULT '[]',
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

-- ═══════════════════════════════════════════════════════════════
--  FRIENDS TABLE
-- ═══════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════
--  PHONE COLUMN on user_profiles (for invite lookup)
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS phone text UNIQUE;

CREATE INDEX IF NOT EXISTS user_profiles_phone_idx ON user_profiles (phone)
  WHERE phone IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════
--  RLS for new tables
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_reviews   ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE friends           ENABLE ROW LEVEL SECURITY;

-- products: public read
DROP POLICY IF EXISTS "products: public read" ON products;
CREATE POLICY "products: public read"
  ON products FOR SELECT USING (is_active = true);

-- product_reviews: public read, auth insert/update own
DROP POLICY IF EXISTS "product_reviews: public read" ON product_reviews;
CREATE POLICY "product_reviews: public read"
  ON product_reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "product_reviews: auth insert" ON product_reviews;
CREATE POLICY "product_reviews: auth insert"
  ON product_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "product_reviews: owner update" ON product_reviews;
CREATE POLICY "product_reviews: owner update"
  ON product_reviews FOR UPDATE USING (auth.uid() = user_id);

-- delivery_addresses: owner CRUD
DROP POLICY IF EXISTS "addresses: owner read"   ON delivery_addresses;
CREATE POLICY "addresses: owner read"
  ON delivery_addresses FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "addresses: owner insert" ON delivery_addresses;
CREATE POLICY "addresses: owner insert"
  ON delivery_addresses FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "addresses: owner update" ON delivery_addresses;
CREATE POLICY "addresses: owner update"
  ON delivery_addresses FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "addresses: owner delete" ON delivery_addresses;
CREATE POLICY "addresses: owner delete"
  ON delivery_addresses FOR DELETE USING (auth.uid() = user_id);

-- orders: owner read/insert
DROP POLICY IF EXISTS "orders: owner read"   ON orders;
CREATE POLICY "orders: owner read"
  ON orders FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "orders: owner insert" ON orders;
CREATE POLICY "orders: owner insert"
  ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);

-- friends: owner read/write
DROP POLICY IF EXISTS "friends: owner read"   ON friends;
CREATE POLICY "friends: owner read"
  ON friends FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS "friends: owner insert" ON friends;
CREATE POLICY "friends: owner insert"
  ON friends FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "friends: owner update" ON friends;
CREATE POLICY "friends: owner update"
  ON friends FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- ═══════════════════════════════════════════════════════════════
--  VENUES SEED  (15 real Bengaluru venues)
-- ═══════════════════════════════════════════════════════════════

INSERT INTO venues (id, name, address, area, lat, lng, sports, rating, review_count,
                    opening_time, closing_time, photo_url, amenities, has_the_box, is_active)
VALUES
  ('00000000-0000-0000-0001-000000000001',
   'Game Theory Koramangala',
   '5th Block, Koramangala, Bengaluru', 'Koramangala',
   12.9310, 77.6276,
   ARRAY['basketball','badminton'],
   4.9, 312, '6:00 AM', '11:00 PM', '',
   ARRAY['Parking','Changing Rooms','Water','Floodlights','AC'],
   true, true),

  ('00000000-0000-0000-0001-000000000002',
   'Game Theory Indiranagar',
   '12th Main, Indiranagar, Bengaluru', 'Indiranagar',
   12.9795, 77.6390,
   ARRAY['basketball','badminton'],
   4.8, 278, '6:00 AM', '11:00 PM', '',
   ARRAY['Parking','Water','Floodlights','AC'],
   true, true),

  ('00000000-0000-0000-0001-000000000003',
   'Game Theory HSR Layout',
   'Sector 6, HSR Layout, Bengaluru', 'HSR Layout',
   12.9150, 77.6410,
   ARRAY['basketball','badminton'],
   4.8, 195, '6:00 AM', '11:00 PM', '',
   ARRAY['Parking','Changing Rooms','Water','Floodlights','AC'],
   false, true),

  ('00000000-0000-0000-0001-000000000004',
   'Game Theory JP Nagar',
   '7th Phase, JP Nagar, Bengaluru', 'JP Nagar',
   12.9020, 77.5866,
   ARRAY['basketball','badminton','cricket'],
   4.9, 401, '6:00 AM', '11:00 PM', '',
   ARRAY['Parking','Changing Rooms','Cafeteria','Water','Floodlights','AC'],
   true, true),

  ('00000000-0000-0000-0001-000000000005',
   'Sporthood',
   'Sarjapur - Marathahalli Rd, Bengaluru', 'Sarjapur Road',
   12.9035, 77.6872,
   ARRAY['basketball','badminton','football'],
   4.7, 143, '6:00 AM', '11:59 PM', '',
   ARRAY['Parking','Changing Rooms','Water','Floodlights'],
   false, true),

  ('00000000-0000-0000-0001-000000000006',
   'Sree Kanteerava Stadium',
   'Kasturba Rd, Sampangi Rama Nagar, Bengaluru', 'Central Bengaluru',
   12.9747, 77.5838,
   ARRAY['basketball','cricket','football'],
   4.3, 89, '6:00 AM', '8:00 PM', '',
   ARRAY['Parking','Changing Rooms','Water'],
   false, true),

  ('00000000-0000-0000-0001-000000000007',
   'Koramangala Indoor Stadium',
   '80 Feet Rd, Koramangala 4th Block, Bengaluru', 'Koramangala',
   12.9271, 77.6224,
   ARRAY['basketball','badminton'],
   4.2, 67, '6:00 AM', '9:00 PM', '',
   ARRAY['Parking','Water','Floodlights'],
   false, true),

  ('00000000-0000-0000-0001-000000000008',
   'Madhavan Park Court',
   'Jayanagar 3rd Block, Bengaluru', 'Jayanagar',
   12.9252, 77.5934,
   ARRAY['basketball'],
   4.0, 34, '6:00 AM', '9:00 PM', '',
   ARRAY['Water'],
   false, true),

  ('00000000-0000-0000-0001-000000000009',
   'AVA Multi-Sport Court',
   '1st Main Rd, Abbaiah Reddy Layout, Kaggadasapura', 'Kaggadasapura',
   13.0079, 77.6576,
   ARRAY['basketball','badminton','football'],
   4.5, 112, '6:00 AM', '9:00 PM', '',
   ARRAY['Parking','Changing Rooms','Water'],
   false, true),

  ('00000000-0000-0000-0001-000000000010',
   'Active Arena',
   'Marathahalli, Bengaluru', 'Marathahalli',
   12.9568, 77.7014,
   ARRAY['basketball','badminton'],
   4.4, 88, '6:00 AM', '10:00 PM', '',
   ARRAY['Parking','Changing Rooms','Water','Floodlights'],
   false, true),

  ('00000000-0000-0000-0001-000000000011',
   'Tiger 5',
   'Dairy Circle, Bannerghatta Rd, Bengaluru', 'Bannerghatta Road',
   12.8883, 77.6012,
   ARRAY['basketball','cricket'],
   3.9, 52, '6:00 AM', '10:00 PM', '',
   ARRAY['Parking','Water'],
   false, true),

  ('00000000-0000-0000-0001-000000000012',
   'Basecamp by Push Sports',
   'Palace Road, Bengaluru City University Campus', 'Palace Road',
   13.0064, 77.5848,
   ARRAY['basketball','football'],
   4.6, 134, '6:00 AM', '10:00 PM',
   'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80',
   ARRAY['Parking','Changing Rooms','Cafeteria','Water'],
   true, true),

  ('00000000-0000-0000-0001-000000000013',
   'Indiranagar Sports Club',
   'Near ESI Hospital, Indiranagar', 'Indiranagar',
   12.9780, 77.6440,
   ARRAY['badminton'],
   4.5, 210, '6:00 AM', '10:00 PM',
   'https://images.unsplash.com/photo-1626224580195-f23912418175?w=800&q=80',
   ARRAY['Parking','Shower','AC','Locker'],
   false, true),

  ('00000000-0000-0000-0001-000000000014',
   'Whitefield Stadium',
   'ITPL Main Rd, Whitefield', 'Whitefield',
   12.9840, 77.7280,
   ARRAY['cricket','football'],
   4.7, 540, '6:00 AM', '11:00 PM',
   'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&q=80',
   ARRAY['Ample Parking','Floodlights','Medical Support'],
   false, true),

  ('00000000-0000-0000-0001-000000000015',
   'Bannerghatta Sports Hub',
   'Hulimavu, Bannerghatta Rd', 'Bannerghatta Road',
   12.8750, 77.5950,
   ARRAY['basketball','football','badminton'],
   4.4, 165, '6:00 AM', '11:00 PM',
   'https://images.unsplash.com/photo-1504450758481-7338eba7524a?w=800&q=80',
   ARRAY['Parking','Floodlights','Water'],
   true, true)

ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════
--  COURTS SEED
-- ═══════════════════════════════════════════════════════════════

INSERT INTO courts (id, venue_id, sport, name, surface, is_indoor,
                    price_per_slot, slot_duration_min, has_the_box, is_active)
VALUES
  -- Game Theory Koramangala
  ('00000000-0000-0000-0002-000000000001','00000000-0000-0000-0001-000000000001','basketball','Court 1','Hardwood',        true, 400,45,true, true),
  ('00000000-0000-0000-0002-000000000002','00000000-0000-0000-0001-000000000001','basketball','Court 2','Hardwood',        true, 400,45,false,true),
  ('00000000-0000-0000-0002-000000000003','00000000-0000-0000-0001-000000000001','badminton', 'Court A','Synthetic',       true, 250,45,false,true),

  -- Game Theory Indiranagar
  ('00000000-0000-0000-0002-000000000004','00000000-0000-0000-0001-000000000002','basketball','Court 1','Hardwood',        true, 450,45,true, true),
  ('00000000-0000-0000-0002-000000000005','00000000-0000-0000-0001-000000000002','badminton', 'Court A','Synthetic',       true, 280,45,false,true),

  -- Game Theory HSR
  ('00000000-0000-0000-0002-000000000006','00000000-0000-0000-0001-000000000003','basketball','Court 1','Hardwood',        true, 400,45,false,true),

  -- Game Theory JP Nagar
  ('00000000-0000-0000-0002-000000000007','00000000-0000-0000-0001-000000000004','basketball','Court 1','Hardwood',        true, 380,45,true, true),
  ('00000000-0000-0000-0002-000000000008','00000000-0000-0000-0001-000000000004','cricket',   'Turf A', 'Artificial Turf', true, 600,60,false,true),

  -- Sporthood
  ('00000000-0000-0000-0002-000000000009','00000000-0000-0000-0001-000000000005','basketball','Full Court','Hardwood',      true, 500,60,false,true),
  ('00000000-0000-0000-0002-000000000010','00000000-0000-0000-0001-000000000005','football',  'Turf A','Artificial Turf',   true, 800,60,false,true),

  -- Kanteerava
  ('00000000-0000-0000-0002-000000000011','00000000-0000-0000-0001-000000000006','basketball','Court 1','Concrete',        false,200,60,false,true),

  -- Koramangala Indoor
  ('00000000-0000-0000-0002-000000000012','00000000-0000-0000-0001-000000000007','basketball','Court 1','Concrete',        true, 300,45,false,true),

  -- Madhavan Park
  ('00000000-0000-0000-0002-000000000013','00000000-0000-0000-0001-000000000008','basketball','Outdoor Court','Concrete',  false,  0,60,false,true),

  -- AVA
  ('00000000-0000-0000-0002-000000000014','00000000-0000-0000-0001-000000000009','basketball','Court 1','Rubber',           true, 350,45,false,true),

  -- Active Arena
  ('00000000-0000-0000-0002-000000000015','00000000-0000-0000-0001-000000000010','basketball','Court 1','Hardwood',         true, 420,45,false,true),

  -- Tiger 5
  ('00000000-0000-0000-0002-000000000016','00000000-0000-0000-0001-000000000011','basketball','Court 1','Rubber',           true, 300,45,false,true),

  -- Basecamp
  ('00000000-0000-0000-0002-000000000017','00000000-0000-0000-0001-000000000012','basketball','Court 1','Hardwood',         true, 450,45,true, true)

ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════
--  SLOTS  — generate 14 days of slots for all courts
--  Uses the generate_slots_for_court() function from 002_functions.sql
-- ═══════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_court uuid;
  v_date  date;
BEGIN
  FOR v_court IN SELECT id FROM courts WHERE is_active = true LOOP
    FOR v_date IN
      SELECT generate_series(current_date, current_date + 13, '1 day'::interval)::date
    LOOP
      PERFORM generate_slots_for_court(v_court, v_date, '06:00'::time, '22:00'::time, 60);
    END LOOP;
  END LOOP;
END;
$$;

-- ═══════════════════════════════════════════════════════════════
--  PRODUCTS SEED  (30 products across 6 categories)
-- ═══════════════════════════════════════════════════════════════

INSERT INTO products (id, name, brand, category, price, original_price,
                      rating, review_count, description, specifications, tags, in_stock, stock_qty)
VALUES
  -- HYDRATION
  (gen_random_uuid(),'Gatorade Blue Bolt 500ml','Gatorade','Hydration',120,150,4.5,2847,
   'Isotonic sports drink for rapid rehydration. Packed with electrolytes.',
   '{"Volume":"500ml","Calories":"90kcal","Sodium":"110mg"}',
   ARRAY['sports drink','electrolytes','hydration'],true,200),

  (gen_random_uuid(),'Pocari Sweat Ion Drink 500ml','Pocari Sweat','Hydration',65,80,4.3,1243,
   'Smooth ion balance drink that replaces water and ions lost through sweat.',
   '{"Volume":"500ml","Calories":"25kcal","Sodium":"49mg"}',
   ARRAY['ion drink','hydration','recovery'],true,150),

  (gen_random_uuid(),'Electral ORS Sachets (10 pack)','Electral','Hydration',149,199,4.7,3102,
   'WHO-formulated oral rehydration salts for rapid recovery.',
   '{"Pack":"10 sachets","Net Weight":"21.8g each","Flavor":"Lemon"}',
   ARRAY['ORS','electrolytes','recovery'],true,300),

  (gen_random_uuid(),'Red Bull Energy Drink 250ml','Red Bull','Hydration',125,150,4.4,5620,
   '80mg caffeine per can for sustained focus and energy during competition.',
   '{"Volume":"250ml","Caffeine":"80mg","Niacin (B3)":"22mg"}',
   ARRAY['energy drink','caffeine','focus'],true,500),

  (gen_random_uuid(),'Fast&Up Reload Electrolyte (20 tabs)','Fast&Up','Hydration',349,499,4.6,1876,
   'Effervescent electrolyte tablets. Drop in water for instant isotonic sports fuel.',
   '{"Tablets":"20","Flavor":"Orange","Sodium":"200mg","Sugar-free":"Yes"}',
   ARRAY['electrolyte tabs','effervescent','sugar-free'],true,100),

  (gen_random_uuid(),'Decathlon Sports Bottle 1.5L','Decathlon','Hydration',499,799,4.8,4391,
   'BPA-free Tritan bottle with one-click flip cap. Dishwasher safe and leak-proof.',
   '{"Capacity":"1.5L","Material":"Tritan BPA-Free","Leak-proof":"Yes"}',
   ARRAY['water bottle','BPA-free','tritan'],true,80),

  -- NUTRITION
  (gen_random_uuid(),'ON Gold Standard Whey 1kg','Optimum Nutrition','Nutrition',2499,3499,4.8,8932,
   '24g of protein per serving with BCAAs and glutamine for muscle recovery.',
   '{"Protein":"24g/serving","Servings":"29","Calories":"120kcal"}',
   ARRAY['whey protein','muscle recovery','BCAAs'],true,50),

  (gen_random_uuid(),'MyProtein Impact Whey 1kg','MyProtein','Nutrition',1799,2499,4.6,4521,
   '21g protein per serving from grass-fed cows.',
   '{"Protein":"21g/serving","Servings":"40","Calories":"103kcal"}',
   ARRAY['whey','lean gains','grass-fed'],true,60),

  (gen_random_uuid(),'MuscleBlaze Energy Bar (6 pack)','MuscleBlaze','Nutrition',349,499,4.4,2134,
   'High-energy bars for sustained performance. No added sugar.',
   '{"Pack":"6 bars","Protein":"10g/bar","Calories":"160kcal"}',
   ARRAY['energy bar','pre-workout','no added sugar'],true,120),

  (gen_random_uuid(),'Ritebite Max Protein Bar','Ritebite','Nutrition',99,130,4.3,3287,
   '20g protein bar — perfect post-game recovery snack.',
   '{"Protein":"20g","Weight":"67g","Calories":"230kcal"}',
   ARRAY['protein bar','post-workout','recovery'],true,200),

  (gen_random_uuid(),'Unived RRUNN Energy Gels (5 pack)','Unived','Nutrition',599,799,4.5,987,
   'Natural energy gels for endurance sports.',
   '{"Pack":"5 gels","Carbs":"22g/gel","Sodium":"50mg"}',
   ARRAY['energy gel','endurance','natural'],true,90),

  -- EQUIPMENT
  (gen_random_uuid(),'NIVIA Storm Football Size 5','NIVIA','Equipment',699,999,4.5,3412,
   'Match-grade synthetic leather football. 32 hand-stitched panels.',
   '{"Size":"5","Material":"Synthetic Leather","Panels":"32","Weight":"410-450g"}',
   ARRAY['football','match ball','size 5'],true,40),

  (gen_random_uuid(),'NIVIA Basketball Size 7','NIVIA','Equipment',899,1299,4.6,2678,
   'Pro-grade basketball with deep channel design for enhanced grip.',
   '{"Size":"7","Circumference":"75-76cm","Material":"Composite Leather"}',
   ARRAY['basketball','size 7','composite leather'],true,35),

  (gen_random_uuid(),'Yonex Arcsaber 7 Play Racket','Yonex','Equipment',2999,4499,4.7,1892,
   'Graphite shaft with integrated T-joint. Balanced flex for maximum repulsion.',
   '{"Weight":"85g ±2g","Flex":"Medium","Frame":"Graphite","Max Tension":"25 lbs"}',
   ARRAY['badminton racket','graphite','intermediate'],true,25),

  (gen_random_uuid(),'SG KLR Xtreme Cricket Bat','SG','Equipment',3499,4999,4.6,1245,
   'English Willow Grade 2. Ready-to-play, oil-treated.',
   '{"Grade":"English Willow G2","Handle":"Cane","Weight":"1100-1200g"}',
   ARRAY['cricket bat','english willow','SG'],true,20),

  (gen_random_uuid(),'Kookaburra Cricket Balls (3 pack)','Kookaburra','Equipment',799,999,4.5,876,
   'Practice-grade leather cricket balls with 4-piece construction.',
   '{"Pack":"3 balls","Weight":"155.9-163g","Seam":"6-row stitched"}',
   ARRAY['cricket ball','leather','practice'],true,75),

  (gen_random_uuid(),'Cosco Cricket Batting Gloves','Cosco','Equipment',699,999,4.3,654,
   'Reinforced palm with scatter foam knuckle protection.',
   '{"Size":"Adult","Palm":"PU/Rubber","Fingers":"Scatter Foam"}',
   ARRAY['batting gloves','cricket','knuckle protection'],true,45),

  (gen_random_uuid(),'Yonex Mavis 350 Shuttlecocks (6 pack)','Yonex','Equipment',799,1099,4.8,5231,
   'Nylon shuttlecocks with real-feather feel and consistent flight.',
   '{"Pack":"6 shuttles","Material":"Nylon","Speed":"Medium (Yellow)"}',
   ARRAY['shuttlecock','nylon','consistent flight'],true,100),

  (gen_random_uuid(),'Wilson Pro Grip Tape (3 pack)','Wilson','Equipment',299,399,4.6,2134,
   'Tacky feel with high moisture absorption. 110cm per tape.',
   '{"Pack":"3 tapes","Length":"110cm each","Thickness":"0.6mm"}',
   ARRAY['grip tape','racket','badminton'],true,150),

  (gen_random_uuid(),'Cosco Ball Pump with Needle Kit','Cosco','Equipment',199,299,4.2,1678,
   'Dual-action pump for fast inflation. Includes pressure gauge and 2 needles.',
   '{"Type":"Dual Action","Max PSI":"15 PSI","Needles":"2 included"}',
   ARRAY['ball pump','inflation','dual action'],true,60),

  -- FOOTWEAR
  (gen_random_uuid(),'Nike Court Vision Low Basketball','Nike','Footwear',3999,5999,4.7,3421,
   'Classic low-top with perforated leather upper. Waffle-pattern outsole for court traction.',
   '{"Upper":"Perforated Leather","Sole":"Rubber Waffle","Sizes":"UK 6-13"}',
   ARRAY['basketball shoes','Nike','low-top court'],true,30),

  (gen_random_uuid(),'Adidas Predator 24 Football Cleats','Adidas','Footwear',3499,5499,4.5,2187,
   'Control Zone upper for enhanced ball contact. Firm ground rubber studs.',
   '{"Upper":"Synthetic","Sole":"Firm Ground","Studs":"Rubber","Sizes":"UK 6-12"}',
   ARRAY['football cleats','adidas','firm ground'],true,25),

  (gen_random_uuid(),'Yonex Power Cushion Badminton Shoes','Yonex','Footwear',2999,4499,4.7,1654,
   'Power Cushion+ technology for superior impact absorption.',
   '{"Upper":"Mesh + Synthetic","Sole":"Gum Rubber","Cushion":"Power Cushion+"}',
   ARRAY['badminton shoes','Yonex','court shoes'],true,20),

  (gen_random_uuid(),'Decathlon Sports Socks (3 pack)','Decathlon','Footwear',199,299,4.4,7823,
   'Cushioned arch compression for all-day comfort. Anti-blister terry loop construction.',
   '{"Pack":"3 pairs","Material":"80% Cotton","Sizes":"S / M / L / XL"}',
   ARRAY['sports socks','cushioned','anti-blister'],true,300),

  -- APPAREL
  (gen_random_uuid(),'Jordan Dri-FIT Basketball Jersey','Jordan / Nike','Apparel',1299,1999,4.6,2341,
   'Nike Dri-FIT technology moves sweat away fast. Mesh side panels for breathability.',
   '{"Material":"Polyester Dri-FIT","Fit":"Regular","Sizes":"XS-3XL"}',
   ARRAY['basketball jersey','Jordan','Dri-FIT'],true,40),

  (gen_random_uuid(),'Cricket Performance Tee SPF50','Decathlon','Apparel',799,1099,4.5,1897,
   'Quick-dry polyester with SPF50+ sun protection. Built for long innings.',
   '{"Material":"Polyester","SPF":"50+","Fit":"Regular","Sizes":"S-2XL"}',
   ARRAY['cricket tee','SPF protection','quick-dry'],true,55),

  (gen_random_uuid(),'Nike Pro Compression Tights','Nike','Apparel',1499,2499,4.7,3102,
   'Nike Pro Dri-FIT fabric with 4-way stretch. Flatlock seams for zero irritation.',
   '{"Material":"85% Polyester / 15% Elastane","Fit":"Tight","Length":"Full"}',
   ARRAY['compression tights','Nike','muscle support'],true,35),

  (gen_random_uuid(),'Adidas Training Mesh Shorts','Adidas','Apparel',599,899,4.4,2654,
   'Aeroready moisture-absorbing fabric. Side pockets, internal drawstring.',
   '{"Material":"Polyester Aeroready","Length":"7 inch","Pockets":"2 side + 1 back"}',
   ARRAY['training shorts','adidas','aeroready'],true,60),

  -- PROTECTION
  (gen_random_uuid(),'Tynor Knee Sleeves (pair)','Tynor','Protection',599,899,4.7,4231,
   'Medical-grade neoprene with anatomical design. Graduated compression for injury prevention.',
   '{"Material":"Neoprene","Pack":"Pair","Sizes":"S / M / L / XL","Compression":"Medium"}',
   ARRAY['knee sleeve','neoprene','compression'],true,80),

  (gen_random_uuid(),'McDavid Ankle Support Brace','McDavid','Protection',449,699,4.6,2876,
   'Figure-8 strap system for lateral ankle stability. Reduces re-injury risk.',
   '{"Material":"Nylon Elastic","Straps":"Figure-8","Heel":"Open heel"}',
   ARRAY['ankle brace','ankle support','lateral stability'],true,65)

ON CONFLICT (id) DO NOTHING;
