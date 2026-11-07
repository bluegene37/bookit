-- Gene - Nov 07, 2026: Hybrid Payment Methods (GCash, Maya, Bank Transfer, Stripe Card) Schema Extensions

ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'stripe_card',
ADD COLUMN IF NOT EXISTS payment_reference TEXT,
ADD COLUMN IF NOT EXISTS payment_sender TEXT;

ALTER TABLE public.payments
ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'stripe_card',
ADD COLUMN IF NOT EXISTS reference_number TEXT,
ADD COLUMN IF NOT EXISTS sender_account TEXT;

CREATE INDEX IF NOT EXISTS idx_payments_payment_method ON public.payments(payment_method);
CREATE INDEX IF NOT EXISTS idx_payments_reference_number ON public.payments(reference_number);

-- Gene - Nov, 7, 2026: Enable Supabase Realtime publication for public.payments table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'payments'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
    END IF;
END $$;
