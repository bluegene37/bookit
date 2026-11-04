-- Gene - Nov, 04, 2026: Migration for Stripe Connect payments, flexible deposits, and refund ledgers

-- 1. Extend businesses table
ALTER TABLE public.businesses
ADD COLUMN IF NOT EXISTS stripe_account_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_charges_enabled BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS platform_fee_percent NUMERIC(4,2) NOT NULL DEFAULT 2.50,
ADD COLUMN IF NOT EXISTS platform_fee_fixed NUMERIC(10,2) NOT NULL DEFAULT 0.30;

-- 2. Extend services table
ALTER TABLE public.services
ADD COLUMN IF NOT EXISTS payment_policy TEXT NOT NULL DEFAULT 'full_upfront' 
    CHECK (payment_policy IN ('full_upfront', 'deposit', 'pay_at_venue')),
ADD COLUMN IF NOT EXISTS deposit_type TEXT NOT NULL DEFAULT 'percentage' 
    CHECK (deposit_type IN ('percentage', 'fixed')),
ADD COLUMN IF NOT EXISTS deposit_amount NUMERIC(10,2) NOT NULL DEFAULT 20.00;

-- 3. Extend bookings table
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_status_check;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_status_check 
    CHECK (status IN ('awaiting_payment', 'pending', 'confirmed', 'completed', 'cancelled', 'rejected'));

ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'deposit_paid', 'paid_in_full', 'refunded', 'partially_refunded')),
ADD COLUMN IF NOT EXISTS hold_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS amount_due NUMERIC(10,2) NOT NULL DEFAULT 0.00;

-- 4. Create payments table
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

-- 5. Create refunds table
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

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_business_id ON public.payments(business_id);
CREATE INDEX IF NOT EXISTS idx_refunds_booking_id ON public.refunds(booking_id);

-- 7. RLS
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own payments"
ON public.payments FOR SELECT
TO authenticated
USING (client_id = auth.uid() OR business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
));

CREATE POLICY "Users can view their own refunds"
ON public.refunds FOR SELECT
TO authenticated
USING (booking_id IN (
    SELECT id FROM public.bookings WHERE client_id = auth.uid() OR business_id IN (
        SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    )
));
