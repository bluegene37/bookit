// Gene - Nov, 04, 2026: Edge Function to create Stripe Connect hosted checkout session with mock fallback
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { stripe, supabaseAdmin, corsHeaders } from '../_shared/stripe.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { booking_id, return_url, cancel_url } = await req.json();

    // 1. Fetch booking details
    const { data: booking, error: bErr } = await supabaseAdmin
      .from('bookings')
      .select('*, businesses(*), services(*), profiles(*)')
      .eq('id', booking_id)
      .single();

    if (bErr || !booking) throw new Error('Booking not found');

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
