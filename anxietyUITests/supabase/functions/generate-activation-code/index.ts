import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const allowedOrigins = [
  'https://zenya-web.vercel.app',
  'https://www.zenya.app',
  'https://zenya.app'
];

function getCorsHeaders(origin: string | null): Record<string, string> {
  const isAllowed = origin && allowedOrigins.includes(origin);
  return {
    'Access-Control-Allow-Origin': isAllowed ? origin : allowedOrigins[0],
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
  };
}

function generateActivationCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const segments = 3;
  const segmentLength = 4;
  
  let code = 'ZENYA';
  
  for (let i = 0; i < segments; i++) {
    code += '-';
    for (let j = 0; j < segmentLength; j++) {
      const randomBytes = new Uint8Array(1);
      crypto.getRandomValues(randomBytes);
      const randomIndex = randomBytes[0] % chars.length;
      code += chars.charAt(randomIndex);
    }
  }
  
  return code;
}

serve(async (req) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);
  
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { 
      email, 
      plan_type, 
      amount_paid, 
      stripe_payment_id, 
      stripe_customer_id, 
      card_last4, 
      card_brand, 
      billing_zip,
      metadata 
    } = await req.json();

    console.log('🎫 Generating activation code for:', email);

    // Generate activation code
    const code = generateActivationCode();
    
    console.log('✅ Generated code:', code);

    // Create Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Calculate expiration date
    const expiresAt = new Date();
    if (plan_type === 'annual') {
      expiresAt.setFullYear(expiresAt.getFullYear() + 1);
    } else {
      expiresAt.setMonth(expiresAt.getMonth() + 1);
    }

    // Insert activation code into database
    const { data, error } = await supabase
      .from('activation_codes')
      .insert({
        code,
        email,
        plan_type,
        amount_paid,
        stripe_payment_id,
        stripe_customer_id,
        card_last4,
        card_brand,
        billing_zip,
        expires_at: expiresAt.toISOString(),
        is_redeemed: false
      })
      .select()
      .single();

    if (error) {
      console.error('❌ Database error:', error);
      throw error;
    }

    console.log('✅ Code saved to database');

    return new Response(
      JSON.stringify({ 
        success: true,
        code,
        expires_at: expiresAt.toISOString(),
        data 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('❌ Error:', error);
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
