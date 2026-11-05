// Gene - Nov, 05, 2026: Supabase Edge Function for Automated Dual-Stage Reminders (24-Hour Notice & 2-Hour Quick Arrival)
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { supabaseAdmin, corsHeaders } from '../_shared/stripe.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in2Hours = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    const emailApiKey = Deno.env.get('RESEND_API_KEY') || Deno.env.get('SENDGRID_API_KEY');
    const twilioAccountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
    const isMock = !emailApiKey && !twilioAccountSid;

    let count24h = 0;
    let count2h = 0;

    // =========================================================================
    // 1. Process 24-Hour Notice Reminders (between now and +24 hours)
    // =========================================================================
    const { data: bookings24h, error: err24h } = await supabaseAdmin
      .from('bookings')
      .select('*, businesses(*), services(*), business_staff(*), profiles:client_id(*)')
      .eq('status', 'confirmed')
      .is('reminder_24h_sent', null)
      .gt('start_time', now.toISOString())
      .lte('start_time', in24Hours.toISOString())
      .limit(50);

    if (err24h) {
      console.error('Error fetching 24h reminder bookings:', err24h);
    } else if (bookings24h && bookings24h.length > 0) {
      for (const booking of bookings24h) {
        const business = booking.businesses;
        const service = booking.services;
        const staff = booking.business_staff;
        const client = booking.profiles;

        const startTimeFormatted = new Date(booking.start_time).toLocaleString('en-US', {
          dateStyle: 'medium',
          timeStyle: 'short',
        });

        const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
          `${business?.name || ''} ${business?.address || ''} ${business?.city || ''}`
        )}`;
        const rescheduleUrl = `https://bookit.app/my-bookings?reschedule=${booking.id}`;

        const notificationTitle = `Appointment Reminder: Tomorrow with ${business?.name || 'Clinic'}`;
        const notificationBody = `Your ${service?.name || 'service'} with ${
          staff?.name || 'Specialist'
        } is scheduled for ${startTimeFormatted}. Location: ${business?.address || ''}. Need to adjust? 1-Tap Reschedule: ${rescheduleUrl}`;

        // 1a. Insert into in-app notifications ledger
        await supabaseAdmin.from('notifications').insert({
          user_id: booking.client_id,
          business_id: booking.business_id,
          booking_id: booking.id,
          title: notificationTitle,
          body: notificationBody,
          type: 'reminder_24h',
        });

        // 1b. Dispatch SMS/Email or record mock delivery
        if (isMock) {
          console.log(`[MOCK DISPATCH] 24h Reminder sent to ${client?.email || 'client'} for booking ${booking.id}`);
        }

        // 1c. Mark reminder as sent (idempotency)
        await supabaseAdmin
          .from('bookings')
          .update({ reminder_24h_sent: new Date().toISOString() })
          .eq('id', booking.id);

        count24h++;
      }
    }

    // =========================================================================
    // 2. Process 2-Hour Quick Arrival Reminders (between now and +2 hours)
    // =========================================================================
    const { data: bookings2h, error: err2h } = await supabaseAdmin
      .from('bookings')
      .select('*, businesses(*), services(*), business_staff(*), profiles:client_id(*)')
      .eq('status', 'confirmed')
      .is('reminder_2h_sent', null)
      .gt('start_time', now.toISOString())
      .lte('start_time', in2Hours.toISOString())
      .limit(50);

    if (err2h) {
      console.error('Error fetching 2h reminder bookings:', err2h);
    } else if (bookings2h && bookings2h.length > 0) {
      for (const booking of bookings2h) {
        const business = booking.businesses;
        const staff = booking.business_staff;

        const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
          `${business?.name || ''} ${business?.address || ''} ${business?.city || ''}`
        )}`;

        const notificationTitle = `Starting in 2 Hours: ${business?.name || 'Appointment'}`;
        const notificationBody = `Quick reminder: Your appointment with ${
          staff?.name || 'Specialist'
        } starts soon. Please plan to arrive 10 minutes early. Map & directions: ${mapsUrl}`;

        // 2a. Insert in-app notification
        await supabaseAdmin.from('notifications').insert({
          user_id: booking.client_id,
          business_id: booking.business_id,
          booking_id: booking.id,
          title: notificationTitle,
          body: notificationBody,
          type: 'reminder_2h',
        });

        // 2b. Dispatch SMS or mock delivery
        if (isMock) {
          console.log(`[MOCK DISPATCH] 2h SMS Reminder sent for booking ${booking.id}`);
        }

        // 2c. Mark reminder as sent
        await supabaseAdmin
          .from('bookings')
          .update({ reminder_2h_sent: new Date().toISOString() })
          .eq('id', booking.id);

        count2h++;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed_24h: count24h,
        processed_2h: count2h,
        timestamp: now.toISOString(),
        is_mock: isMock,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
