// Gene - Nov, 04, 2026: Stripe webhook listener verifying signatures and mutating booking & payment rows
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { stripe, supabaseAdmin, corsHeaders } from '../_shared/stripe.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const signature = req.headers.get('stripe-signature');
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');

  /*
  // Gene - Nov, 04, 2026: Insecure fallback to JSON.parse when signature is absent
  try {
    const body = await req.text();
    const event = webhookSecret && signature
      ? stripe.webhooks.constructEvent(body, signature, webhookSecret)
      : JSON.parse(body);
  */

  // Gene - Nov, 05, 2026: Enforce mandatory cryptographic signature verification; reject unverified requests (CWE-345)
  if (!signature || !webhookSecret) {
    return new Response(
      JSON.stringify({ error: 'Missing or invalid stripe-signature header or webhook secret' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
    );
  }

  try {
    const body = await req.text();
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret);

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      const bookingId = session.client_reference_id;
      const amountTotal = (session.amount_total || 0) / 100;

      // 1. Fetch booking to calculate remaining due
      const { data: booking } = await supabaseAdmin
        .from('bookings')
        .select('*')
        .eq('id', bookingId)
        .single();

      if (booking) {
        const remainingDue = Math.max(0, Number((booking.total_price - amountTotal).toFixed(2)));
        const paymentStatus = remainingDue === 0 ? 'paid_in_full' : 'deposit_paid';

        // 2. Update booking
        await supabaseAdmin
          .from('bookings')
          .update({
            status: 'confirmed',
            payment_status: paymentStatus,
            amount_paid: amountTotal,
            amount_due: remainingDue,
          })
          .eq('id', bookingId);

        // 3. Record in payments table
        await supabaseAdmin.from('payments').insert({
          booking_id: bookingId,
          business_id: booking.business_id,
          client_id: booking.client_id,
          stripe_session_id: session.id,
          stripe_payment_intent_id: session.payment_intent,
          gross_amount: amountTotal,
          net_amount: amountTotal, // Actual Stripe transfer net
          payment_status: 'succeeded',
          receipt_url: session.customer_details?.email ? `https://receipt.stripe.com/${session.id}` : null,
        });

        // 4. Create in-app notification (uses 'body' column per notifications schema)
        await supabaseAdmin.from('notifications').insert({
          user_id: booking.client_id,
          business_id: booking.business_id,
          booking_id: bookingId,
          title: 'Booking Confirmed!',
          body: `Your booking was confirmed. Paid: $${amountTotal.toFixed(2)}${remainingDue > 0 ? `, Due on arrival: $${remainingDue.toFixed(2)}` : ''}.`,
          type: 'booking_confirmed',
        });
      }
    } else if (event.type === 'charge.refunded') {
      const charge = event.data.object;
      const paymentIntentId = charge.payment_intent;
      if (paymentIntentId) {
        await supabaseAdmin
          .from('payments')
          .update({ payment_status: charge.refunded ? 'refunded' : 'partially_refunded' })
          .eq('stripe_payment_intent_id', paymentIntentId);
      }
    } else if (event.type === 'account.updated') {
      const account = event.data.object;
      if (account.id) {
        await supabaseAdmin
          .from('businesses')
          .update({ stripe_charges_enabled: account.charges_enabled ?? false })
          .eq('stripe_account_id', account.id);
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (err: any) {
    return new Response(`Webhook Error: ${err.message}`, {
      headers: corsHeaders,
      status: 400,
    });
  }
});
