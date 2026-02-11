// Supabase Edge Function: redeem-activation-code
// Validates and redeems activation codes purchased on web

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const allowedOrigins = [
  'https://zenya-web.vercel.app',
  'https://www.zenya.app',
  'https://zenya.app'
]

function getCorsHeaders(origin: string | null): Record<string, string> {
  const isAllowed = origin && allowedOrigins.includes(origin)
  return {
    'Access-Control-Allow-Origin': isAllowed ? origin : allowedOrigins[0],
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
  }
}

serve(async (req) => {
  const origin = req.headers.get('origin')
  const corsHeaders = getCorsHeaders(origin)
  
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { code, device_id } = await req.json()

    // Validate input
    if (!code || !device_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'INVALID_REQUEST',
          message: 'Code and device_id are required'
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Clean and validate code format
    const cleanCode = code.trim().toUpperCase()
    const codeRegex = /^ZENYA-[A-Z0-9]{4}-[A-Z0-9]{4}$/
    
    if (!codeRegex.test(cleanCode)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'INVALID_CODE',
          message: 'Invalid code format. Expected: ZENYA-XXXX-XXXX'
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Look up activation code
    const { data: activationCode, error: lookupError } = await supabase
      .from('activation_codes')
      .select('*')
      .eq('code', cleanCode)
      .single()

    if (lookupError || !activationCode) {
      console.error('Code lookup error:', lookupError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'INVALID_CODE',
          message: 'This activation code is invalid.'
        }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Check if already redeemed
    if (activationCode.is_redeemed) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'ALREADY_REDEEMED',
          message: 'This activation code has already been used.'
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Check if expired
    const expiresAt = new Date(activationCode.expires_at)
    if (expiresAt < new Date()) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'EXPIRED',
          message: 'This activation code has expired.'
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Mark code as redeemed
    const { error: updateError } = await supabase
      .from('activation_codes')
      .update({
        is_redeemed: true,
        redeemed_at: new Date().toISOString(),
        redeemed_by_device_id: device_id
      })
      .eq('id', activationCode.id)

    if (updateError) {
      console.error('Failed to update activation code:', updateError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'DATABASE_ERROR',
          message: 'Failed to redeem code. Please try again.'
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Update or create user profile
    const { error: profileError } = await supabase
      .from('user_profiles')
      .upsert({
        id: device_id,
        has_active_subscription: true,
        subscription_plan: activationCode.plan_type,
        subscription_expires_at: activationCode.expires_at,
        activation_code_id: activationCode.id,
        device_id: device_id,
        updated_at: new Date().toISOString()
      })

    if (profileError) {
      console.error('Failed to update user profile:', profileError)
    }

    // Success!
    console.log(`✅ Code redeemed: ${cleanCode} by device ${device_id}`)

    return new Response(
      JSON.stringify({
        success: true,
        user_id: device_id,
        plan_type: activationCode.plan_type,
        expires_at: activationCode.expires_at,
        customer_id: activationCode.stripe_customer_id || null,
        message: 'Activation successful!'
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: 'SERVER_ERROR',
        message: error.message || 'An unexpected error occurred'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
