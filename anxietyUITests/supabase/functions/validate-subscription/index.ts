// Supabase Edge Function: validate-subscription
// Checks if a device has an active subscription

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { device_id } = await req.json()

    if (!device_id) {
      return new Response(
        JSON.stringify({
          is_active: false,
          message: 'Device ID required'
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Look up user profile by device ID
    const { data: userProfile, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('device_id', device_id)
      .single()

    if (error || !userProfile) {
      return new Response(
        JSON.stringify({
          is_active: false,
          plan_type: null,
          expires_at: null,
          days_remaining: null
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Check if subscription is active
    const isActive = userProfile.has_active_subscription || false
    const expiresAt = userProfile.subscription_expires_at
    const planType = userProfile.subscription_plan

    let daysRemaining = null
    if (expiresAt) {
      const expiryDate = new Date(expiresAt)
      const now = new Date()
      const diffTime = expiryDate.getTime() - now.getTime()
      daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      
      // If expired, mark as inactive
      if (daysRemaining <= 0) {
        await supabase
          .from('user_profiles')
          .update({ has_active_subscription: false })
          .eq('id', userProfile.id)
        
        return new Response(
          JSON.stringify({
            is_active: false,
            plan_type: planType,
            expires_at: expiresAt,
            days_remaining: 0
          }),
          {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }
    }

    return new Response(
      JSON.stringify({
        is_active: isActive,
        plan_type: planType,
        expires_at: expiresAt,
        days_remaining: daysRemaining
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
        is_active: false,
        error: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
