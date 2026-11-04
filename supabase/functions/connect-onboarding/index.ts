// Gene - Nov, 04, 2026: Stripe Connect Express account onboarding and login link generator
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { stripe, supabaseAdmin, corsHeaders } from '../_shared/stripe.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { business_id, return_url, refresh_url, action } = await req.json();

    if (!business_id) {
      throw new Error('business_id is required');
    }

    // 1. Fetch business record
    const { data: business, error: bizErr } = await supabaseAdmin
      .from('businesses')
      .select('*')
      .eq('id', business_id)
      .single();

    if (bizErr || !business) {
      throw new Error('Business not found');
    }

    // 2. Mock fallback for local development or preview environments
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
    if (!stripeKey || stripeKey === 'mock') {
      const mockAccountId = business.stripe_account_id || `acct_mock_${Date.now()}`;
      if (!business.stripe_account_id) {
        await supabaseAdmin
          .from('businesses')
          .update({
            stripe_account_id: mockAccountId,
            stripe_charges_enabled: true,
          })
          .eq('id', business_id);
      }

      return new Response(
        JSON.stringify({
          url: `${return_url || 'https://bookit.app'}?stripe_connected=true&mock=true`,
          account_id: mockAccountId,
          is_mock: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // 3. Login link for already onboarded accounts
    if (action === 'login_link' && business.stripe_account_id) {
      const loginLink = await stripe.accounts.createLoginLink(business.stripe_account_id);
      return new Response(
        JSON.stringify({ url: loginLink.url, is_mock: false }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // 4. Create Express account if not already created
    let accountId = business.stripe_account_id;
    if (!accountId) {
      const account = await stripe.accounts.create({
        type: 'express',
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        business_profile: {
          name: business.name,
        },
      });
      accountId = account.id;

      await supabaseAdmin
        .from('businesses')
        .update({ stripe_account_id: accountId })
        .eq('id', business_id);
    }

    // 5. Create Express onboarding AccountLink
    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refresh_url || return_url,
      return_url: return_url,
      type: 'account_onboarding',
    });

    return new Response(
      JSON.stringify({
        url: accountLink.url,
        account_id: accountId,
        is_mock: false,
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
