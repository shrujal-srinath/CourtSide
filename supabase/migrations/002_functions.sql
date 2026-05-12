-- ─────────────────────────────────────────────────────────────────
--  COURTSIDE — Database Functions & RPCs
--  Run AFTER 001_schema.sql
-- ─────────────────────────────────────────────────────────────────

-- ═════════════════════════════════════════════════════════════════
--  book_slot
--
--  Atomically reserves a slot and writes the booking record in a
--  single SERIALIZABLE transaction, preventing double-bookings.
--
--  Called by BookingService.createBooking() immediately after
--  Razorpay confirms payment.
--
--  Returns: new booking UUID
--  Raises: 'P0001' if slot is no longer available
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION book_slot(
  p_slot_id               uuid,
  p_court_id              uuid,
  p_user_id               uuid,
  p_venue_id              uuid,
  p_venue_name            text,
  p_sport                 text,
  p_amount                integer,
  p_payment_id            text    DEFAULT '',
  p_time_slot             text    DEFAULT '',
  p_phone_scoring         boolean DEFAULT false,
  p_hardware_option_id    uuid    DEFAULT NULL,
  p_is_public_game        boolean DEFAULT false,
  p_player_limit          integer DEFAULT 10
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking_id uuid;
BEGIN
  -- Lock the slot row for this transaction.
  -- If status != 'available', the slot was taken concurrently.
  PERFORM 1
    FROM slots
   WHERE id = p_slot_id
     AND status = 'available'
     FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Slot is no longer available'
      USING ERRCODE = 'P0001';
  END IF;

  -- Write the confirmed booking
  INSERT INTO bookings (
    user_id,
    slot_id,
    court_id,
    venue_id,
    venue_name,
    sport,
    cs_status,
    amount_paid,
    payment_id,
    time_slot,
    phone_scoring_enabled,
    hardware_option_id,
    is_public_game,
    player_limit
  ) VALUES (
    p_user_id,
    p_slot_id,
    p_court_id,
    p_venue_id,
    p_venue_name,
    p_sport,
    'upcoming',
    p_amount,
    p_payment_id,
    p_time_slot,
    p_phone_scoring,
    p_hardware_option_id,
    p_is_public_game,
    p_player_limit
  )
  RETURNING id INTO v_booking_id;

  -- Mark slot as booked so no other user can take it
  UPDATE slots
     SET status = 'booked'
   WHERE id = p_slot_id;

  RETURN v_booking_id;
END;
$$;

-- ═════════════════════════════════════════════════════════════════
--  increment_slot_booked
--
--  Non-fatal counter increment — cosmetic only.
--  Called after book_slot succeeds; failure is silently swallowed
--  by the client (BookingService) so it never blocks the user.
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION increment_slot_booked(p_slot_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE slots SET booked_count = booked_count + 1 WHERE id = p_slot_id;
$$;

-- ═════════════════════════════════════════════════════════════════
--  complete_booking
--
--  Called by the server (or venue admin) when a game finishes.
--  Sets cs_status = 'completed' and records that stats are ready.
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION complete_booking(p_booking_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE bookings
     SET cs_status = 'completed'
   WHERE id = p_booking_id
     AND cs_status = 'upcoming';
$$;

-- ═════════════════════════════════════════════════════════════════
--  cancel_booking
--
--  User-facing cancellation. Only upcoming bookings can be
--  cancelled. The slot is released back to 'available'.
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION cancel_booking(
  p_booking_id uuid,
  p_user_id    uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_slot_id uuid;
BEGIN
  -- Only let the owner cancel, only if still upcoming
  UPDATE bookings
     SET cs_status = 'cancelled'
   WHERE id      = p_booking_id
     AND user_id = p_user_id
     AND cs_status = 'upcoming'
  RETURNING slot_id INTO v_slot_id;

  -- Release the slot so others can book it
  IF v_slot_id IS NOT NULL THEN
    UPDATE slots SET status = 'available' WHERE id = v_slot_id;
  END IF;
END;
$$;

-- ═════════════════════════════════════════════════════════════════
--  generate_slots_for_court
--
--  Utility: generate all 1-hour slots between open/close for a
--  given court + date. Run from cron or admin panel.
--
--  Example:
--    SELECT generate_slots_for_court(
--      '<court-uuid>', '2024-10-20', '06:00'::time, '22:00'::time, 60
--    );
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION generate_slots_for_court(
  p_court_id        uuid,
  p_date            date,
  p_open_time       time DEFAULT '06:00',
  p_close_time      time DEFAULT '22:00',
  p_duration_min    integer DEFAULT 60
)
RETURNS integer   -- returns number of slots created
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_start     time := p_open_time;
  v_end       time;
  v_count     integer := 0;
BEGIN
  WHILE v_start < p_close_time LOOP
    v_end := v_start + (p_duration_min || ' minutes')::interval;

    IF v_end > p_close_time THEN
      EXIT;
    END IF;

    INSERT INTO slots (venue_court_id, date, start_time, end_time, status)
    VALUES (p_court_id, p_date, v_start, v_end, 'available')
    ON CONFLICT (venue_court_id, date, start_time) DO NOTHING;

    v_count := v_count + 1;
    v_start := v_end;
  END LOOP;

  RETURN v_count;
END;
$$;

-- ═════════════════════════════════════════════════════════════════
--  update_venue_rating
--
--  Trigger function: recalculates a venue's aggregate rating
--  whenever a product_review is inserted/updated/deleted.
--  Extend this later for venue-specific reviews.
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_product_review_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE products
     SET rating       = sub.avg_rating,
         review_count = sub.cnt
    FROM (
      SELECT AVG(rating)::numeric(3,1) AS avg_rating,
             COUNT(*)::integer         AS cnt
        FROM product_reviews
       WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
    ) sub
   WHERE id = COALESCE(NEW.product_id, OLD.product_id);
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_product_review_count ON product_reviews;
CREATE TRIGGER trg_product_review_count
  AFTER INSERT OR UPDATE OR DELETE ON product_reviews
  FOR EACH ROW EXECUTE FUNCTION update_product_review_count();
