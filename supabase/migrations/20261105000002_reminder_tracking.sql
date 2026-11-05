-- Gene - Nov, 05, 2026: Migration for Automated Dual-Stage Reminders (24-Hour & 2-Hour Notice tracking)

-- 1. Extend bookings table with reminder timestamps for strict idempotency
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS reminder_24h_sent TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS reminder_2h_sent TIMESTAMPTZ;

-- 2. Index for efficient scheduled querying by dispatch-reminders Edge Function
CREATE INDEX IF NOT EXISTS idx_bookings_reminder_lookup 
ON public.bookings(status, start_time, reminder_24h_sent, reminder_2h_sent)
WHERE status = 'confirmed';
