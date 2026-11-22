-- Gene - Nov, 22, 2026: Database-Driven Setup & Production Hardening Migration
-- 1. Creates `public.platform_settings` table with RLS and seeds universal currencies, booking models, scheduling presets, payment channels, CRM thresholds/presets, standee presets, and branding
-- 2. Fixes constraints on `profiles.role`, `services.payment_policy`, `bookings.status`, `bookings.payment_status`, and `bookings.client_id` nullable for walk-ins
-- 3. Adds missing operational columns on `bookings` (`checked_in_at`, `in_service_at`, `qr_token`, `intake_responses`, `walkin_client_name`, `currency`)
-- 4. Fixes multi-tenant staff & walk-in RLS policies on `bookings` and `businesses`
-- 5. Adds secure `reschedule_client_booking` and `submit_manual_payment` RPCs
-- 6. Updates `get_available_slots` RPC to enforce `business_staff.schedule_override` and `min_notice_hours`
-- 7. Syncs all 7 categories and 11+ business templates with valid hex UUIDs (`b0000001-...`), universal `ui_config` labels, currency, and explicit `deposit_type`

-- =====================================================================
-- 1. PLATFORM SETTINGS TABLE (Database-Driven Global Configuration)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.platform_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read platform settings" ON public.platform_settings;
CREATE POLICY "Public read platform settings"
ON public.platform_settings FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Admins manage platform settings" ON public.platform_settings;
CREATE POLICY "Admins manage platform settings"
ON public.platform_settings FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

INSERT INTO public.platform_settings (key, value, description)
VALUES
    (
        'supported_currencies',
        '[
            {"code": "USD", "symbol": "$", "name": "US Dollar"},
            {"code": "PHP", "symbol": "₱", "name": "Philippine Peso"},
            {"code": "EUR", "symbol": "€", "name": "Euro"},
            {"code": "GBP", "symbol": "£", "name": "British Pound"},
            {"code": "SGD", "symbol": "S$", "name": "Singapore Dollar"},
            {"code": "AUD", "symbol": "A$", "name": "Australian Dollar"},
            {"code": "CAD", "symbol": "C$", "name": "Canadian Dollar"},
            {"code": "JPY", "symbol": "¥", "name": "Japanese Yen"}
        ]'::jsonb,
        'Supported ISO currencies and symbols available across business onboarding, catalogs, and checkout'
    ),
    (
        'booking_models',
        '[
            {
                "id": "slot_based",
                "title": "1. Time Slot Appointments",
                "short_label": "Time Slot Appointment",
                "description": "Clients choose a service, select a provider or resource, and book discrete time slots.",
                "icon": "calendar_today"
            },
            {
                "id": "date_range",
                "title": "2. Date Range Booking (Stays & Rentals)",
                "short_label": "Date Range Booking",
                "description": "Clients pick arrival and departure dates with automatic multi-day or nightly rate calculation.",
                "icon": "date_range"
            },
            {
                "id": "daily",
                "title": "3. Daily Session (Day Pass & Capacity)",
                "short_label": "Daily Session",
                "description": "Clients reserve full-day sessions or day passes on available open dates.",
                "icon": "view_day"
            }
        ]'::jsonb,
        'Universal booking model catalog with industry-neutral labels and descriptions'
    ),
    (
        'scheduling_presets',
        '{
            "slot_intervals": [15, 30, 45, 60],
            "buffer_options": [0, 5, 10, 15, 30],
            "open_times": ["06:00", "07:00", "08:00", "08:30", "09:00", "09:30", "10:00", "11:00", "12:00"],
            "close_times": ["14:00", "15:00", "16:00", "17:00", "17:30", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"],
            "default_advance_booking_days": 14,
            "default_min_notice_hours": 0
        }'::jsonb,
        'Configurable scheduling dropdown presets for admin business setup and slot generation'
    ),
    (
        'payment_channels',
        '[
            {
                "id": "stripe_card",
                "label": "Card (Stripe)",
                "channel_title": "Credit / Debit Card (Stripe)",
                "subtitle": "Online card checkout via Stripe Express",
                "requires_reference": false
            },
            {
                "id": "gcash",
                "label": "GCash",
                "channel_title": "GCash Express / QR Ph",
                "subtitle": "Clients scan QR or transfer to your GCash number and input their 13-digit Reference No.",
                "requires_reference": true,
                "reference_label": "13-Digit GCash Reference No.",
                "reference_hint": "e.g. 9018472615243",
                "sender_label": "Your GCash Name / Mobile No.",
                "sender_hint": "e.g. Alex Reyes (0917-XXX-XXXX)"
            },
            {
                "id": "maya",
                "label": "Maya",
                "channel_title": "Maya Digital Wallet",
                "subtitle": "Direct transfer via Maya mobile number or QR Ph",
                "requires_reference": true,
                "reference_label": "Maya Reference ID",
                "reference_hint": "Enter transaction reference number",
                "sender_label": "Your Maya Name / Mobile No.",
                "sender_hint": "e.g. Alex Reyes (0918-XXX-XXXX)"
            },
            {
                "id": "bank_transfer",
                "label": "Bank Transfer",
                "channel_title": "Bank Transfer (InstaPay / PESONet)",
                "subtitle": "Clients transfer to your business bank account",
                "requires_reference": true,
                "reference_label": "Bank Transfer Reference No.",
                "reference_hint": "Enter transaction reference number",
                "sender_label": "Your Sending Bank & Account Name",
                "sender_hint": "e.g. BPI Savings / Alex Reyes"
            }
        ]'::jsonb,
        'Supported checkout channels and input metadata (merchant receiving accounts stored per business)'
    ),
    (
        'crm_config',
        '{
            "vip_spend_threshold": 350,
            "vip_visits_threshold": 3,
            "regular_visits_threshold": 2,
            "lapsed_days": 90,
            "flag_presets_by_category": {
                "healthcare": ["Penicillin Allergy", "Latex Sensitivity", "Blood Thinners", "High Anxiety", "Lidocaine Sensitivity", "Pregnancy / Nursing"],
                "wellness": ["Essential Oil Sensitivity", "Pregnancy / Prenatal", "Deep Pressure Contraindication", "Mobility Assistance", "Dietary Allergy"],
                "beauty": ["Sensitive Scalp / Skin", "Color / Bleach History", "Keratin / Chemical Treated", "Adhesive / Latex Sensitivity"],
                "fitness": ["Knee / Joint Limitation", "Lower Back Sensitivity", "Asthma / Cardio Note", "Post-Rehab Clearance"],
                "automotive": ["Matte Paint / Vinyl Wrap", "Ceramic Coated", "Oversize / Over 7ft", "Heavy Pet Hair"],
                "default": ["VIP Preference", "Accessibility Needs", "Special Preparation", "Repeat Scheduling Preference"]
            }
        }'::jsonb,
        'Dynamic CRM segmentation thresholds and industry-aware dossier alert flag presets'
    ),
    (
        'standee_presets',
        '{
            "public_base_url": "https://bookit.app",
            "headlines": [
                "Scan to Book in 30 Seconds",
                "Walk-Ins Welcome — Check Today''s Openings",
                "Reserve Your Spot Now"
            ]
        }'::jsonb,
        'Public booking link base URL and headline presets for QR Standee Studio'
    ),
    (
        'branding',
        '{
            "app_name": "BookIt",
            "discovery_subtitle": "Discover businesses, specialists & services",
            "search_placeholder": "Search businesses, services, or specialists...",
            "default_latitude": 37.7749,
            "default_longitude": -122.4194
        }'::jsonb,
        'Universal marketplace branding strings and default map coordinates'
    )
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = now();

-- =====================================================================
-- 2. FIX SCHEMA CONSTRAINTS & MISSING BOOKINGS COLUMNS
-- =====================================================================
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles
    ADD CONSTRAINT profiles_role_check
    CHECK (role IN ('client', 'staff', 'business_owner', 'admin'));

ALTER TABLE public.services DROP CONSTRAINT IF EXISTS services_payment_policy_check;
ALTER TABLE public.services
    ADD CONSTRAINT services_payment_policy_check
    CHECK (payment_policy IN ('full_upfront', 'deposit', 'deposit_required', 'pay_at_venue', 'free_consultation'));

-- Gene - Nov, 22, 2026: Ensure payment metadata columns exist on bookings and payments tables
-- ALTER TABLE public.bookings
--     ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMPTZ,
--     ADD COLUMN IF NOT EXISTS in_service_at TIMESTAMPTZ,
--     ADD COLUMN IF NOT EXISTS qr_token TEXT,
--     ADD COLUMN IF NOT EXISTS intake_responses JSONB NOT NULL DEFAULT '{}'::jsonb,
--     ADD COLUMN IF NOT EXISTS walkin_client_name TEXT,
--     ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';
ALTER TABLE public.bookings
    ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS in_service_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS qr_token TEXT,
    ADD COLUMN IF NOT EXISTS intake_responses JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS walkin_client_name TEXT,
    ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD',
    ADD COLUMN IF NOT EXISTS payment_method TEXT,
    ADD COLUMN IF NOT EXISTS payment_reference TEXT,
    ADD COLUMN IF NOT EXISTS payment_sender TEXT;

ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS payment_method TEXT,
    ADD COLUMN IF NOT EXISTS reference_number TEXT,
    ADD COLUMN IF NOT EXISTS sender_account TEXT;

-- Allow NULL client_id for walk-in bookings when walkin_client_name is provided
ALTER TABLE public.bookings ALTER COLUMN client_id DROP NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_bookings_client_or_walkin'
    ) THEN
        ALTER TABLE public.bookings
        ADD CONSTRAINT chk_bookings_client_or_walkin
        CHECK (client_id IS NOT NULL OR (walkin_client_name IS NOT NULL AND length(trim(walkin_client_name)) > 0));
    END IF;
END $$;

ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_status_check;
ALTER TABLE public.bookings
    ADD CONSTRAINT bookings_status_check
    CHECK (status IN (
        'awaiting_payment',
        'pending',
        'confirmed',
        'checked_in',
        'in_service',
        'completed',
        'cancelled',
        'rejected',
        'no_show'
    ));

ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_payment_status_check;
ALTER TABLE public.bookings
    ADD CONSTRAINT bookings_payment_status_check
    CHECK (payment_status IN (
        'unpaid',
        'pending_verification',
        'deposit_paid',
        'paid_in_full',
        'refunded',
        'partially_refunded'
    ));

-- Make handle_booking_status_notification safe when client_id is NULL (walk-ins without user account)
CREATE OR REPLACE FUNCTION public.handle_booking_status_notification()
RETURNS TRIGGER AS $$
DECLARE
    b_name TEXT;
BEGIN
    IF NEW.client_id IS NULL THEN
        RETURN NEW;
    END IF;

    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status)) THEN
        SELECT name INTO b_name FROM public.businesses WHERE id = NEW.business_id;
        b_name := COALESCE(b_name, 'BookIt Business');

        INSERT INTO public.notifications (user_id, business_id, booking_id, title, body, type)
        VALUES (
            NEW.client_id,
            NEW.business_id,
            NEW.id,
            CASE 
                WHEN NEW.status = 'confirmed' THEN 'Booking Confirmed!'
                WHEN NEW.status = 'checked_in' THEN 'Checked In at Reception'
                WHEN NEW.status = 'in_service' THEN 'Your Session is Starting'
                WHEN NEW.status = 'cancelled' THEN 'Booking Cancelled'
                WHEN NEW.status = 'completed' THEN 'Booking Completed'
                WHEN NEW.status = 'rejected' THEN 'Booking Request Declined'
                WHEN NEW.status = 'no_show' THEN 'Marked as No-Show'
                ELSE 'Booking Request Received'
            END,
            CASE
                WHEN NEW.status = 'confirmed' THEN 'Your booking with ' || b_name || ' has been confirmed.'
                WHEN NEW.status = 'checked_in' THEN 'You are checked in at ' || b_name || '.'
                WHEN NEW.status = 'in_service' THEN 'Your provider at ' || b_name || ' is ready for you now.'
                WHEN NEW.status = 'cancelled' THEN 'Your booking with ' || b_name || ' was cancelled.'
                WHEN NEW.status = 'completed' THEN 'Thank you for visiting ' || b_name || '. Please leave a review!'
                WHEN NEW.status = 'rejected' THEN 'Unfortunately, ' || b_name || ' could not accommodate this booking.'
                WHEN NEW.status = 'no_show' THEN 'Your booking at ' || b_name || ' was marked as a no-show.'
                ELSE 'Your booking with ' || b_name || ' is pending confirmation.'
            END,
            'booking_' || NEW.status
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- =====================================================================
-- 3. MULTI-TENANT STAFF & WALK-IN RLS POLICIES
-- =====================================================================
DROP POLICY IF EXISTS "Active businesses are publicly viewable" ON public.businesses;
DROP POLICY IF EXISTS "Public read active businesses" ON public.businesses;
CREATE POLICY "Public read active businesses"
ON public.businesses FOR SELECT
USING (
    is_active = true
    OR auth.uid() = owner_id
    OR EXISTS (
        SELECT 1 FROM public.business_staff bs
        WHERE bs.business_id = id AND bs.user_id = auth.uid() AND bs.is_active = true
    )
);

DROP POLICY IF EXISTS "Business owners and staff can create walk-in bookings" ON public.bookings;
CREATE POLICY "Business owners and staff can create walk-in bookings"
ON public.bookings FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.business_staff bs
        WHERE bs.business_id = business_id AND bs.user_id = auth.uid() AND bs.is_active = true
    )
);

DROP POLICY IF EXISTS "Assigned staff can view business bookings" ON public.bookings;
CREATE POLICY "Assigned staff can view business bookings"
ON public.bookings FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.business_staff bs
        WHERE bs.business_id = business_id AND bs.user_id = auth.uid() AND bs.is_active = true
    )
);

DROP POLICY IF EXISTS "Assigned staff can update operational booking status" ON public.bookings;
CREATE POLICY "Assigned staff can update operational booking status"
ON public.bookings FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.business_staff bs
        WHERE bs.business_id = business_id AND bs.user_id = auth.uid() AND bs.is_active = true
    )
);

-- =====================================================================
-- 4. SECURE RPCs FOR CLIENT RESCHEDULE & HYBRID MANUAL PAYMENT
-- =====================================================================
CREATE OR REPLACE FUNCTION public.reschedule_client_booking(
    p_booking_id UUID,
    p_new_start_time TIMESTAMPTZ DEFAULT NULL,
    p_new_end_time TIMESTAMPTZ DEFAULT NULL,
    p_new_date_from DATE DEFAULT NULL,
    p_new_date_to DATE DEFAULT NULL
)
RETURNS public.bookings AS $$
DECLARE
    v_booking public.bookings;
    v_business_name TEXT;
    v_conflict_exists BOOLEAN := false;
BEGIN
    SELECT * INTO v_booking
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found.';
    END IF;

    IF auth.role() IN ('anon', 'authenticated') THEN
        IF auth.uid() IS NULL OR (
            v_booking.client_id IS DISTINCT FROM auth.uid()
            AND NOT EXISTS (
                SELECT 1 FROM public.businesses b
                WHERE b.id = v_booking.business_id AND b.owner_id = auth.uid()
            )
            AND NOT EXISTS (
                SELECT 1 FROM public.business_staff bs
                WHERE bs.business_id = v_booking.business_id AND bs.user_id = auth.uid() AND bs.is_active = true
            )
            AND NOT EXISTS (
                SELECT 1 FROM public.profiles p
                WHERE p.id = auth.uid() AND p.role = 'admin'
            )
        ) THEN
            RAISE EXCEPTION 'Forbidden: You do not have permission to reschedule this booking.';
        END IF;
    END IF;

    IF v_booking.status IN ('cancelled', 'rejected', 'completed', 'in_service', 'no_show') THEN
        RAISE EXCEPTION 'Bookings with status "%" cannot be rescheduled.', v_booking.status;
    END IF;

    IF v_booking.booking_model = 'slot_based' THEN
        IF p_new_start_time IS NULL OR p_new_end_time IS NULL OR p_new_end_time <= p_new_start_time THEN
            RAISE EXCEPTION 'Valid new start_time and end_time are required for slot-based rescheduling.';
        END IF;

        IF v_booking.staff_id IS NOT NULL THEN
            SELECT EXISTS (
                SELECT 1
                FROM public.bookings other
                WHERE other.id <> p_booking_id
                  AND other.business_id = v_booking.business_id
                  AND other.staff_id = v_booking.staff_id
                  AND other.start_time IS NOT NULL
                  AND other.end_time IS NOT NULL
                  AND other.status NOT IN ('cancelled', 'rejected', 'no_show')
                  AND (other.status <> 'awaiting_payment' OR (other.hold_expires_at IS NOT NULL AND other.hold_expires_at > now()))
                  AND tstzrange(other.start_time, other.end_time) && tstzrange(p_new_start_time, p_new_end_time)
            ) INTO v_conflict_exists;

            IF v_conflict_exists THEN
                RAISE EXCEPTION 'Selected time slot is no longer available.';
            END IF;
        END IF;

        UPDATE public.bookings
        SET start_time = p_new_start_time,
            end_time = p_new_end_time,
            reminder_24h_sent = NULL,
            reminder_2h_sent = NULL,
            updated_at = now()
        WHERE id = p_booking_id
        RETURNING * INTO v_booking;
    ELSE
        IF p_new_date_from IS NULL THEN
            RAISE EXCEPTION 'A valid new date_from is required for rescheduling.';
        END IF;

        UPDATE public.bookings
        SET date_from = p_new_date_from,
            date_to = COALESCE(p_new_date_to, v_booking.date_to),
            updated_at = now()
        WHERE id = p_booking_id
        RETURNING * INTO v_booking;
    END IF;

    IF v_booking.client_id IS NOT NULL THEN
        SELECT name INTO v_business_name FROM public.businesses WHERE id = v_booking.business_id;
        INSERT INTO public.notifications (user_id, business_id, booking_id, title, body, type)
        VALUES (
            v_booking.client_id,
            v_booking.business_id,
            v_booking.id,
            'Booking Rescheduled',
            'Your booking at ' || COALESCE(v_business_name, 'BookIt Business') || ' has been rescheduled.',
            'booking_rescheduled'
        );
    END IF;

    RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE EXECUTE ON FUNCTION public.reschedule_client_booking(UUID, TIMESTAMPTZ, TIMESTAMPTZ, DATE, DATE) FROM anon;
GRANT EXECUTE ON FUNCTION public.reschedule_client_booking(UUID, TIMESTAMPTZ, TIMESTAMPTZ, DATE, DATE) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.submit_manual_payment(
    p_booking_id UUID,
    p_payment_method TEXT,
    p_reference_number TEXT,
    p_sender_account TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_booking public.bookings;
    v_business public.businesses;
    v_service public.services;
    v_total NUMERIC(10,2);
    v_charge_amount NUMERIC(10,2);
    v_remaining_due NUMERIC(10,2);
    v_payment_status TEXT;
    v_app_fee NUMERIC(10,2);
    v_currency TEXT;
    v_ref TEXT;
    v_payment_id UUID;
BEGIN
    IF p_payment_method NOT IN ('gcash', 'maya', 'bank_transfer') THEN
        RAISE EXCEPTION 'Unsupported manual payment method: %', p_payment_method;
    END IF;

    v_ref := trim(COALESCE(p_reference_number, ''));
    IF v_ref = '' THEN
        RAISE EXCEPTION 'Transaction reference number is required.';
    END IF;

    SELECT * INTO v_booking
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found.';
    END IF;

    -- Gene - Nov, 22, 2026: Prevent payment submission on cancelled/rejected or already-settled bookings
    IF v_booking.status IN ('cancelled', 'rejected') THEN
        RAISE EXCEPTION 'Cancelled or rejected bookings cannot accept payments.';
    END IF;

    IF v_booking.payment_status IN ('paid_in_full', 'deposit_paid') THEN
        RAISE EXCEPTION 'Payment has already been recorded for this booking.';
    END IF;

    SELECT * INTO v_business FROM public.businesses WHERE id = v_booking.business_id;

    IF auth.role() IN ('anon', 'authenticated') THEN
        IF auth.uid() IS NULL OR (
            v_booking.client_id IS DISTINCT FROM auth.uid()
            AND v_business.owner_id IS DISTINCT FROM auth.uid()
            AND NOT EXISTS (
                SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'
            )
        ) THEN
            RAISE EXCEPTION 'Forbidden: You are not authorized to submit payment for this booking.';
        END IF;
    END IF;

    IF v_booking.service_id IS NOT NULL THEN
        SELECT * INTO v_service FROM public.services WHERE id = v_booking.service_id;
    END IF;

    v_total := GREATEST(COALESCE(v_booking.total_price, v_service.price, 0.00), 0.00);
    v_currency := lower(COALESCE(v_service.currency, v_booking.currency, v_business.settings->>'currency', 'usd'));

    IF v_service.id IS NOT NULL AND v_service.payment_policy IN ('deposit', 'deposit_required') THEN
        IF v_service.deposit_type = 'percentage' THEN
            v_charge_amount := ROUND((v_total * (v_service.deposit_amount / 100.0))::numeric, 2);
        ELSE
            v_charge_amount := LEAST(v_service.deposit_amount, v_total);
        END IF;
    ELSIF v_service.id IS NOT NULL AND v_service.payment_policy IN ('pay_at_venue', 'free_consultation') THEN
        v_charge_amount := 0.00;
    ELSE
        v_charge_amount := v_total;
    END IF;

    v_remaining_due := GREATEST(ROUND((v_total - v_charge_amount)::numeric, 2), 0.00);
    v_payment_status := CASE
        WHEN v_charge_amount <= 0 THEN 'unpaid'
        WHEN v_remaining_due <= 0 THEN 'paid_in_full'
        ELSE 'deposit_paid'
    END;

    v_app_fee := ROUND(((v_charge_amount * (COALESCE(v_business.platform_fee_percent, 2.50) / 100.0)) + COALESCE(v_business.platform_fee_fixed, 0.30))::numeric, 2);

    UPDATE public.bookings
    SET status = CASE WHEN COALESCE(v_business.settings->>'requires_approval', 'false')::boolean THEN 'pending' ELSE 'confirmed' END,
        payment_status = v_payment_status,
        amount_paid = v_charge_amount,
        amount_due = v_remaining_due,
        hold_expires_at = NULL,
        payment_method = p_payment_method,
        payment_reference = v_ref,
        payment_sender = NULLIF(trim(COALESCE(p_sender_account, '')), ''),
        updated_at = now()
    WHERE id = p_booking_id
    RETURNING * INTO v_booking;

    INSERT INTO public.payments (
        booking_id,
        business_id,
        client_id,
        stripe_payment_intent_id,
        gross_amount,
        application_fee_amount,
        stripe_fee_amount,
        net_amount,
        currency,
        payment_status,
        payment_method,
        reference_number,
        sender_account
    )
    -- Gene - Nov, 22, 2026: Keep stripe_payment_intent_id NULL for manual transfers to avoid UNIQUE collisions
    VALUES (
        p_booking_id,
        v_booking.business_id,
        COALESCE(v_booking.client_id, v_business.owner_id),
        -- v_ref,
        NULL,
        v_charge_amount,
        v_app_fee,
        0.00,
        v_charge_amount,
        v_currency,
        'succeeded',
        p_payment_method,
        v_ref,
        NULLIF(trim(COALESCE(p_sender_account, '')), '')
    )
    RETURNING id INTO v_payment_id;

    IF v_booking.client_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, business_id, booking_id, title, body, type)
        VALUES (
            v_booking.client_id,
            v_booking.business_id,
            v_booking.id,
            'Payment Recorded',
            'Your ' || upper(p_payment_method) || ' payment (' || upper(v_currency) || ' ' || v_charge_amount::text || ', Ref: ' || v_ref || ') has been recorded.',
            'payment_success'
        );
    END IF;

    IF v_business.owner_id IS NOT NULL AND v_business.owner_id IS DISTINCT FROM v_booking.client_id THEN
        INSERT INTO public.notifications (user_id, business_id, booking_id, title, body, type)
        VALUES (
            v_business.owner_id,
            v_booking.business_id,
            v_booking.id,
            'New Payment Received',
            'Direct transfer payment (' || upper(p_payment_method) || ' ' || upper(v_currency) || ' ' || v_charge_amount::text || ', Ref: ' || v_ref || ') submitted.',
            'payment_received'
        );
    END IF;

    RETURN jsonb_build_object(
        'payment_id', v_payment_id,
        'booking_id', v_booking.id,
        'status', v_booking.status,
        'payment_status', v_booking.payment_status,
        'amount_paid', v_booking.amount_paid,
        'amount_due', v_booking.amount_due,
        'currency', v_currency,
        'reference_number', v_ref
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE EXECUTE ON FUNCTION public.submit_manual_payment(UUID, TEXT, TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.submit_manual_payment(UUID, TEXT, TEXT, TEXT) TO authenticated, service_role;

-- =====================================================================
-- 5. UPGRADE get_available_slots RPC (Staff Shift Overrides & Notice Window)
-- =====================================================================
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
    v_staff_override JSONB;
    v_weekday TEXT;
    v_day_cfg JSONB;
    v_staff_day_cfg JSONB;
    v_is_open BOOLEAN;
    v_open_str TEXT;
    v_close_str TEXT;
    v_break_start_str TEXT;
    v_break_end_str TEXT;
    v_has_break BOOLEAN := false;
    v_step_interval INT;
    v_slot_duration INT;
    v_buffer_minutes INT;
    v_min_notice_hours INT;
    v_day_start TIMESTAMPTZ;
    v_day_end TIMESTAMPTZ;
    v_break_start TIMESTAMPTZ;
    v_break_end TIMESTAMPTZ;
    v_curr TIMESTAMPTZ;
    v_candidate_end TIMESTAMPTZ;
    v_occupied BOOLEAN;
    v_in_break BOOLEAN;
    v_min_notice_cutoff TIMESTAMPTZ;
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
    v_min_notice_hours := GREATEST(COALESCE((v_settings->>'min_notice_hours')::int, 0), 0);
    v_min_notice_cutoff := now() + make_interval(hours => v_min_notice_hours);

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

    IF p_staff_id IS NOT NULL THEN
        SELECT bs.schedule_override INTO v_staff_override
        FROM public.business_staff bs
        WHERE bs.id = p_staff_id AND bs.business_id = p_business_id;

        IF v_staff_override IS NOT NULL AND (v_staff_override ? v_weekday) THEN
            v_staff_day_cfg := v_staff_override->v_weekday;
            IF COALESCE((v_staff_day_cfg->>'is_working')::boolean, true) = false THEN
                RETURN;
            END IF;
            v_open_str := COALESCE(v_staff_day_cfg->>'start', v_open_str);
            v_close_str := COALESCE(v_staff_day_cfg->>'end', v_close_str);
            IF (v_staff_day_cfg ? 'break_start') AND (v_staff_day_cfg ? 'break_end')
               AND NULLIF(v_staff_day_cfg->>'break_start', '') IS NOT NULL
               AND NULLIF(v_staff_day_cfg->>'break_end', '') IS NOT NULL THEN
                v_has_break := true;
                v_break_start_str := v_staff_day_cfg->>'break_start';
                v_break_end_str := v_staff_day_cfg->>'break_end';
            END IF;
        END IF;
    END IF;

    v_day_start := (p_date::text || ' ' || v_open_str || ':00+00')::timestamptz;
    v_day_end := (p_date::text || ' ' || v_close_str || ':00+00')::timestamptz;
    IF v_has_break THEN
        v_break_start := (p_date::text || ' ' || v_break_start_str || ':00+00')::timestamptz;
        v_break_end := (p_date::text || ' ' || v_break_end_str || ':00+00')::timestamptz;
    END IF;

    v_curr := v_day_start;
    WHILE v_curr + make_interval(mins => v_slot_duration) <= v_day_end LOOP
        v_candidate_end := v_curr + make_interval(mins => v_slot_duration);

        v_in_break := v_has_break AND v_curr < v_break_end AND v_candidate_end > v_break_start;

        SELECT EXISTS (
            SELECT 1
            FROM public.bookings bk
            WHERE bk.business_id = p_business_id
              AND bk.start_time IS NOT NULL
              AND bk.end_time IS NOT NULL
              AND (p_staff_id IS NULL OR bk.staff_id IS NULL OR bk.staff_id = p_staff_id)
              AND bk.status NOT IN ('cancelled', 'rejected', 'no_show')
              AND (
                  bk.status != 'awaiting_payment'
                  OR (bk.hold_expires_at IS NOT NULL AND bk.hold_expires_at > now())
              )
              AND v_curr < (bk.end_time + make_interval(mins => v_buffer_minutes))
              AND (v_candidate_end + make_interval(mins => v_buffer_minutes)) > bk.start_time
        ) INTO v_occupied;

        slot_start := v_curr;
        slot_end := v_candidate_end;
        is_available := (NOT v_occupied) AND (NOT v_in_break) AND (v_curr >= v_min_notice_cutoff);
        RETURN NEXT;

        v_curr := v_curr + make_interval(mins => v_step_interval);
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- =====================================================================
-- 6. SYNC ALL 7 CATEGORIES & 11 BUSINESS TEMPLATES (Valid Hex UUIDs + Universal ui_config)
-- =====================================================================
INSERT INTO public.business_categories (id, name, slug, description, icon, display_order, is_active)
VALUES
    ('c0000001-0000-0000-0000-000000000001', 'Healthcare & Clinics', 'healthcare-clinics', 'Dental practices, medical specialists, physical therapy, and clinical care.', 'medical_services_rounded', 1, true),
    ('c0000002-0000-0000-0000-000000000002', 'Wellness & Therapy', 'wellness-therapy', 'Mental health counseling, specialized post-op recovery retreats, and nutrition.', 'spa_rounded', 2, true),
    ('c0000003-0000-0000-0000-000000000003', 'Beauty & Personal Care', 'beauty-personal-care', 'Hair salons, barbershops, esthetics, medical spas, and nail care.', 'content_cut_rounded', 3, true),
    ('c0000004-0000-0000-0000-000000000004', 'Fitness & Coaching', 'fitness-coaching', '1-on-1 personal training, Pilates/yoga instruction, and specialized private coaching.', 'fitness_center_rounded', 4, true),
    ('c0000005-0000-0000-0000-000000000005', 'Professional Consulting', 'professional-consulting', 'Legal counsel, certified tax/accounting, financial advising, and architecture review.', 'gavel_rounded', 5, true),
    ('c0000006-0000-0000-0000-000000000006', 'Studios & Space Rentals', 'studios-space-rentals', 'Photography cycloramas, podcast/audio booths, and private production suites.', 'meeting_room_rounded', 6, true),
    ('c0000007-0000-0000-0000-000000000007', 'Automotive & Detailing', 'automotive-detailing', 'Car wash, ceramic coatings, interior steam sanitization, and mobile detailing fleets.', 'local_car_wash_rounded', 7, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    slug = EXCLUDED.slug,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    display_order = EXCLUDED.display_order,
    is_active = EXCLUDED.is_active;

-- Remove any legacy invalid non-hex IDs if present
DELETE FROM public.business_templates WHERE slug IN ('dental-clinic', 'medical-dermatology', 'recovery-suites') AND id::text LIKE 't0000001%';

INSERT INTO public.business_templates (
    id, category_id, name, slug, description, icon, booking_model,
    default_settings, ui_config, starter_services, starter_staff_roles, display_order, is_active
)
VALUES
(
    'b0000001-0000-0000-0000-000000000001',
    'c0000001-0000-0000-0000-000000000001',
    'Dental Care Clinic',
    'dental-clinic',
    'Perfect for general dentists, orthodontists, periodontists, and oral surgeons.',
    'medical_information_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":30,"buffer_minutes":10,"requires_approval":false,"advance_booking_days":30,"min_notice_hours":2,"working_hours":{"monday":{"open":"09:00","close":"18:00","is_open":true},"tuesday":{"open":"09:00","close":"18:00","is_open":true},"wednesday":{"open":"09:00","close":"18:00","is_open":true},"thursday":{"open":"09:00","close":"18:00","is_open":true},"friday":{"open":"09:00","close":"17:00","is_open":true},"saturday":{"open":"10:00","close":"15:00","is_open":true},"sunday":{"open":"00:00","close":"00:00","is_open":false}}}'::jsonb,
    '{"resource_type":"person","resource_label":"Dentist / Specialist","service_label":"Dental Treatment","client_label":"Patient","venue_label":"Clinic","booking_label":"Appointment","crm_flag_label":"Medical & Clinical Flags","crm_flag_presets":["Penicillin Allergy","Latex Sensitivity","Blood Thinners","High Dental Anxiety","Lidocaine Sensitivity","Pregnancy / Nursing"],"show_staff_selection":true,"intake_fields":[{"id":"dental_insurance","label":"Do you have dental insurance?","type":"boolean","required":false},{"id":"insurance_carrier","label":"Insurance Provider / Member ID","type":"text","placeholder":"e.g. Delta Dental / Cigna","required":false},{"id":"anesthesia_allergies","label":"Allergies to local anesthesia, latex, or antibiotics?","type":"text","placeholder":"None or specify","required":false},{"id":"chief_complaint","label":"Primary reason for visit / symptoms","type":"textarea","placeholder":"Checkup, tooth sensitivity, toothache...","required":true}]}'::jsonb,
    '[{"name":"Comprehensive Exam & Digital X-Ray","description":"Full mouth exam, digital radiography, and preventive gum scoring.","duration_minutes":45,"price":120.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":30.00},{"name":"Preventive Teeth Cleaning (Prophylaxis)","description":"Ultrasonic scaling, stain removal, and fluoride polish.","duration_minutes":45,"price":95.00,"payment_policy":"pay_at_venue"},{"name":"In-Office Teeth Whitening","description":"Professional 60-minute accelerated light-activated whitening treatment.","duration_minutes":60,"price":350.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":50.00},{"name":"Orthodontic & Invisalign Consultation","description":"3D intraoral digital scan and smile simulation.","duration_minutes":30,"price":50.00,"payment_policy":"full_upfront"}]'::jsonb,
    '["General Dentist","Lead Orthodontist","Dental Hygienist","Oral Surgeon"]'::jsonb,
    1,
    true
),
(
    'b0000001-0000-0000-0000-000000000002',
    'c0000001-0000-0000-0000-000000000001',
    'Aesthetic & Dermatology Clinic',
    'aesthetic-dermatology',
    'Medical aesthetics, laser dermatology, Botox/fillers, Morpheus8 RF, and clinical peels.',
    'health_and_safety_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":15,"buffer_minutes":15,"numbing_buffer_minutes":20,"requires_approval":true,"deposit_percent":30.0,"cancellation_window_hours":48,"advance_booking_days":60,"min_notice_hours":6,"working_hours":{"monday":{"open":"09:00","close":"18:00","is_open":true},"tuesday":{"open":"09:00","close":"18:00","is_open":true},"wednesday":{"open":"09:00","close":"18:00","is_open":true},"thursday":{"open":"09:00","close":"18:00","is_open":true},"friday":{"open":"09:00","close":"18:00","is_open":true},"saturday":{"open":"10:00","close":"16:00","is_open":true},"sunday":{"open":"00:00","close":"00:00","is_open":false}}}'::jsonb,
    '{"resource_type":"person_and_room_and_device","resource_label":"Medical Practitioner","service_label":"Aesthetic Treatment","client_label":"Patient","venue_label":"Clinic","booking_label":"Treatment","crm_flag_label":"Clinical Alerts & Contraindications","crm_flag_presets":["Accutane History","Lidocaine Sensitivity","Blood Thinners","HSV-1 Cold Sore Prophylaxis","Pregnancy / Nursing"],"show_staff_selection":true,"intake_fields":[{"id":"fitzpatrick_scale","label":"Fitzpatrick Skin Type","type":"select","required":true,"options":["Type I - Always burns, never tans","Type II - Usually burns, tans with difficulty","Type III - Sometimes mild burn, gradually tans","Type IV - Rarely burns, tans with ease","Type V - Very rarely burns, tans very easily","Type VI - Never burns, deeply pigmented"]},{"id":"accutane_history","label":"Used oral Isotretinoin (Accutane) within the past 6 months?","type":"boolean","required":true,"blocking_condition":true,"blocking_message":"Laser, RF microneedling, and chemical peels cannot be administered within 6 months of Accutane therapy due to scarring risks."},{"id":"blood_thinners_nsaids","label":"Currently taking blood thinners, Aspirin, Ibuprofen, or high-dose Fish Oil?","type":"boolean","required":true,"helper_text":"May increase injection-site bruising."},{"id":"pregnancy_lactation","label":"Currently pregnant, planning pregnancy, or breastfeeding?","type":"boolean","required":true,"blocking_condition":true,"blocking_message":"Cosmetic injectables and laser treatments are contraindicated during pregnancy and breastfeeding."},{"id":"hsv_cold_sores","label":"History of oral facial cold sores (HSV-1)?","type":"boolean","required":false,"helper_text":"If having lip filler or perioral laser, prophylactic antiviral medication is recommended."},{"id":"clinical_photo_consent","label":"I consent to pre- and post-treatment photographic documentation for my clinical record","type":"boolean","required":true}]}'::jsonb,
    '[{"name":"Botox / Dysport Wrinkle Relaxer","description":"Precision neuromodulator injections for forehead lines, crow''s feet, and frown lines.","duration_minutes":30,"price":320.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":96.00},{"name":"Juvederm / Restylane Dermal Filler","description":"Hyaluronic acid contouring for midface volume, cheekbones, and jawline definition.","duration_minutes":45,"price":650.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":195.00},{"name":"Morpheus8 RF Microneedling (Face & Neck)","description":"Fractional radiofrequency subdermal adipose remodeling for skin tightening.","duration_minutes":75,"price":950.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":285.00},{"name":"Deluxe Medical Hydrafacial with Booster","description":"Vortex-fusion deep pore cleansing, exfoliation, painless extraction, and antioxidant infusion.","duration_minutes":60,"price":275.00,"payment_policy":"pay_at_venue"}]'::jsonb,
    '["Board-Certified Dermatologist","Lead Aesthetic Nurse Injector","Senior Certified Laser Specialist"]'::jsonb,
    2,
    true
),
(
    'b0000001-0000-0000-0000-000000000003',
    'c0000002-0000-0000-0000-000000000002',
    'Post-Op Recovery & Wellness Suites',
    'recovery-suites',
    'Specialized multi-day post-operative clinical suites with nursing supervision and rehabilitation support.',
    'hotel_rounded',
    'date_range',
    '{"currency":"USD","checkin_time":"14:00","checkout_time":"11:00","min_days":2,"max_days":30,"requires_approval":true}'::jsonb,
    '{"resource_type":"facility","resource_label":"Care Suite / Room","service_label":"Recovery Tier","client_label":"Guest","venue_label":"Retreat","booking_label":"Reservation","crm_flag_label":"Care & Dietary Notes","crm_flag_presets":["Mobility Assistance","Post-Op Care Protocol","Dietary Allergy","Low-Sodium Meal Plan"],"show_staff_selection":false,"intake_fields":[{"id":"surgery_type","label":"Surgical procedure type & hospital","type":"text","placeholder":"e.g. Orthopedic knee replacement at UCSF","required":true},{"id":"surgery_date","label":"Surgery discharge date","type":"text","placeholder":"MM/DD/YYYY","required":true},{"id":"mobility_level","label":"Assistance needed (Wheelchair, Walker, Bedbound)","type":"text","placeholder":"Describe mobility needs","required":true},{"id":"dietary_restrictions","label":"Nutritional restrictions / allergies","type":"text","placeholder":"e.g. Low sodium, Diabetic, Gluten-free","required":false}]}'::jsonb,
    '[{"name":"Private Clinical Recovery Suite (Per Night)","description":"Private suite with 24/7 dedicated RN monitoring, physical therapy access, and chef-curated meals.","duration_minutes":1440,"price":450.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":100.00},{"name":"Executive Care Suite & Companion Bed (Per Night)","description":"Expanded double suite accommodating guest and accompanying family member.","duration_minutes":1440,"price":650.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":150.00}]'::jsonb,
    '["Lead Registered Nurse (RN)","Physical Therapist","Nutritional Coordinator"]'::jsonb,
    3,
    true
),
(
    'b0000001-0000-0000-0000-000000000004',
    'c0000002-0000-0000-0000-000000000002',
    'Mental Health & Therapy Practice',
    'mental-health-therapy',
    'Designed for licensed psychologists, counselors, psychotherapists, and family therapists.',
    'psychology_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":50,"buffer_minutes":10,"requires_approval":false,"advance_booking_days":30,"min_notice_hours":4,"working_hours":{"monday":{"open":"09:00","close":"19:00","is_open":true},"tuesday":{"open":"09:00","close":"19:00","is_open":true},"wednesday":{"open":"09:00","close":"19:00","is_open":true},"thursday":{"open":"09:00","close":"19:00","is_open":true},"friday":{"open":"09:00","close":"17:00","is_open":true},"saturday":{"open":"10:00","close":"14:00","is_open":true},"sunday":{"open":"00:00","close":"00:00","is_open":false}}}'::jsonb,
    '{"resource_type":"person","resource_label":"Therapist / Counselor","service_label":"Session Type","client_label":"Client","venue_label":"Practice","booking_label":"Session","crm_flag_label":"Session Preferences & Care Notes","crm_flag_presets":["Telehealth Preferred","Evening Slot Preference","Accessibility Needs","Couples Format"],"show_staff_selection":true,"intake_fields":[{"id":"preferred_format","label":"Session Format","type":"text","placeholder":"In-Person or Secure Video Call","required":true},{"id":"prior_therapy","label":"Have you worked with a counselor before?","type":"boolean","required":false},{"id":"primary_goals","label":"What are your primary goals for therapy?","type":"textarea","placeholder":"Anxiety management, life transition, relationship...","required":true}]}'::jsonb,
    '[{"name":"Individual Psychotherapy Session (50 min)","description":"Confidential one-on-one evidence-based therapy session.","duration_minutes":50,"price":160.00,"payment_policy":"full_upfront"},{"name":"Couples & Family Counseling (75 min)","description":"Systemic counseling focusing on communication and relationship dynamics.","duration_minutes":75,"price":230.00,"payment_policy":"full_upfront"},{"name":"Initial Consultation & Intake Assessment (60 min)","description":"Diagnostic evaluation and personalized treatment roadmap design.","duration_minutes":60,"price":190.00,"payment_policy":"full_upfront"}]'::jsonb,
    '["Licensed Clinical Psychologist (PsyD)","Licensed Marriage & Family Therapist (LMFT)","Clinical Social Worker (LCSW)"]'::jsonb,
    4,
    true
),
(
    'b0000001-0000-0000-0000-000000000005',
    'c0000003-0000-0000-0000-000000000003',
    'Hair & Beauty Salon',
    'hair-beauty-salon',
    'Lived-in balayage, precision cuts, Brazilian keratin smoothing, Russian volume lashes, and brow sculpt.',
    'content_cut_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":15,"buffer_minutes":10,"requires_approval":false,"deposit_percent":25.0,"cancellation_window_hours":48,"advance_booking_days":60,"min_notice_hours":4,"working_hours":{"monday":{"open":"00:00","close":"00:00","is_open":false},"tuesday":{"open":"09:00","close":"19:00","is_open":true},"wednesday":{"open":"09:00","close":"19:00","is_open":true},"thursday":{"open":"09:00","close":"20:00","is_open":true},"friday":{"open":"09:00","close":"20:00","is_open":true},"saturday":{"open":"09:00","close":"18:00","is_open":true},"sunday":{"open":"10:00","close":"17:00","is_open":true}}}'::jsonb,
    '{"resource_type":"stylist_chair_and_wash_basin","resource_label":"Master Stylist / Colorist","service_label":"Salon Service","client_label":"Guest","venue_label":"Salon","booking_label":"Appointment","crm_flag_label":"Color & Sensitivity Alerts","crm_flag_presets":["PPD Dye Patch Required","Sensitive Scalp","Keratin / Box Dye History","Lash Adhesive Sensitivity"],"show_staff_selection":true,"intake_fields":[{"id":"hair_chemical_history","label":"Chemical & Color History (Past 24 Months)","type":"multiselect","required":true,"options":["Virgin Hair (No color or chemicals ever)","Professional Salon Bleach / Highlights","At-Home Drugstore Box Dye / Black Color","Henna or Vegetable Dyes","Keratin Treatment / Brazilian Blowout","Chemical Perm or Relaxer"]},{"id":"current_hair_length","label":"Current Hair Length","type":"select","required":true,"options":["Pixie / Above Ears","Bob / Chin Length","Shoulder Length","Mid-Back Length","Waist Length or Longer (Requires extra time)"]},{"id":"ppd_allergy","label":"Have you ever experienced an allergic reaction or burning from hair dye (PPD)?","type":"boolean","required":true,"helper_text":"If yes, a 48-hour strand patch test is required prior to your chemical appointment."},{"id":"lash_contact_lenses","label":"Wearing contact lenses during lash appointments?","type":"boolean","required":false,"helper_text":"Please bring lens case or wear glasses to avoid eye irritation."}]}'::jsonb,
    '[{"name":"Lived-In Signature Balayage & Glaze","description":"Hand-painted multidimensional blonde with custom gloss tone and signature blowout.","duration_minutes":180,"price":320.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":75.00},{"name":"Master Stylist Precision Cut & Blowout","description":"Bespoke structural shear architecture, wash, and voluminous round-brush finish.","duration_minutes":60,"price":110.00,"payment_policy":"pay_at_venue"},{"name":"Brazilian Keratin Smoothing Complex","description":"Formaldehyde-free intensive amino smoothing eliminating 95% of frizz for 12 weeks.","duration_minutes":150,"price":350.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":100.00},{"name":"Full Set Russian Volume Lash Extensions","description":"Handmade lightweight 3D-6D volume fans delivering full, dark, fluffy lash drama.","duration_minutes":120,"price":220.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":50.00}]'::jsonb,
    '["Creative Director & Master Balayage Specialist","Senior Colorist & Keratin Expert","Certified Lash Master & Brow Sculptor"]'::jsonb,
    5,
    true
),
(
    'b0000001-0000-0000-0000-000000000006',
    'c0000003-0000-0000-0000-000000000003',
    'Day Spa & Massage Center',
    'day-spa-massage',
    'Therapeutic massage, basalt hot stones, infrared thermal suites, and couples romance duet rituals.',
    'spa_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":15,"buffer_minutes":15,"early_arrival_minutes":15,"requires_approval":false,"deposit_percent":25.0,"cancellation_window_hours":24,"advance_booking_days":90,"min_notice_hours":2,"working_hours":{"monday":{"open":"10:00","close":"20:00","is_open":true},"tuesday":{"open":"10:00","close":"20:00","is_open":true},"wednesday":{"open":"10:00","close":"20:00","is_open":true},"thursday":{"open":"10:00","close":"20:00","is_open":true},"friday":{"open":"10:00","close":"21:00","is_open":true},"saturday":{"open":"09:00","close":"20:00","is_open":true},"sunday":{"open":"10:00","close":"18:00","is_open":true}}}'::jsonb,
    '{"resource_type":"massage_therapist_and_treatment_room","resource_label":"Licensed Massage Therapist (LMT)","service_label":"Spa Ritual & Bodywork","client_label":"Guest","venue_label":"Spa","booking_label":"Session","crm_flag_label":"Allergies & Treatment Preferences","crm_flag_presets":["Nut / Carrier Oil Allergy","Essential Oil Sensitivity","Prenatal Protocol","Light Pressure Only","Hot Stone Sensitive"],"show_staff_selection":true,"intake_fields":[{"id":"desired_pressure","label":"Preferred Massage Pressure","type":"select","required":true,"options":["Light - Gentle flowing relaxation","Medium - Balanced stress relief and tension release","Firm - Deep muscle focus without sharp pain","Deep Tissue - Intense trigger point focus and myofascial release"]},{"id":"focus_and_avoid_areas","label":"Primary Focus Areas (Select all that apply)","type":"multiselect","required":true,"options":["Neck & Cervical Spine","Upper Shoulders & Trapezius","Lower Lumbar Back","Glutes & Sciatic Nerve","Legs & Hamstrings","Feet & Reflexology","Scalp & Temples","Avoid Glutes","Avoid Feet"]},{"id":"oil_scent_allergies","label":"Tree nut (almond carrier oil), iodine, or essential oil allergies?","type":"text","required":false,"placeholder":"None or specify allergies"},{"id":"pregnancy_status","label":"Are you currently pregnant?","type":"select","required":true,"options":["No","Yes - 1st Trimester (Under 12 weeks: contraindicated)","Yes - 2nd Trimester (13-27 weeks)","Yes - 3rd Trimester (28+ weeks)"]},{"id":"soundscape_ambience","label":"Treatment Room Soundscape Preference","type":"select","required":false,"options":["Gentle Ocean Waves & Rainfall","Tibetan Singing Bowls & Meditation","Soft Acoustic Piano & Cello","Complete Silence"]}]}'::jsonb,
    '[{"name":"Deep Tissue Neuromuscular Massage (60 min)","description":"Targeted myofascial release relieving chronic tension and muscle knots.","duration_minutes":60,"price":130.00,"payment_policy":"pay_at_venue"},{"name":"Basalt Heated Stone Full Body Therapy (75 min)","description":"Smooth volcanic river stones gliding deep heat into tired muscular tissues.","duration_minutes":75,"price":170.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":42.50},{"name":"Presidential Romance Duet Couples Massage (75 min)","description":"Side-by-side couples massage in our luxury fireplace suite.","duration_minutes":75,"price":320.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":160.00}]'::jsonb,
    '["Master Deep Tissue & Heated Stone Specialist","Sports Recovery & Myofascial Therapist","Holistic Aromatherapy & Prenatal Practitioner"]'::jsonb,
    6,
    true
),
(
    'b0000001-0000-0000-0000-000000000007',
    'c0000004-0000-0000-0000-000000000004',
    'Boutique Fitness Studio & Yoga',
    'fitness-pilates-yoga',
    'Reformer Pilates, 95° Infrared Vinyasa Yoga, 1-on-1 private movement analysis, and class credits.',
    'fitness_center_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":60,"buffer_minutes":10,"requires_approval":false,"deposit_percent":100.0,"cancellation_window_hours":12,"advance_booking_days":14,"min_notice_hours":1,"working_hours":{"monday":{"open":"06:00","close":"20:00","is_open":true},"tuesday":{"open":"06:00","close":"20:00","is_open":true},"wednesday":{"open":"06:00","close":"20:00","is_open":true},"thursday":{"open":"06:00","close":"20:00","is_open":true},"friday":{"open":"06:00","close":"19:00","is_open":true},"saturday":{"open":"07:00","close":"16:00","is_open":true},"sunday":{"open":"08:00","close":"14:00","is_open":true}}}'::jsonb,
    '{"resource_type":"instructor_and_studio_sanctuary","resource_label":"Certified Instructor","service_label":"Class / Private Session","client_label":"Member","venue_label":"Studio","booking_label":"Session","crm_flag_label":"Movement & Safety Flags","crm_flag_presets":["Knee / Meniscus Modification","Lower Back Modification","Shoulder / Wrist Prop Needed","Prenatal Modification","Grip Socks Checked"],"show_staff_selection":true,"intake_fields":[{"id":"fitness_experience_level","label":"Pilates / Yoga Experience Level","type":"select","required":true,"options":["First Timer (Never been on a Reformer before)","Beginner (1 - 5 classes completed)","Intermediate (Regular practitioner)","Advanced / Instructor"]},{"id":"injury_movement_limitations","label":"Current Injuries, Limitations or Surgeries (Select all that apply)","type":"multiselect","required":true,"options":["None - Healthy & Full Mobility","Lower Back Pain / Disc Herniation","Knee Pain / Meniscus / ACL","Neck / Cervical Spine","Shoulder / Rotator Cuff","Carpal Tunnel / Wrist Sensitivity","Diastasis Recti / Postpartum","Currently Pregnant"]},{"id":"grip_socks_acknowledgment","label":"Mandatory Grip Socks Policy Acknowledgment","type":"boolean","required":true,"helper_text":"Grip socks are strictly required for all Reformer classes for hygiene and traction."},{"id":"studio_liability_waiver","label":"Physical Activity Liability Release Waiver","type":"signature","required":true,"disclaimer":"I voluntarily participate in physical exercise at the studio and assume all risks of injury. I agree to inform the instructor of any pain or modifications needed."},{"id":"emergency_contact","label":"Emergency Contact (Name & Phone Number)","type":"text","required":true,"placeholder":"e.g. Alex Morgan - (555) 019-9988"}]}'::jsonb,
    '[{"name":"Signature Reformer Flow (All Levels)","description":"Full-body core integration, spinal articulation, and muscle endurance on Allegro 2 reformer.","duration_minutes":50,"price":36.00,"payment_policy":"full_upfront"},{"name":"95° Infrared Candlelight Vinyasa Yoga","description":"Therapeutic infrared heat promoting detoxifying sweat and deeper muscle flexibility.","duration_minutes":60,"price":28.00,"payment_policy":"full_upfront"},{"name":"1-on-1 Private Reformer & Movement Analysis","description":"Personalized kinetic biomechanics screen and tailored reformer workout.","duration_minutes":55,"price":115.00,"payment_policy":"full_upfront"}]'::jsonb,
    '["Lead Comprehensive Pilates Master Trainer","Senior Yoga Acharya & Sound Healer","Functional Movement & Mobility Coach"]'::jsonb,
    7,
    true
),
(
    'b0000001-0000-0000-0000-000000000008',
    'c0000005-0000-0000-0000-000000000005',
    'Legal & Financial Advisory',
    'legal-financial-advisory',
    'Built for attorneys, CPA tax advisors, financial planners, and corporate consultants.',
    'balance_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":60,"buffer_minutes":15,"requires_approval":true,"advance_booking_days":30,"min_notice_hours":24,"working_hours":{"monday":{"open":"09:00","close":"17:00","is_open":true},"tuesday":{"open":"09:00","close":"17:00","is_open":true},"wednesday":{"open":"09:00","close":"17:00","is_open":true},"thursday":{"open":"09:00","close":"17:00","is_open":true},"friday":{"open":"09:00","close":"16:00","is_open":true},"saturday":{"open":"00:00","close":"00:00","is_open":false},"sunday":{"open":"00:00","close":"00:00","is_open":false}}}'::jsonb,
    '{"resource_type":"person","resource_label":"Consultant / Attorney","service_label":"Advisory Engagement","client_label":"Client","venue_label":"Firm","booking_label":"Consultation","crm_flag_label":"Compliance & Matter Flags","crm_flag_presets":["Conflict Check Cleared","NDA On File","Retainer Active","Urgent Filing Deadline"],"show_staff_selection":true,"intake_fields":[{"id":"legal_matter","label":"Matter Type (Contract, Corporate, IP, Estate, Tax)","type":"text","placeholder":"e.g. Commercial Contract Review","required":true},{"id":"opposing_party","label":"Adverse / Opposing Party Name (for Conflict Check)","type":"text","placeholder":"Party or company name","required":true},{"id":"brief_summary","label":"Brief overview of question or matter","type":"textarea","placeholder":"Summarize key issues...","required":true}]}'::jsonb,
    '[{"name":"Initial Legal Strategy Consultation (60 min)","description":"Structured legal risk analysis, issue spotting, and engagement roadmap.","duration_minutes":60,"price":350.00,"payment_policy":"full_upfront"},{"name":"CPA Tax Planning & Entity Structure Review","description":"Tax mitigation optimization for business owners and high earners.","duration_minutes":60,"price":275.00,"payment_policy":"full_upfront"}]'::jsonb,
    '["Managing Partner / Attorney","Senior Tax CPA","Corporate Counsel"]'::jsonb,
    8,
    true
),
(
    'b0000001-0000-0000-0000-000000000009',
    'c0000006-0000-0000-0000-000000000006',
    'Photography & Podcast Studio',
    'photo-podcast-studio',
    'Designed for rentable production spaces, white cycloramas, and broadcast-ready podcast rooms.',
    'camera_indoor_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":60,"buffer_minutes":30,"requires_approval":false,"advance_booking_days":60,"min_notice_hours":4,"working_hours":{"monday":{"open":"08:00","close":"22:00","is_open":true},"tuesday":{"open":"08:00","close":"22:00","is_open":true},"wednesday":{"open":"08:00","close":"22:00","is_open":true},"thursday":{"open":"08:00","close":"22:00","is_open":true},"friday":{"open":"08:00","close":"23:00","is_open":true},"saturday":{"open":"08:00","close":"23:00","is_open":true},"sunday":{"open":"09:00","close":"21:00","is_open":true}}}'::jsonb,
    '{"resource_type":"facility","resource_label":"Studio Bay / Room","service_label":"Space Rental","client_label":"Producer / Client","venue_label":"Studio","booking_label":"Studio Booking","crm_flag_label":"Production & Gear Flags","crm_flag_presets":["200A Power Required","Cyclorama Repaint Add-On","Multi-Cam Podcast Rig","COI Insurance Verified"],"show_staff_selection":true,"intake_fields":[{"id":"crew_size","label":"Estimated Crew / Cast Size","type":"text","placeholder":"e.g. 5 people","required":true},{"id":"equipment_needs","label":"Special equipment requested (Strobes, Microphones, C-Stands)","type":"text","placeholder":"e.g. 4x Shure SM7B, Aputure 600d","required":false},{"id":"production_type","label":"Production Type (Fashion, Interview, Commercial)","type":"text","placeholder":"e.g. Video podcast recording","required":true}]}'::jsonb,
    '[{"name":"Soundproof 4-Mic Podcast Suite (Per Hour)","description":"Equipped with Shure SM7B mics, Rodecaster Pro II, Blackmagic 4K cameras, and studio headphones.","duration_minutes":60,"price":95.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":30.00},{"name":"White Cyclorama Photo & Video Bay (Per Hour)","description":"Corner infinity cove cyclorama with pre-rigged RGB ceiling grid and 200A power distribution.","duration_minutes":60,"price":140.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":50.00}]'::jsonb,
    '["Studio A (Cyclorama Cove)","Studio B (Podcast Suite)","Sound Stage C"]'::jsonb,
    9,
    true
),
(
    'b0000001-0000-0000-0000-000000000010',
    'c0000007-0000-0000-0000-000000000007',
    'Auto Detailing & Car Wash',
    'auto-detailing-car-wash',
    'Hand foam washes, interior steam extraction, 1-step machine polish, and multi-year ceramic paint coatings.',
    'local_car_wash_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":30,"buffer_minutes":10,"requires_approval":false,"deposit_percent":25.0,"cancellation_window_hours":24,"advance_booking_days":30,"min_notice_hours":2,"working_hours":{"monday":{"open":"08:00","close":"18:00","is_open":true},"tuesday":{"open":"08:00","close":"18:00","is_open":true},"wednesday":{"open":"08:00","close":"18:00","is_open":true},"thursday":{"open":"08:00","close":"18:00","is_open":true},"friday":{"open":"08:00","close":"18:00","is_open":true},"saturday":{"open":"08:00","close":"18:00","is_open":true},"sunday":{"open":"09:00","close":"16:00","is_open":true}}}'::jsonb,
    '{"resource_type":"bay_and_technician","resource_label":"Detailing Bay & Specialist","service_label":"Auto Detailing Package","client_label":"Driver / Owner","venue_label":"Shop","booking_label":"Detail Booking","crm_flag_label":"Vehicle & Paint Flags","crm_flag_presets":["Matte Paint / Vinyl Wrap","Ceramic Coated","PPF Protected","Heavy Pet Hair","Low Clearance Exotic"],"show_staff_selection":true,"intake_fields":[{"id":"vehicle_type","label":"Vehicle Size & Class","type":"select","required":true,"options":["Sedan / Hatchback","Mid-Size SUV / Crossover","Full-Size SUV / Pickup Truck","Minivan / Commercial Van"]},{"id":"vehicle_make_model_year","label":"Vehicle Year, Make & Model","type":"text","required":true,"placeholder":"e.g. 2024 Porsche Macan, Chalk White"},{"id":"license_plate","label":"License Plate # & State","type":"text","required":true,"placeholder":"e.g. 7XYZ123 (CA)"},{"id":"heavy_soiling_pet_hair","label":"Excessive pet hair, interior mold, or heavy caked mud?","type":"boolean","required":true,"helper_text":"Additional manual steam extraction surcharge ($30-$50) may apply at intake inspection."},{"id":"ceramic_matte_paint","label":"Vehicle has existing ceramic coating, matte paint, or protective vinyl wrap?","type":"boolean","required":false,"helper_text":"Ensures pH-neutral foam wash and contact-free drying towels."},{"id":"special_requests","label":"Interior focus areas or special requests","type":"textarea","required":false,"placeholder":"Cup holder stains, engine bay wipe, child car seat sanitized..."}]}'::jsonb,
    '[{"name":"Signature Hand Wash & Wheel Decon","description":"Touchless pre-foam, 2-bucket hand wash, iron wheel decontamination, and tire dressing.","duration_minutes":45,"price":55.00,"payment_policy":"pay_at_venue"},{"name":"Executive Interior Steam & Leather Care","description":"Deep dry steam extraction, vents sanitized, leather conditioned, and carpet shampoo.","duration_minutes":90,"price":165.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":40.00},{"name":"Complete Diamond Detail (In & Out)","description":"Full exterior clay bar decontamination, 1-month sealant, and intensive interior steam sanitize.","duration_minutes":150,"price":280.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":70.00},{"name":"3-Year Pro Ceramic Coating Package","description":"Full paint decontamination, multi-stage prep, and 9H SiO2 ceramic liquid glass application.","duration_minutes":240,"price":850.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":200.00}]'::jsonb,
    '["Bay 1: Master Certified Detailer & Paint Corrector","Bay 2: Senior Interior Steam Specialist","Bay 3: Ceramic Coating Technician"]'::jsonb,
    10,
    true
),
(
    'b0000001-0000-0000-0000-000000000011',
    'c0000007-0000-0000-0000-000000000007',
    'Express & Full-Service Car Wash',
    'express-car-wash',
    'High-throughput snow foam exterior washes, full inside-and-out vacuum packages, undercarriage mud flush, and hand wax bays.',
    'water_drop_rounded',
    'slot_based',
    '{"currency":"USD","slot_interval_minutes":15,"buffer_minutes":5,"requires_approval":false,"deposit_percent":0.0,"cancellation_window_hours":2,"advance_booking_days":14,"min_notice_hours":0,"working_hours":{"monday":{"open":"07:00","close":"20:00","is_open":true},"tuesday":{"open":"07:00","close":"20:00","is_open":true},"wednesday":{"open":"07:00","close":"20:00","is_open":true},"thursday":{"open":"07:00","close":"20:00","is_open":true},"friday":{"open":"07:00","close":"20:00","is_open":true},"saturday":{"open":"07:00","close":"20:00","is_open":true},"sunday":{"open":"08:00","close":"18:00","is_open":true}}}'::jsonb,
    '{"resource_type":"wash_bay","resource_label":"Wash Bay","service_label":"Car Wash Package","client_label":"Driver","venue_label":"Wash Station","booking_label":"Wash Slot","crm_flag_label":"Vehicle & Bay Clearance Flags","crm_flag_presets":["Matte Paint / Wrap","Oversize / Over 7ft","Aftermarket Roof Rack","Child Seat Steam Care"],"show_staff_selection":true,"intake_fields":[{"id":"vehicle_body_type","label":"Vehicle Size & Body Type","type":"select","required":true,"options":["Sedan / Coupe / Hatchback","Compact SUV / Crossover","Full-Size SUV / 3-Row / Pickup Truck","Passenger Van / Lifted 4x4"]},{"id":"vehicle_plate_and_model","label":"License Plate # & Vehicle Make / Color","type":"text","required":true,"placeholder":"e.g. ABC-1234 • Silver Toyota Hilux / White Civic"},{"id":"wash_addons","label":"Optional Express Add-Ons (Select any)","type":"multiselect","required":false,"options":["Undercarriage High-Pressure Mud & Salt Flush","Hydrophobic Rain-Repellent Glass Coat","Tire Gloss & Alloy Brake-Dust Brightener","Pet Hair & Trunk Brush Extraction","Antibacterial AC Vent Mist & Cabin Scent","Child Car Seat Steam Sanitize"]},{"id":"roof_rack_clearance_check","label":"Does vehicle exceed 7 ft height or carry unsecured roof-box / open pickup bed cargo?","type":"boolean","required":true,"blocking_condition":true,"blocking_message":"Vehicles over 7 ft clearance or carrying loose roof/bed cargo cannot enter standard wash bays safely. Please remove loose cargo or contact the wash bay crew for oversize hand-wash clearance.","helper_text":"Toggle ON only if over 7 ft height or carrying loose exterior items."},{"id":"matte_wrap_or_ppf","label":"Matte paint, vinyl wrap, PPF, or aftermarket antenna?","type":"boolean","required":false,"helper_text":"Crew will use pH-neutral snow foam and touch-safe microfiber drying."},{"id":"valuables_acknowledgment","label":"Pre-Wash Valuables & Exterior Inspection Check","type":"signature","required":true,"disclaimer":"I confirm personal valuables have been secured or removed from the cabin/console and power windows/sunroof are fully closed prior to wash bay entry."}]}'::jsonb,
    '[{"name":"Express Exterior Snow Foam & Dry","description":"High-pressure pre-rinse, thick pH-neutral snow foam bath, spot-free RO rinse, and microfiber air-dry.","duration_minutes":20,"price":18.00,"payment_policy":"pay_at_venue"},{"name":"Full-Service Inside & Out Car Wash","description":"Exterior snow foam hand wash, full cabin & trunk vacuum, dash/console wipe, door jambs, and streak-free glass.","duration_minutes":35,"price":32.00,"payment_policy":"pay_at_venue"},{"name":"SUV & Pickup Heavy Mud + Undercarriage Wash","description":"High-pressure chassis & wheel-well mud flush, bug/tar removal, rubber mat scrub, and deep interior vacuum.","duration_minutes":45,"price":45.00,"payment_policy":"pay_at_venue"},{"name":"Deluxe Carnauba Hand Wax & Tire Shine","description":"Full inside-and-out wash plus warm Brazilian carnauba hand wax for wet-look gloss and UV paint protection.","duration_minutes":50,"price":58.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":15.00},{"name":"VIP Wash + SiO2 Spray Ceramic Sealant","description":"Touchless foam wash, clay-mitt decon, 3-month hydrophobic SiO2 ceramic spray coat, and full interior wipe-down.","duration_minutes":60,"price":75.00,"payment_policy":"deposit","deposit_type":"fixed","deposit_amount":20.00}]'::jsonb,
    '["Wash Bay 1 (Express Snow Foam & Exterior)","Wash Bay 2 (Full-Service Inside & Out)","Wash Bay 3 (SUV / Pickup & Hand Wax Bay)"]'::jsonb,
    11,
    true
)
ON CONFLICT (id) DO UPDATE SET
    category_id = EXCLUDED.category_id,
    name = EXCLUDED.name,
    slug = EXCLUDED.slug,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    booking_model = EXCLUDED.booking_model,
    default_settings = EXCLUDED.default_settings,
    ui_config = EXCLUDED.ui_config,
    starter_services = EXCLUDED.starter_services,
    starter_staff_roles = EXCLUDED.starter_staff_roles,
    display_order = EXCLUDED.display_order,
    is_active = EXCLUDED.is_active;
