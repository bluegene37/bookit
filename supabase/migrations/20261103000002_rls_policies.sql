-- Gene - Nov, 03, 2026: Row Level Security (RLS) Policies for BookIt multi-tenant platform

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 1. Profiles Policies
CREATE POLICY "Public profiles are viewable by authenticated users"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id);

-- 2. Businesses Policies
CREATE POLICY "Active businesses are publicly viewable"
ON public.businesses FOR SELECT
TO public
USING (is_active = true OR auth.uid() = owner_id);

CREATE POLICY "Business owners can create businesses"
ON public.businesses FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Business owners can update their own business"
ON public.businesses FOR UPDATE
TO authenticated
USING (auth.uid() = owner_id);

-- 3. Business Staff Policies
CREATE POLICY "Active staff are publicly viewable"
ON public.business_staff FOR SELECT
TO public
USING (is_active = true OR EXISTS (
    SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()
));

CREATE POLICY "Business owners can manage staff"
ON public.business_staff FOR ALL
TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()
));

-- 4. Services Policies
CREATE POLICY "Active services are publicly viewable"
ON public.services FOR SELECT
TO public
USING (is_active = true OR EXISTS (
    SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()
));

CREATE POLICY "Business owners can manage services"
ON public.services FOR ALL
TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()
));

-- 5. Bookings Policies
CREATE POLICY "Clients can view their own bookings"
ON public.bookings FOR SELECT
TO authenticated
USING (
    client_id = auth.uid() OR EXISTS (
        SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
);

CREATE POLICY "Clients can create bookings"
ON public.bookings FOR INSERT
TO authenticated
WITH CHECK (client_id = auth.uid());

CREATE POLICY "Clients and owners can update their bookings"
ON public.bookings FOR UPDATE
TO authenticated
USING (
    client_id = auth.uid() OR EXISTS (
        SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
);

-- 6. Notifications Policies
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- 7. Reviews Policies
CREATE POLICY "Reviews are viewable by everyone"
ON public.reviews FOR SELECT
TO public
USING (true);

CREATE POLICY "Clients can insert review for their completed booking"
ON public.reviews FOR INSERT
TO authenticated
WITH CHECK (
    client_id = auth.uid() AND EXISTS (
        SELECT 1 FROM public.bookings bk 
        WHERE bk.id = booking_id 
        AND bk.client_id = auth.uid() 
        AND bk.status = 'completed'
    )
);
