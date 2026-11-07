-- Gene - Nov 07, 2026: High-Scale Architecture Migration
-- Adds:
-- 1. Composite indexes for date-windowed bookings & paginated marketplace discovery
-- 2. Persistent `public.client_crm_dossiers` table with Row-Level Security (RLS)
-- 3. Privacy-safe `public.get_busy_slots_for_date` and `public.get_available_slots` RPCs
-- 4. Server-side `public.get_business_crm_profiles` paginated LTV aggregation RPC

-- 1. High-Scale Composite Indexes
CREATE INDEX IF NOT EXISTS idx_bookings_business_start_status
    ON public.bookings(business_id, start_time, status);

CREATE INDEX IF NOT EXISTS idx_bookings_business_date_from_status
    ON public.bookings(business_id, date_from, status);

CREATE INDEX IF NOT EXISTS idx_businesses_active_category_rating
    ON public.businesses(is_active, category, rating_avg DESC);

-- 2. Persistent Client CRM Dossiers Table (Medical Flags & Staff Clinical Notes)
CREATE TABLE IF NOT EXISTS public.client_crm_dossiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    medical_flags JSONB NOT NULL DEFAULT '[]'::jsonb,
    internal_staff_notes JSONB NOT NULL DEFAULT '[]'::jsonb,
    status_tag_override TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(business_id, client_id)
);

CREATE INDEX IF NOT EXISTS idx_crm_dossiers_business_client
    ON public.client_crm_dossiers(business_id, client_id);

ALTER TABLE public.client_crm_dossiers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Business owners can view their client CRM dossiers" ON public.client_crm_dossiers;
CREATE POLICY "Business owners can view their client CRM dossiers"
ON public.client_crm_dossiers FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Business owners can manage their client CRM dossiers" ON public.client_crm_dossiers;
CREATE POLICY "Business owners can manage their client CRM dossiers"
ON public.client_crm_dossiers FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
);

-- 3. Privacy-Safe Busy Slots RPC (Returns occupied time ranges without exposing PII)
CREATE OR REPLACE FUNCTION public.get_busy_slots_for_date(
    p_business_id UUID,
    p_date DATE,
    p_staff_id UUID DEFAULT NULL
)
RETURNS TABLE (
    booking_id UUID,
    staff_id UUID,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    status TEXT,
    hold_expires_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.id AS booking_id,
        b.staff_id,
        b.start_time,
        b.end_time,
        b.status,
        b.hold_expires_at
    FROM public.bookings b
    WHERE b.business_id = p_business_id
      AND b.start_time IS NOT NULL
      AND b.end_time IS NOT NULL
      AND (b.start_time AT TIME ZONE 'UTC')::date = p_date
      AND (p_staff_id IS NULL OR b.staff_id IS NULL OR b.staff_id = p_staff_id)
      AND b.status NOT IN ('cancelled', 'rejected')
      AND (
          b.status != 'awaiting_payment'
          OR (b.hold_expires_at IS NOT NULL AND b.hold_expires_at > now())
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 4. Server-Side Slot Availability Calculation RPC
CREATE OR REPLACE FUNCTION public.get_available_slots(
    p_business_id UUID,
    p_date DATE,
    p_duration_minutes INT DEFAULT NULL,
    p_staff_id UUID DEFAULT NULL
)
RETURNS TABLE (
    slot_start TIMESTAMPTZ,
    slot_end TIMESTAMPTZ,
    is_available BOOLEAN
) AS $$
DECLARE
    v_settings JSONB;
    v_weekday TEXT;
    v_day_cfg JSONB;
    v_is_open BOOLEAN;
    v_open_str TEXT;
    v_close_str TEXT;
    v_step_interval INT;
    v_slot_duration INT;
    v_buffer_minutes INT;
    v_day_start TIMESTAMPTZ;
    v_day_end TIMESTAMPTZ;
    v_curr TIMESTAMPTZ;
    v_candidate_end TIMESTAMPTZ;
    v_occupied BOOLEAN;
BEGIN
    SELECT b.settings INTO v_settings
    FROM public.businesses b
    WHERE b.id = p_business_id;

    IF v_settings IS NULL THEN
        RETURN;
    END IF;

    v_step_interval := COALESCE((v_settings->>'slot_interval_minutes')::int, 30);
    IF v_step_interval <= 0 THEN v_step_interval := 30; END IF;

    v_slot_duration := COALESCE(NULLIF(p_duration_minutes, 0), v_step_interval);
    v_buffer_minutes := COALESCE((v_settings->>'buffer_minutes')::int, 0);

    v_weekday := trim(lower(to_char(p_date, 'day')));
    v_day_cfg := v_settings->'working_hours'->v_weekday;

    IF v_day_cfg IS NOT NULL THEN
        v_is_open := COALESCE((v_day_cfg->>'is_open')::boolean, true);
        IF NOT v_is_open THEN
            RETURN;
        END IF;
        v_open_str := COALESCE(v_day_cfg->>'open', '09:00');
        v_close_str := COALESCE(v_day_cfg->>'close', '18:00');
    ELSE
        v_open_str := '09:00';
        v_close_str := '17:00';
    END IF;

    v_day_start := (p_date::text || ' ' || v_open_str || ':00+00')::timestamptz;
    v_day_end := (p_date::text || ' ' || v_close_str || ':00+00')::timestamptz;

    v_curr := v_day_start;
    WHILE v_curr + make_interval(mins => v_slot_duration) <= v_day_end LOOP
        v_candidate_end := v_curr + make_interval(mins => v_slot_duration);

        SELECT EXISTS (
            SELECT 1
            FROM public.bookings bk
            WHERE bk.business_id = p_business_id
              AND bk.start_time IS NOT NULL
              AND bk.end_time IS NOT NULL
              AND (p_staff_id IS NULL OR bk.staff_id IS NULL OR bk.staff_id = p_staff_id)
              AND bk.status NOT IN ('cancelled', 'rejected')
              AND (
                  bk.status != 'awaiting_payment'
                  OR (bk.hold_expires_at IS NOT NULL AND bk.hold_expires_at > now())
              )
              AND v_curr < (bk.end_time + make_interval(mins => v_buffer_minutes))
              AND (v_candidate_end + make_interval(mins => v_buffer_minutes)) > bk.start_time
        ) INTO v_occupied;

        slot_start := v_curr;
        slot_end := v_candidate_end;
        is_available := NOT v_occupied;
        RETURN NEXT;

        v_curr := v_curr + make_interval(mins => v_step_interval);
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 5. Server-Side Paginated CRM Client LTV Aggregation RPC
CREATE OR REPLACE FUNCTION public.get_business_crm_profiles(
    p_business_id UUID,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    client_id UUID,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    avatar_url TEXT,
    total_spend NUMERIC,
    total_visits BIGINT,
    no_show_count BIGINT,
    first_visit TIMESTAMPTZ,
    last_visit TIMESTAMPTZ,
    status_tag TEXT,
    medical_flags JSONB,
    internal_staff_notes JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH agg AS (
        SELECT
            b.client_id,
            SUM(CASE WHEN b.status IN ('completed', 'confirmed', 'checked_in', 'in_service') THEN b.total_price ELSE 0 END) AS spend,
            COUNT(*) FILTER (WHERE b.status IN ('completed', 'confirmed', 'checked_in', 'in_service')) AS visits,
            COUNT(*) FILTER (WHERE b.status IN ('rejected')) AS no_shows,
            MIN(b.start_time) AS first_v,
            MAX(b.start_time) AS last_v
        FROM public.bookings b
        WHERE b.business_id = p_business_id
        GROUP BY b.client_id
    )
    SELECT
        agg.client_id,
        COALESCE(p.full_name, 'Patient / Client') AS full_name,
        COALESCE(p.email, 'client@example.com') AS email,
        COALESCE(p.phone, '') AS phone,
        p.avatar_url,
        COALESCE(agg.spend, 0.00) AS total_spend,
        COALESCE(agg.visits, 0) AS total_visits,
        COALESCE(agg.no_shows, 0) AS no_show_count,
        agg.first_v AS first_visit,
        agg.last_v AS last_visit,
        COALESCE(
            d.status_tag_override,
            CASE
                WHEN COALESCE(agg.spend, 0) >= 350 OR COALESCE(agg.visits, 0) >= 3 THEN 'VIP'
                WHEN COALESCE(agg.visits, 0) >= 2 THEN 'Regular'
                WHEN agg.last_v IS NOT NULL AND (now() - agg.last_v) > INTERVAL '90 days' THEN 'Lapsed'
                ELSE 'New'
            END
        ) AS status_tag,
        COALESCE(d.medical_flags, '[]'::jsonb) AS medical_flags,
        COALESCE(d.internal_staff_notes, '[]'::jsonb) AS internal_staff_notes
    FROM agg
    LEFT JOIN public.profiles p ON p.id = agg.client_id
    LEFT JOIN public.client_crm_dossiers d
        ON d.business_id = p_business_id AND d.client_id = agg.client_id
    ORDER BY total_spend DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
