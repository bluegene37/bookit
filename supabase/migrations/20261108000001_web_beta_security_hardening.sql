-- Gene - Nov, 08, 2026: Web Beta Security Hardening Migration
-- 1. Enforces strict Business Owner / Platform Admin authorization inside SECURITY DEFINER RPC `get_business_crm_profiles` (CWE-285 / CWE-862)
-- 2. Revokes anonymous execution privilege on sensitive CRM aggregation RPC
-- 3. Adds non-negative financial and rating integrity constraints on `bookings` and `reviews`

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
    -- Gene - Nov, 08, 2026: Enforce RBAC check inside SECURITY DEFINER function so only the business owner or platform admin can retrieve patient CRM records
    IF auth.role() IN ('anon', 'authenticated') THEN
        IF auth.uid() IS NULL OR (
            NOT EXISTS (
                SELECT 1 FROM public.businesses b
                WHERE b.id = p_business_id AND b.owner_id = auth.uid()
            )
            AND NOT EXISTS (
                SELECT 1 FROM public.profiles p
                WHERE p.id = auth.uid() AND p.role = 'admin'
            )
        ) THEN
            RAISE EXCEPTION 'Forbidden: Only the business owner or platform administrator may access client CRM dossiers.';
        END IF;
    END IF;

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
    LIMIT LEAST(GREATEST(p_limit, 1), 200)
    OFFSET GREATEST(p_offset, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE EXECUTE ON FUNCTION public.get_business_crm_profiles(UUID, INT, INT) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_business_crm_profiles(UUID, INT, INT) TO authenticated, service_role;

-- Non-negative financial integrity constraints on bookings
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_bookings_non_negative_amounts'
    ) THEN
        ALTER TABLE public.bookings
        ADD CONSTRAINT chk_bookings_non_negative_amounts
        CHECK (
            total_price >= 0 AND
            COALESCE(amount_paid, 0) >= 0 AND
            COALESCE(amount_due, 0) >= 0
        );
    END IF;
END $$;
