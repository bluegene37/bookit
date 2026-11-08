// Gene - Nov, 04, 2026: Edge Function to create Stripe Connect hosted checkout session with mock fallback
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { stripe, supabaseAdmin, corsHeaders, isAllowedRedirectUrl } from '../_shared/stripe.ts';

/*
// Gene - Nov, 05, 2026: Validate redirect URLs against trusted origins to prevent Open Redirect attacks (CWE-601)
function isAllowedUrl(urlStr: string): boolean {
  try {
    const parsed = new URL(urlStr);
    const hostname = parsed.hostname;
    return (
      hostname === 'localhost' ||
      hostname === '127.0.0.1' ||
      hostname.endsWith('.bookit.app') ||
      hostname === 'bookit.app' ||
      hostname.endsWith('.vercel.app') ||
      hostname.endsWith('.supabase.co')
    );
  } catch {
    return false;
  }
}
*/
// Gene - Nov, 08, 2026: Delegate redirect validation to shared isAllowedRedirectUrl (supports Vercel, BookIt, localhost, and bookit:// deep links)
function isAllowedUrl(urlStr: string): boolean {
  return isAllowedRedirectUrl(urlStr);
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    /*
    const { booking_id, return_url, cancel_url } = await req.json();
    */
    // Gene - Nov 07, 2026: Accept hybrid payment_method, reference_number, and sender_account in checkout request
    const {
      booking_id,
      return_url,
      cancel_url,
      payment_method = 'stripe_card',
      reference_number,
      sender_account,
    } = await req.json();

    // Gene - Nov, 05, 2026: Enforce URL origin validation
    if (return_url && !isAllowedUrl(return_url)) {
      throw new Error('Invalid return_url: domain not permitted');
    }
    if (cancel_url && !isAllowedUrl(cancel_url)) {
      throw new Error('Invalid cancel_url: domain not permitted');
    }

    // 1. Fetch booking details
    const { data: booking, error: bErr } = await supabaseAdmin
      .from('bookings')
      .select('*, businesses(*), services(*), profiles(*)')
      .eq('id', booking_id)
      .single();

    if (bErr || !booking) throw new Error('Booking not found');

    // Gene - Nov, 05, 2026: Verify caller ownership if authenticated
    const authHeader = req.headers.get('Authorization');
    const token = authHeader?.replace('Bearer ', '');
    if (token) {
      const { data: { user } } = await supabaseAdmin.auth.getUser(token);
      if (user && booking.client_id !== user.id) {
        const { data: callerProfile } = await supabaseAdmin
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
        if (callerProfile?.role !== 'admin') {
          return new Response(JSON.stringify({ error: 'Forbidden: You do not own this booking' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 403,
          });
        }
      }
    } else {
      // Gene - Nov, 08, 2026: Require authentication token when live Stripe credentials are active (CWE-306)
      const stripeKeyCheck = Deno.env.get('STRIPE_SECRET_KEY');
      if (stripeKeyCheck && stripeKeyCheck !== 'mock') {
        return new Response(JSON.stringify({ error: 'Unauthorized: Authentication required to create a checkout session' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        });
      }
    }

    const business = booking.businesses;
    const service = booking.services;
    const chargeAmount = service.payment_policy === 'deposit' 
      ? (service.deposit_type === 'percentage' 
          ? Number((service.price * (service.deposit_amount / 100)).toFixed(2)) 
          : Math.min(service.deposit_amount, service.price))
      : service.price;

    const chargeAmountCents = Math.round(chargeAmount * 100);

    // Mock fallback if Stripe keys are not set or running offline
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
    if (!stripeKey || stripeKey === 'mock') {
      return new Response(
        JSON.stringify({
          url: `${return_url}?booking_id=${booking_id}&mock=true`,
          session_id: `mock_cs_${Date.now()}`,
          is_mock: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // Calculate platform application fee
    const feePercent = business.platform_fee_percent || 2.50;
    const feeFixed = business.platform_fee_fixed || 0.30;
    const appFeeCents = Math.round((chargeAmount * (feePercent / 100) + feeFixed) * 100);

    // Gene - Nov 07, 2026: Handle direct clinic transfer channels (GCash, Maya, Bank Transfer) with reference tracking
    if (payment_method && payment_method !== 'stripe_card') {
      const remainingDue = Math.max(0, Number((service.price - chargeAmount).toFixed(2)));
      const paymentStatus = remainingDue === 0 ? 'paid_in_full' : 'deposit_paid';
      const effectiveRef = reference_number || `${payment_method.toUpperCase()}-${Date.now()}`;

      await supabaseAdmin
        .from('bookings')
        .update({
          status: 'confirmed',
          payment_status: paymentStatus,
          amount_paid: chargeAmount,
          amount_due: remainingDue,
          hold_expires_at: null,
          payment_method,
          payment_reference: effectiveRef,
          payment_sender: sender_account || null,
        })
        .eq('id', booking_id);

      await supabaseAdmin.from('payments').insert({
        booking_id,
        business_id: business.id,
        client_id: booking.client_id,
        gross_amount: chargeAmount,
        application_fee_amount: Number(((chargeAmount * (feePercent / 100)) + feeFixed).toFixed(2)),
        stripe_fee_amount: 0,
        net_amount: chargeAmount,
        currency: 'usd',
        payment_status: 'succeeded',
        payment_method,
        reference_number: effectiveRef,
        sender_account: sender_account || null,
      });

      return new Response(
        JSON.stringify({
          url: `${return_url}?booking_id=${booking_id}&method=${payment_method}&ref=${encodeURIComponent(effectiveRef)}`,
          session_id: effectiveRef,
          is_mock: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // Create Stripe Checkout Session
    const sessionConfig: any = {
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: {
            name: `${service.name} ${service.payment_policy === 'deposit' ? '(Booking Deposit)' : ''}`.trim(),
            description: `Reservation at ${business.name}`,
          },
          unit_amount: chargeAmountCents,
        },
        quantity: 1,
      }],
      mode: 'payment',
      client_reference_id: booking_id,
      success_url: `${return_url}?booking_id=${booking_id}&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${cancel_url}?booking_id=${booking_id}`,
    };

    if (business.stripe_account_id) {
      sessionConfig.payment_intent_data = {
        application_fee_amount: appFeeCents,
        transfer_data: { destination: business.stripe_account_id },
      };
    }

    const session = await stripe.checkout.sessions.create(sessionConfig);

    return new Response(
      JSON.stringify({ url: session.url, session_id: session.id, is_mock: false }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
