// Gene - Nov, 04, 2026: Shared Stripe client and Supabase admin client initialization
import Stripe from 'https://esm.sh/stripe@14.14.0?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

/*
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
*/

// Gene - Nov, 08, 2026: Added origin-validated CORS headers and shared redirect URL validator for Vercel & mobile deep-link security
export const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGIN') || '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cron-secret',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};

export function isTrustedHostname(hostname: string): boolean {
  const customOrigin = Deno.env.get('ALLOWED_ORIGIN');
  if (customOrigin) {
    try {
      if (new URL(customOrigin).hostname === hostname) return true;
    } catch {
      // ignore malformed ALLOWED_ORIGIN
    }
  }
  return (
    hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname === 'bookit.app' ||
    hostname.endsWith('.bookit.app') ||
    hostname.endsWith('.vercel.app') ||
    hostname.endsWith('.supabase.co')
  );
}

export function isAllowedRedirectUrl(urlStr: string): boolean {
  try {
    const parsed = new URL(urlStr);
    if (parsed.protocol === 'bookit:') return true;
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return false;
    return isTrustedHostname(parsed.hostname);
  } catch {
    return false;
  }
}

export function getCorsHeaders(req?: Request): Record<string, string> {
  const origin = req?.headers.get('Origin');
  if (origin) {
    try {
      const parsed = new URL(origin);
      if (isTrustedHostname(parsed.hostname)) {
        return {
          ...corsHeaders,
          'Access-Control-Allow-Origin': origin,
          'Vary': 'Origin',
        };
      }
    } catch {
      // fall through
    }
  }
  return corsHeaders;
}

export const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

export const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);
