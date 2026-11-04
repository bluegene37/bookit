-- Gene - Nov, 04, 2026: Master setup script combining all BookIt migrations & seed data
-- Run this in the Supabase Dashboard SQL Editor: https://supabase.com/dashboard/project/xjivgzyfewvdhiceaned/sql/new

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- 1. PROFILES TABLE
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('client', 'business_owner', 'admin')),
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 2. BUSINESS CATEGORIES & TEMPLATES
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.business_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon TEXT NOT NULL DEFAULT 'category',
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.business_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.business_categories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon TEXT NOT NULL DEFAULT 'business',
    booking_model TEXT NOT NULL CHECK (booking_model IN ('slot_based', 'date_range', 'daily')),
    default_settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    ui_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    starter_services JSONB NOT NULL DEFAULT '[]'::jsonb,
    starter_staff_roles JSONB NOT NULL DEFAULT '[]'::jsonb,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 3. BUSINESSES TABLE
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    template_id UUID REFERENCES public.business_templates(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    booking_model TEXT NOT NULL DEFAULT 'slot_based' CHECK (booking_model IN ('slot_based', 'date_range', 'daily')),
    description TEXT,
    address TEXT,
    city TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    contact_phone TEXT,
    contact_email TEXT,
    banner_url TEXT,
    logo_url TEXT,
    settings JSONB NOT NULL DEFAULT '{
        "slot_interval_minutes": 30,
        "buffer_minutes": 10,
        "requires_approval": false,
        "working_hours": {
            "monday": {"open": "09:00", "close": "18:00", "is_open": true},
            "tuesday": {"open": "09:00", "close": "18:00", "is_open": true},
            "wednesday": {"open": "09:00", "close": "18:00", "is_open": true},
            "thursday": {"open": "09:00", "close": "18:00", "is_open": true},
            "friday": {"open": "09:00", "close": "18:00", "is_open": true},
            "saturday": {"open": "09:00", "close": "14:00", "is_open": true},
            "sunday": {"open": "00:00", "close": "00:00", "is_open": false}
        }
    }'::jsonb,
    ui_config JSONB NOT NULL DEFAULT '{
        "resource_type": "person",
        "resource_label": "Specialist",
        "service_label": "Service",
        "show_staff_selection": true,
        "intake_fields": []
    }'::jsonb,
    stripe_account_id TEXT,
    stripe_charges_enabled BOOLEAN NOT NULL DEFAULT false,
    platform_fee_percent NUMERIC(4,2) NOT NULL DEFAULT 2.50,
    platform_fee_fixed NUMERIC(10,2) NOT NULL DEFAULT 0.30,
    rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0.0,
    rating_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 4. BUSINESS STAFF TABLE
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.business_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    specialty TEXT,
    bio TEXT,
    avatar_url TEXT,
    schedule_override JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 5. SERVICES TABLE
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    duration_minutes INT NOT NULL DEFAULT 30,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'USD',
    payment_policy TEXT NOT NULL DEFAULT 'full_upfront' CHECK (payment_policy IN ('full_upfront', 'deposit', 'pay_at_venue')),
    deposit_type TEXT NOT NULL DEFAULT 'percentage' CHECK (deposit_type IN ('percentage', 'fixed')),
    deposit_amount NUMERIC(10,2) NOT NULL DEFAULT 20.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 6. BOOKINGS TABLE
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    staff_id UUID REFERENCES public.business_staff(id) ON DELETE SET NULL,
    booking_model TEXT NOT NULL DEFAULT 'slot_based' CHECK (booking_model IN ('slot_based', 'date_range', 'daily')),
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    date_from DATE,
    date_to DATE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('awaiting_payment', 'pending', 'confirmed', 'completed', 'cancelled', 'rejected')),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'deposit_paid', 'paid_in_full', 'refunded', 'partially_refunded')),
    hold_expires_at TIMESTAMPTZ,
    total_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    amount_due NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    client_notes TEXT,
    admin_notes TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 7. PAYMENTS & REFUNDS TABLES
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    stripe_session_id TEXT UNIQUE,
    stripe_payment_intent_id TEXT UNIQUE,
    gross_amount NUMERIC(10,2) NOT NULL,
    application_fee_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    stripe_fee_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    net_amount NUMERIC(10,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'usd',
    payment_status TEXT NOT NULL DEFAULT 'succeeded',
    receipt_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    stripe_refund_id TEXT UNIQUE,
    amount NUMERIC(10,2) NOT NULL,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'succeeded',
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 8. NOTIFICATIONS & REVIEWS TABLES
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'booking_status',
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    booking_id UUID UNIQUE REFERENCES public.bookings(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 9. INDEXES
-- =====================================================================
CREATE INDEX IF NOT EXISTS idx_businesses_category ON public.businesses(category);
CREATE INDEX IF NOT EXISTS idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_businesses_template ON public.businesses(template_id);
CREATE INDEX IF NOT EXISTS idx_business_templates_category ON public.business_templates(category_id);
CREATE INDEX IF NOT EXISTS idx_services_business ON public.services(business_id);
CREATE INDEX IF NOT EXISTS idx_staff_business ON public.business_staff(business_id);
CREATE INDEX IF NOT EXISTS idx_bookings_business ON public.bookings(business_id);
CREATE INDEX IF NOT EXISTS idx_bookings_client ON public.bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON public.bookings(start_time, date_from);
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_business_id ON public.payments(business_id);
CREATE INDEX IF NOT EXISTS idx_refunds_booking_id ON public.refunds(booking_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_reviews_business ON public.reviews(business_id);

-- =====================================================================
-- 10. ROW LEVEL SECURITY (RLS)
-- =====================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Public read policies
CREATE POLICY "Public read active categories" ON public.business_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Public read active templates" ON public.business_templates FOR SELECT USING (is_active = true);
CREATE POLICY "Public read active businesses" ON public.businesses FOR SELECT USING (is_active = true OR auth.uid() = owner_id);
CREATE POLICY "Public read active staff" ON public.business_staff FOR SELECT USING (is_active = true);
CREATE POLICY "Public read active services" ON public.services FOR SELECT USING (is_active = true);
CREATE POLICY "Public read reviews" ON public.reviews FOR SELECT USING (true);

-- Authenticated profiles
CREATE POLICY "Users view profiles" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users insert profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Owners manage businesses, staff, services
CREATE POLICY "Owners create businesses" ON public.businesses FOR INSERT TO authenticated WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners update businesses" ON public.businesses FOR UPDATE TO authenticated USING (auth.uid() = owner_id);

CREATE POLICY "Owners manage staff" ON public.business_staff FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);

CREATE POLICY "Owners manage services" ON public.services FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);

-- Bookings policies
CREATE POLICY "Users view bookings" ON public.bookings FOR SELECT TO authenticated USING (
    client_id = auth.uid() OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);
CREATE POLICY "Clients create bookings" ON public.bookings FOR INSERT TO authenticated WITH CHECK (client_id = auth.uid());
CREATE POLICY "Users update bookings" ON public.bookings FOR UPDATE TO authenticated USING (
    client_id = auth.uid() OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);

-- Payments & Refunds policies
CREATE POLICY "Users view payments" ON public.payments FOR SELECT TO authenticated USING (
    client_id = auth.uid() OR business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid())
);
CREATE POLICY "Users view refunds" ON public.refunds FOR SELECT TO authenticated USING (
    booking_id IN (SELECT id FROM public.bookings WHERE client_id = auth.uid() OR business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid()))
);

-- Notifications
CREATE POLICY "Users view notifications" ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Users update notifications" ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Reviews
CREATE POLICY "Clients create reviews" ON public.reviews FOR INSERT TO authenticated WITH CHECK (client_id = auth.uid());
CREATE POLICY "Clients update reviews" ON public.reviews FOR UPDATE TO authenticated USING (client_id = auth.uid());

-- =====================================================================
-- 11. AUTOMATIC PROFILE CREATION TRIGGER
-- =====================================================================
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================================
-- 12. SEED DATA (CATEGORIES & TEMPLATES)
-- =====================================================================
INSERT INTO public.business_categories (id, name, slug, description, icon, display_order)
VALUES 
    ('c0000001-0000-0000-0000-000000000001', 'Healthcare & Clinics', 'healthcare-clinics', 'Dental practices, medical specialists, physical therapy, and clinical care.', 'medical_services_rounded', 1),
    ('c0000002-0000-0000-0000-000000000002', 'Wellness & Therapy', 'wellness-therapy', 'Mental health counseling, specialized post-op recovery retreats, and nutrition.', 'spa_rounded', 2),
    ('c0000003-0000-0000-0000-000000000003', 'Beauty & Personal Care', 'beauty-personal-care', 'Hair salons, barbershops, esthetics, medical spas, and nail care.', 'content_cut_rounded', 3),
    ('c0000004-0000-0000-0000-000000000004', 'Fitness & Coaching', 'fitness-coaching', '1-on-1 personal training, golf/tennis instruction, and specialized private coaching.', 'fitness_center_rounded', 4),
    ('c0000005-0000-0000-0000-000000000005', 'Professional Consulting', 'professional-consulting', 'Legal counsel, certified tax/accounting, financial advising, and architecture review.', 'gavel_rounded', 5),
    ('c0000006-0000-0000-0000-000000000006', 'Studios & Space Rentals', 'studios-space-rentals', 'Photography cycloramas, podcast/audio booths, and private production suites.', 'meeting_room_rounded', 6)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.business_templates (
    id, category_id, name, slug, description, icon, booking_model,
    default_settings, ui_config, starter_services, starter_staff_roles, display_order
) VALUES 
(
    't0000001-0000-0000-0000-000000000001',
    'c0000001-0000-0000-0000-000000000001',
    'Dental Care Clinic',
    'dental-clinic',
    'Perfect for general dentists, orthodontists, periodontists, and oral surgeons.',
    'medical_information_rounded',
    'slot_based',
    '{"slot_interval_minutes": 30, "buffer_minutes": 10, "requires_approval": false, "working_hours": {"monday": {"open": "09:00", "close": "18:00", "is_open": true}, "tuesday": {"open": "09:00", "close": "18:00", "is_open": true}, "wednesday": {"open": "09:00", "close": "18:00", "is_open": true}, "thursday": {"open": "09:00", "close": "18:00", "is_open": true}, "friday": {"open": "09:00", "close": "17:00", "is_open": true}, "saturday": {"open": "10:00", "close": "15:00", "is_open": true}, "sunday": {"open": "00:00", "close": "00:00", "is_open": false}}}'::jsonb,
    '{"resource_type": "person", "resource_label": "Dentist / Specialist", "service_label": "Dental Treatment", "show_staff_selection": true, "intake_fields": [{"id": "dental_insurance", "label": "Do you have dental insurance?", "type": "boolean", "required": false}, {"id": "insurance_carrier", "label": "Insurance Provider / Member ID", "type": "text", "placeholder": "e.g. Delta Dental / Cigna", "required": false}, {"id": "anesthesia_allergies", "label": "Allergies to local anesthesia, latex, or antibiotics?", "type": "text", "placeholder": "None or specify", "required": false}, {"id": "chief_complaint", "label": "Primary reason for visit / symptoms", "type": "textarea", "placeholder": "Checkup, tooth sensitivity, toothache...", "required": true}]}'::jsonb,
    '[{"name": "Comprehensive Exam & Digital X-Ray", "description": "Full mouth exam, digital radiography, and preventive gum scoring.", "duration_minutes": 45, "price": 120.00, "payment_policy": "deposit_required", "deposit_amount": 30.00}, {"name": "Preventive Teeth Cleaning (Prophylaxis)", "description": "Ultrasonic scaling, stain removal, and fluoride polish.", "duration_minutes": 45, "price": 95.00, "payment_policy": "pay_at_venue"}, {"name": "In-Office Teeth Whitening", "description": "Professional 60-minute accelerated light-activated whitening treatment.", "duration_minutes": 60, "price": 350.00, "payment_policy": "deposit_required", "deposit_amount": 50.00}, {"name": "Orthodontic & Invisalign Consultation", "description": "3D intraoral digital scan and smile simulation.", "duration_minutes": 30, "price": 50.00, "payment_policy": "full_upfront"}]'::jsonb,
    '["General Dentist", "Lead Orthodontist", "Dental Hygienist", "Oral Surgeon"]'::jsonb,
    1
),
(
    't0000001-0000-0000-0000-000000000002',
    'c0000001-0000-0000-0000-000000000001',
    'Medical Specialist & Dermatology',
    'medical-dermatology',
    'Ideal for dermatologists, pediatricians, cardiologists, and outpatient clinical consultations.',
    'health_and_safety_rounded',
    'slot_based',
    '{"slot_interval_minutes": 45, "buffer_minutes": 15, "requires_approval": false, "working_hours": {"monday": {"open": "08:30", "close": "17:30", "is_open": true}, "tuesday": {"open": "08:30", "close": "17:30", "is_open": true}, "wednesday": {"open": "08:30", "close": "17:30", "is_open": true}, "thursday": {"open": "08:30", "close": "17:30", "is_open": true}, "friday": {"open": "08:30", "close": "16:00", "is_open": true}, "saturday": {"open": "00:00", "close": "00:00", "is_open": false}, "sunday": {"open": "00:00", "close": "00:00", "is_open": false}}}'::jsonb,
    '{"resource_type": "person", "resource_label": "Physician / Doctor", "service_label": "Consultation / Procedure", "show_staff_selection": true, "intake_fields": [{"id": "medical_history", "label": "Relevant past medical conditions or surgeries", "type": "textarea", "placeholder": "None or list conditions", "required": false}, {"id": "current_medications", "label": "Current daily medications / dosages", "type": "text", "placeholder": "e.g. Lisinopril 10mg", "required": false}, {"id": "referral_doctor", "label": "Referring Doctor (if applicable)", "type": "text", "placeholder": "Doctor name or clinic", "required": false}]}'::jsonb,
    '[{"name": "New Patient Clinical Consultation", "description": "Comprehensive physical evaluation and diagnostics review.", "duration_minutes": 45, "price": 180.00, "payment_policy": "deposit_required", "deposit_amount": 50.00}, {"name": "Targeted Follow-up & Treatment Review", "description": "Ongoing care monitoring and prescription adjustment.", "duration_minutes": 30, "price": 95.00, "payment_policy": "pay_at_venue"}, {"name": "Clinical Skin Check & Biopsy Review", "description": "Full-body dermatoscope inspection of moles and lesions.", "duration_minutes": 45, "price": 220.00, "payment_policy": "deposit_required", "deposit_amount": 50.00}]'::jsonb,
    '["Board Certified Dermatologist", "Attending Physician", "Clinical Nurse Specialist"]'::jsonb,
    2
),
(
    't0000001-0000-0000-0000-000000000003',
    'c0000002-0000-0000-0000-000000000002',
    'Post-Op Recovery & Wellness Suites',
    'recovery-suites',
    'Specialized multi-day post-operative clinical suites with nursing supervision and rehabilitation support.',
    'hotel_rounded',
    'date_range',
    '{"checkin_time": "14:00", "checkout_time": "11:00", "min_days": 2, "max_days": 30, "requires_approval": true}'::jsonb,
    '{"resource_type": "facility", "resource_label": "Care Suite / Room", "service_label": "Recovery Tier", "show_staff_selection": false, "intake_fields": [{"id": "surgery_type", "label": "Surgical procedure type & hospital", "type": "text", "placeholder": "e.g. Orthopedic knee replacement at UCSF", "required": true}, {"id": "surgery_date", "label": "Surgery discharge date", "type": "text", "placeholder": "MM/DD/YYYY", "required": true}, {"id": "mobility_level", "label": "Assistance needed (Wheelchair, Walker, Bedbound)", "type": "text", "placeholder": "Describe mobility needs", "required": true}, {"id": "dietary_restrictions", "label": "Nutritional restrictions / allergies", "type": "text", "placeholder": "e.g. Low sodium, Diabetic, Gluten-free", "required": false}]}'::jsonb,
    '[{"name": "Private Clinical Recovery Suite (Per Night)", "description": "Private suite with 24/7 dedicated RN monitoring, physical therapy access, and chef-curated meals.", "duration_minutes": 1440, "price": 450.00, "payment_policy": "deposit_required", "deposit_amount": 100.00}, {"name": "Executive Care Suite & Companion Bed (Per Night)", "description": "Expanded double suite accommodating patient and accompanying family member.", "duration_minutes": 1440, "price": 650.00, "payment_policy": "deposit_required", "deposit_amount": 150.00}]'::jsonb,
    '["Lead Registered Nurse (RN)", "Physical Therapist", "Nutritional Coordinator"]'::jsonb,
    3
)
ON CONFLICT (id) DO NOTHING;
