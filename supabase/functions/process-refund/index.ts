// Gene - Nov, 04, 2026: Stripe refund processor updating payments, refunds ledger, and booking amounts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { stripe, supabaseAdmin, corsHeaders } from '../_shared/stripe.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { payment_id, booking_id, amount, reason, created_by } = await req.json();

    if (!payment_id || !booking_id) {
      throw new Error('payment_id and booking_id are required');
    }

    // 1. Fetch payment record
    const { data: payment, error: pErr } = await supabaseAdmin
      .from('payments')
      .select('*')
      .eq('id', payment_id)
      .single();

    if (pErr || !payment) throw new Error('Payment record not found');

    // 2. Fetch booking record
    const { data: booking, error: bErr } = await supabaseAdmin
      .from('bookings')
      .select('*')
      .eq('id', booking_id)
      .single();

    if (bErr || !booking) throw new Error('Booking record not found');

    // 3. Validate refund amount
    const refundAmount = Number(amount);
    if (isNaN(refundAmount) || refundAmount <= 0) {
      throw new Error('Refund amount must be greater than zero');
    }

    const currentPaid = booking.amount_paid ?? payment.gross_amount;
    if (refundAmount > currentPaid) {
      throw new Error('Refund amount cannot exceed amount paid');
    }

    // 4. Mock fallback or Stripe API call
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
    let stripeRefundId = `mock_re_${Date.now()}`;
    let isMock = false;

    if (!stripeKey || stripeKey === 'mock' || !payment.stripe_payment_intent_id) {
      isMock = true;
    } else {
      const refundParams: any = {
        payment_intent: payment.stripe_payment_intent_id,
        amount: Math.round(refundAmount * 100),
      };

      if (reason === 'duplicate' || reason === 'fraudulent' || reason === 'requested_by_customer') {
        refundParams.reason = reason;
      }

      const refundRes = await stripe.refunds.create(refundParams);
      stripeRefundId = refundRes.id;
    }

    // 5. Insert into refunds ledger table
    const { data: refundRecord, error: rErr } = await supabaseAdmin
      .from('refunds')
      .insert({
        payment_id: payment_id,
        booking_id: booking_id,
        stripe_refund_id: stripeRefundId,
        amount: refundAmount,
        reason: reason || 'Customer requested refund',
        status: 'succeeded',
        created_by: created_by || null,
      })
      .select()
      .single();

    if (rErr) throw new Error(`Failed to create refund record: ${rErr.message}`);

    // 6. Update booking paid and due amounts
    const newAmountPaid = Math.max(0, Number((currentPaid - refundAmount).toFixed(2)));
    const newAmountDue = Math.max(0, Number(((booking.total_price || 0) - newAmountPaid).toFixed(2)));
    const newPaymentStatus = newAmountPaid === 0 ? 'refunded' : 'partially_refunded';

    await supabaseAdmin
      .from('bookings')
      .update({
        amount_paid: newAmountPaid,
        amount_due: newAmountDue,
        payment_status: newPaymentStatus,
      })
      .eq('id', booking_id);

    // 7. Update payments status if fully refunded
    if (newAmountPaid === 0) {
      await supabaseAdmin
        .from('payments')
        .update({ payment_status: 'refunded' })
        .eq('id', payment_id);
    }

    // 8. Create in-app audit notification
    await supabaseAdmin.from('notifications').insert({
      user_id: booking.client_id,
      business_id: booking.business_id,
      booking_id: booking_id,
      title: 'Refund Processed',
      body: `A refund of $${refundAmount.toFixed(2)} has been processed for your booking.`,
      type: 'booking_status',
    });

    return new Response(
      JSON.stringify({
        success: true,
        refund: refundRecord,
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
