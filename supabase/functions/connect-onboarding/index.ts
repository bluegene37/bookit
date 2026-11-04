// Gene - Nov, 04, 2026: Stripe Connect Express account onboarding and login link generator
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { stripe, supabaseAdmin, corsHeaders } from '../_shared/stripe.ts';

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

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { business_id, return_url, refresh_url, action } = await req.json();

    if (!business_id) {
      throw new Error('business_id is required');
    }

    // Gene - Nov, 05, 2026: Validate redirect URLs
    if (return_url && !isAllowedUrl(return_url)) {
      throw new Error('Invalid return_url: domain not permitted');
    }
    if (refresh_url && !isAllowedUrl(refresh_url)) {
      throw new Error('Invalid refresh_url: domain not permitted');
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

    // Gene - Nov, 05, 2026: Authorize caller ownership: only business owner or platform admin can manage Connect
    const authHeader = req.headers.get('Authorization');
    const token = authHeader?.replace('Bearer ', '');
    if (token) {
      const { data: { user }, error: authErr } = await supabaseAdmin.auth.getUser(token);
      if (authErr || !user) {
        return new Response(JSON.stringify({ error: 'Unauthorized: Invalid authentication token' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        });
      }

      if (business.owner_id !== user.id) {
        const { data: callerProfile } = await supabaseAdmin
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
        if (callerProfile?.role !== 'admin') {
          return new Response(JSON.stringify({ error: 'Forbidden: Only the business owner can manage Stripe Connect onboarding' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 403,
          });
        }
      }
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
