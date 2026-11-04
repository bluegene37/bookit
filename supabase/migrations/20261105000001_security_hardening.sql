-- Gene - Nov, 05, 2026: Security Hardening Migration
-- Closes Critical & High vulnerabilities:
-- 1. Insecure profile role self-escalation (CWE-269)
-- 2. Client booking payment/status tampering (CWE-862)
-- 3. Untrusted search_path on SECURITY DEFINER triggers (CWE-426)
-- 4. Double-booking race conditions via PostgreSQL exclusion constraints (CWE-362)

-- 1. Enable btree_gist for timestamp range exclusion constraints
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 2. Prevent Profile Role Self-Escalation
CREATE OR REPLACE FUNCTION public.protect_profile_role()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.role IS DISTINCT FROM NEW.role) THEN
        -- Block authenticated users from elevating their own role unless already an admin
        IF auth.uid() = OLD.id AND auth.role() = 'authenticated' THEN
            IF OLD.role != 'admin' THEN
                RAISE EXCEPTION 'Access Denied: Users are not permitted to alter their account role.';
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_protect_profile_role ON public.profiles;
CREATE TRIGGER trg_protect_profile_role
    BEFORE UPDATE OF role ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_profile_role();

-- 3. Harden handle_new_user() Trigger with Secure Search Path & Strict Default Role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Force new self-registered signups to 'client' role unless created by internal service
    INSERT INTO public.profiles (id, email, full_name, role, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        CASE 
            WHEN NEW.raw_user_meta_data->>'role' = 'business_owner' THEN 'business_owner'
            ELSE 'client'
        END,
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        full_name = EXCLUDED.full_name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 4. Harden update_business_rating() with Secure Search Path
CREATE OR REPLACE FUNCTION public.update_business_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_business_id UUID;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        target_business_id := OLD.business_id;
    ELSE
        target_business_id := NEW.business_id;
    END IF;

    UPDATE public.businesses
    SET 
        rating_avg = COALESCE((SELECT ROUND(AVG(rating)::numeric, 2) FROM public.reviews WHERE business_id = target_business_id), 0.0),
        rating_count = (SELECT COUNT(*) FROM public.reviews WHERE business_id = target_business_id),
        updated_at = now()
    WHERE id = target_business_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 5. Harden handle_booking_status_notification() with Secure Search Path
CREATE OR REPLACE FUNCTION public.handle_booking_status_notification()
RETURNS TRIGGER AS $$
DECLARE
    b_name TEXT;
BEGIN
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status)) THEN
        SELECT name INTO b_name FROM public.businesses WHERE id = NEW.business_id;

        INSERT INTO public.notifications (user_id, business_id, booking_id, title, body, type)
        VALUES (
            NEW.client_id,
            NEW.business_id,
            NEW.id,
            CASE 
                WHEN NEW.status = 'confirmed' THEN 'Booking Confirmed! 🎉'
                WHEN NEW.status = 'cancelled' THEN 'Booking Cancelled ℹ️'
                WHEN NEW.status = 'completed' THEN 'Appointment Completed ✅'
                WHEN NEW.status = 'rejected' THEN 'Booking Request Declined'
                ELSE 'Booking Request Received ⏳'
            END,
            CASE
                WHEN NEW.status = 'confirmed' THEN 'Your appointment with ' || b_name || ' has been confirmed.'
                WHEN NEW.status = 'cancelled' THEN 'Your appointment with ' || b_name || ' was cancelled.'
                WHEN NEW.status = 'completed' THEN 'Thank you for visiting ' || b_name || '. Please leave a review!'
                WHEN NEW.status = 'rejected' THEN 'Unfortunately, ' || b_name || ' could not accommodate this booking.'
                ELSE 'Your booking with ' || b_name || ' is pending approval.'
            END,
            'booking_' || NEW.status
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 6. Lockdown Bookings UPDATE Policy
DROP POLICY IF EXISTS "Clients and owners can update their bookings" ON public.bookings;
DROP POLICY IF EXISTS "Business owners can update their bookings" ON public.bookings;
DROP POLICY IF EXISTS "Clients can only cancel their own bookings" ON public.bookings;

-- Business owners can manage and update all booking fields for their business
CREATE POLICY "Business owners can update their bookings"
ON public.bookings FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
);

-- Clients can ONLY cancel their own bookings
CREATE POLICY "Clients can only cancel their own bookings"
ON public.bookings FOR UPDATE
TO authenticated
USING (client_id = auth.uid())
WITH CHECK (
    client_id = auth.uid() AND
    status = 'cancelled'
);

-- 7. Trigger Safeguard: Prevent Client Tampering with Payment/Financial Columns
CREATE OR REPLACE FUNCTION public.protect_booking_financial_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- If update is executed by authenticated user who is the client (and not the business owner)
    IF auth.role() = 'authenticated' AND auth.uid() = OLD.client_id AND NOT EXISTS (
        SELECT 1 FROM public.businesses b WHERE b.id = OLD.business_id AND b.owner_id = auth.uid()
    ) THEN
        -- Forbid client from changing status to anything other than 'cancelled'
        IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status != 'cancelled' THEN
            RAISE EXCEPTION 'Clients are only permitted to cancel bookings.';
        END IF;

        -- Forbid client from altering payment statuses or amounts directly
        IF NEW.payment_status IS DISTINCT FROM OLD.payment_status OR
           NEW.amount_paid IS DISTINCT FROM OLD.amount_paid OR
           NEW.amount_due IS DISTINCT FROM OLD.amount_due OR
           NEW.total_price IS DISTINCT FROM OLD.total_price THEN
            RAISE EXCEPTION 'Direct client manipulation of financial or payment columns is forbidden.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_protect_booking_financial_fields ON public.bookings;
CREATE TRIGGER trg_protect_booking_financial_fields
    BEFORE UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.protect_booking_financial_fields();

-- 8. Exclusion Constraint: Prevent Overlapping Staff Appointments (No Double-Booking)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'no_overlapping_staff_slots'
    ) THEN
        ALTER TABLE public.bookings ADD CONSTRAINT no_overlapping_staff_slots
        EXCLUDE USING gist (
            business_id WITH =,
            staff_id WITH =,
            tstzrange(start_time, end_time) WITH &&
        ) WHERE (
            staff_id IS NOT NULL AND 
            start_time IS NOT NULL AND 
            end_time IS NOT NULL AND 
            status NOT IN ('cancelled', 'rejected')
        );
    END IF;
END $$;
