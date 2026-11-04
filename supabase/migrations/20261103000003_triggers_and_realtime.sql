-- Gene - Nov, 03, 2026: Triggers, Rating aggregators, Notification generators & Realtime publication

-- 1. Automatic Profile Creation on auth.users Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'client'),
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        full_name = EXCLUDED.full_name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Gene - Nov, 04, 2026: Replaced DROP TRIGGER with CREATE OR REPLACE TRIGGER for idempotent non-destructive migration execution
/*
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
*/
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Business Rating Recalculation Trigger
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Gene - Nov, 04, 2026: Replaced DROP TRIGGER with CREATE OR REPLACE TRIGGER
/*
DROP TRIGGER IF EXISTS on_review_changed ON public.reviews;
CREATE TRIGGER on_review_changed
    AFTER INSERT OR UPDATE OR DELETE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_business_rating();
*/
CREATE OR REPLACE TRIGGER on_review_changed
    AFTER INSERT OR UPDATE OR DELETE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_business_rating();

-- 3. Automatic Notification on Booking Status Change
CREATE OR REPLACE FUNCTION public.handle_booking_status_notification()
RETURNS TRIGGER AS $$
DECLARE
    b_name TEXT;
BEGIN
    -- Only trigger on status change or new booking
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Gene - Nov, 04, 2026: Replaced DROP TRIGGER with CREATE OR REPLACE TRIGGER
/*
DROP TRIGGER IF EXISTS on_booking_status_updated ON public.bookings;
CREATE TRIGGER on_booking_status_updated
    AFTER INSERT OR UPDATE OF status ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.handle_booking_status_notification();
*/
CREATE OR REPLACE TRIGGER on_booking_status_updated
    AFTER INSERT OR UPDATE OF status ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.handle_booking_status_notification();

-- 4. Enable Supabase Realtime
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    END IF;
END $$;
