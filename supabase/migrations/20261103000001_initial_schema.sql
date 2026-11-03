-- Gene - Nov, 03, 2026: Initial schema for multi-tenant Universal Booking Platform (BookIt)
-- Includes profiles, businesses, staff/practitioners, services, bookings, notifications, and reviews.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table
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

-- 2. Businesses Table
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL, -- 'dental', 'medical', 'wellness', 'rental', etc.
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
    rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0.0,
    rating_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Business Staff / Practitioners Table
CREATE TABLE IF NOT EXISTS public.business_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    specialty TEXT, -- e.g., "Lead Orthodontist", "General Dentist", "Oral Surgeon"
    bio TEXT,
    avatar_url TEXT,
    schedule_override JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Services Table
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    duration_minutes INT NOT NULL DEFAULT 30,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'USD',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Bookings Table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    staff_id UUID REFERENCES public.business_staff(id) ON DELETE SET NULL,
    booking_model TEXT NOT NULL DEFAULT 'slot_based' CHECK (booking_model IN ('slot_based', 'date_range', 'daily')),
    start_time TIMESTAMPTZ, -- for slot_based
    end_time TIMESTAMPTZ,   -- for slot_based
    date_from DATE,         -- for date_range / daily
    date_to DATE,           -- for date_range
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'rejected')),
    total_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    client_notes TEXT,
    admin_notes TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Notifications Table
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

-- 7. Reviews Table
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

-- Create Indexes for fast querying
CREATE INDEX IF NOT EXISTS idx_businesses_category ON public.businesses(category);
CREATE INDEX IF NOT EXISTS idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_services_business ON public.services(business_id);
CREATE INDEX IF NOT EXISTS idx_staff_business ON public.business_staff(business_id);
CREATE INDEX IF NOT EXISTS idx_bookings_business ON public.bookings(business_id);
CREATE INDEX IF NOT EXISTS idx_bookings_client ON public.bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON public.bookings(start_time, date_from);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_reviews_business ON public.reviews(business_id);
