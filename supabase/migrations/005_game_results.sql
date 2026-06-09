-- ─────────────────────────────────────────────────────────────────
--  COURTSIDE — Game Results & Verified Stats
--  Run AFTER 004_seed.sql
--
--  NOTE: this DB is shared with the BOX hardware/realtime scoring system,
--  which already owns a `games` table (PK `code`). Courtside's per-game
--  record therefore lives in `courtside_games` to avoid collision.
--
--  This migration is where the product's moat lives in code.
--  player_stats has PUBLIC READ but NO client write policy — by design.
--  The ONLY path that writes a verified stat is submit_game_result()
--  below: SECURITY DEFINER, enforcing the time-gate server-side
--  (15 min before tip-off → 4 h after start). Fail any check → it raises;
--  the client cannot fabricate a verified stat. Unverified free-play
--  games never call this RPC (they stay device-local).
-- ─────────────────────────────────────────────────────────────────

-- ═════════════════════════════════════════════════════════════════
--  COURTSIDE_GAMES — one row per completed Courtside phone-scored game.
--  player_stats is the career aggregate; this is the single-game record
--  the stat card and game history read from.
-- ═════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS courtside_games (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id    uuid REFERENCES bookings(id) ON DELETE SET NULL,
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sport         text NOT NULL,
  is_verified   boolean NOT NULL DEFAULT false,
  won           boolean NOT NULL DEFAULT false,
  score_for     integer NOT NULL DEFAULT 0,   -- the submitter's team score
  score_against integer NOT NULL DEFAULT 0,
  my_line       jsonb   NOT NULL DEFAULT '{}', -- submitter's own stat line
  player_lines  jsonb   NOT NULL DEFAULT '[]', -- full box score (all players)
  played_at     timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS courtside_games_user_idx    ON courtside_games (user_id, played_at DESC);
CREATE INDEX IF NOT EXISTS courtside_games_booking_idx ON courtside_games (booking_id);
CREATE INDEX IF NOT EXISTS courtside_games_sport_idx   ON courtside_games (sport);

ALTER TABLE courtside_games ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "courtside_games: public read" ON courtside_games;
CREATE POLICY "courtside_games: public read"
  ON courtside_games FOR SELECT USING (true);

-- ═════════════════════════════════════════════════════════════════
--  cs_accumulate_stats(existing, addition)
--  Adds the numeric fields of `addition` into `existing`, key by key.
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION cs_accumulate_stats(existing jsonb, addition jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(existing, '{}'::jsonb) || (
    SELECT jsonb_object_agg(
             k,
             COALESCE((existing ->> k)::numeric, 0) + COALESCE((addition ->> k)::numeric, 0)
           )
      FROM jsonb_object_keys(COALESCE(addition, '{}'::jsonb)) AS k
  );
$$;

-- ═════════════════════════════════════════════════════════════════
--  submit_game_result  — the verified-stat write path.
--
--  Enforces (server-side, un-forgeable):
--    1. caller is authenticated
--    2. the booking exists AND belongs to the caller
--    3. now() is inside the scoring window for that booking's slot
--       (15 min before start → 4 h after start), slot time anchored
--       to Asia/Kolkata.
--
--  On success: inserts a verified courtside_games row, upserts
--  player_stats, marks the booking completed.
--  Raises 'P0001' if the booking is missing/foreign or out of window.
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION submit_game_result(
  p_booking_id    uuid,
  p_sport         text,
  p_won           boolean,
  p_score_for     integer,
  p_score_against integer,
  p_my_line       jsonb,
  p_player_lines  jsonb DEFAULT '[]'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid       uuid := auth.uid();
  v_owner     uuid;
  v_slot_id   text;
  v_start_ts  timestamptz;
  v_game_id   uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = 'P0001';
  END IF;

  SELECT user_id, slot_id
    INTO v_owner, v_slot_id
    FROM bookings
   WHERE id = p_booking_id;

  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0001';
  END IF;

  IF v_owner <> v_uid THEN
    RAISE EXCEPTION 'Booking does not belong to caller' USING ERRCODE = 'P0001';
  END IF;

  -- Slot times are IST wall-clock; anchor to Asia/Kolkata for a correct instant.
  SELECT (date + start_time::time) AT TIME ZONE 'Asia/Kolkata'
    INTO v_start_ts
    FROM slots
   WHERE id = v_slot_id;

  IF v_start_ts IS NULL
     OR now() < v_start_ts - interval '15 minutes'
     OR now() > v_start_ts + interval '4 hours' THEN
    RAISE EXCEPTION 'Outside scoring window' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO courtside_games (
    booking_id, user_id, sport, is_verified, won,
    score_for, score_against, my_line, player_lines, played_at
  ) VALUES (
    p_booking_id, v_uid, p_sport, true, p_won,
    p_score_for, p_score_against, p_my_line, p_player_lines, now()
  )
  RETURNING id INTO v_game_id;

  INSERT INTO player_stats (user_id, sport, games_played, wins, stats, updated_at)
  VALUES (
    v_uid, p_sport, 1, CASE WHEN p_won THEN 1 ELSE 0 END,
    cs_accumulate_stats('{}'::jsonb, p_my_line), now()
  )
  ON CONFLICT (user_id, sport) DO UPDATE
     SET games_played = player_stats.games_played + 1,
         wins         = player_stats.wins + CASE WHEN p_won THEN 1 ELSE 0 END,
         stats        = cs_accumulate_stats(player_stats.stats, p_my_line),
         updated_at   = now();

  -- complete_booking() isn't present on this DB — inline the same effect.
  UPDATE bookings
     SET cs_status = 'completed'
   WHERE id = p_booking_id
     AND cs_status = 'upcoming';

  RETURN v_game_id;
END;
$$;
