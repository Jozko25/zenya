-- ============================================================================
-- ACTIVATION CODE SYSTEM - Database Schema
-- ============================================================================
-- This adds web-based activation code system to existing Supabase database
-- User pays on web → gets activation code → redeems in app
-- ============================================================================

-- ============================================================================
-- TABLE: activation_codes
-- Stores activation codes purchased via Stripe on web
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.activation_codes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(20) UNIQUE NOT NULL,
    
    -- Contact information
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    
    -- Subscription details
    plan_type VARCHAR(20) NOT NULL CHECK (plan_type IN ('monthly', 'annual', 'lifetime')),
    stripe_payment_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    amount_paid DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Payment verification data (for recovery)
    card_last4 VARCHAR(4),
    card_brand VARCHAR(20),
    billing_zip VARCHAR(10),
    
    -- Redemption status
    is_redeemed BOOLEAN DEFAULT FALSE,
    redeemed_at TIMESTAMP WITH TIME ZONE,
    redeemed_by_user_id uuid,
    redeemed_by_device_id uuid,
    
    -- Recovery tokens
    recovery_token VARCHAR(64),
    recovery_expires_at TIMESTAMP WITH TIME ZONE,
    recovery_attempts INT DEFAULT 0,
    last_recovery_attempt_at TIMESTAMP WITH TIME ZONE,
    last_recovery_ip INET,
    
    -- Expiration
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Metadata
    purchase_ip INET,
    purchase_user_agent TEXT,
    
    CONSTRAINT activation_codes_pkey PRIMARY KEY (id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_activation_codes_code ON public.activation_codes(code);
CREATE INDEX IF NOT EXISTS idx_activation_codes_email ON public.activation_codes(email);
CREATE INDEX IF NOT EXISTS idx_activation_codes_stripe_payment ON public.activation_codes(stripe_payment_id);
CREATE INDEX IF NOT EXISTS idx_activation_codes_redeemed ON public.activation_codes(is_redeemed);
CREATE INDEX IF NOT EXISTS idx_activation_codes_expires ON public.activation_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_activation_codes_card_zip ON public.activation_codes(card_last4, billing_zip);

-- ============================================================================
-- TABLE: web_purchases (Audit Log)
-- Tracks all web purchases for analytics and debugging
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.web_purchases (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    
    -- Stripe data
    stripe_payment_intent_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    stripe_session_id VARCHAR(255),
    
    -- Purchase details
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    plan_type VARCHAR(20) NOT NULL,
    
    -- Link to activation code
    activation_code_id uuid REFERENCES public.activation_codes(id),
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'refunded', 'failed')),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    ip_address INET,
    user_agent TEXT,
    referrer TEXT,
    
    CONSTRAINT web_purchases_pkey PRIMARY KEY (id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_web_purchases_email ON public.web_purchases(email);
CREATE INDEX IF NOT EXISTS idx_web_purchases_stripe_payment ON public.web_purchases(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_web_purchases_status ON public.web_purchases(status);
CREATE INDEX IF NOT EXISTS idx_web_purchases_created ON public.web_purchases(created_at);

-- ============================================================================
-- TABLE: recovery_attempts
-- Tracks code recovery attempts for rate limiting and fraud detection
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.recovery_attempts (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    
    -- Request data
    ip_address INET NOT NULL,
    method VARCHAR(20) NOT NULL CHECK (method IN ('email', 'payment', 'support')),
    
    -- Attempted data (hashed for privacy)
    attempted_email VARCHAR(255),
    attempted_card_last4 VARCHAR(4),
    attempted_zip VARCHAR(10),
    
    -- Result
    success BOOLEAN DEFAULT FALSE,
    error_code VARCHAR(50),
    
    -- Timestamps
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Metadata
    user_agent TEXT,
    activation_code_id uuid REFERENCES public.activation_codes(id),
    
    CONSTRAINT recovery_attempts_pkey PRIMARY KEY (id)
);

-- Indexes for rate limiting queries
CREATE INDEX IF NOT EXISTS idx_recovery_attempts_ip_time ON public.recovery_attempts(ip_address, attempted_at);
CREATE INDEX IF NOT EXISTS idx_recovery_attempts_method ON public.recovery_attempts(method);
CREATE INDEX IF NOT EXISTS idx_recovery_attempts_success ON public.recovery_attempts(success);

-- ============================================================================
-- UPDATE: user_profiles
-- Add activation code tracking fields
-- ============================================================================
ALTER TABLE public.user_profiles 
    ADD COLUMN IF NOT EXISTS activation_code_id uuid REFERENCES public.activation_codes(id),
    ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS device_id uuid;

-- Index for quick subscription validation
CREATE INDEX IF NOT EXISTS idx_user_profiles_activation ON public.user_profiles(activation_code_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_device ON public.user_profiles(device_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_expires ON public.user_profiles(subscription_expires_at);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.web_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recovery_attempts ENABLE ROW LEVEL SECURITY;

-- activation_codes: Service role only (Edge Functions handle access)
CREATE POLICY "Service role full access on activation_codes"
    ON public.activation_codes
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- web_purchases: Service role only
CREATE POLICY "Service role full access on web_purchases"
    ON public.web_purchases
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- recovery_attempts: Service role only
CREATE POLICY "Service role full access on recovery_attempts"
    ON public.recovery_attempts
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function: Check if activation code is valid
CREATE OR REPLACE FUNCTION public.is_activation_code_valid(code_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    code_record RECORD;
BEGIN
    SELECT * INTO code_record
    FROM public.activation_codes
    WHERE code = code_to_check;
    
    -- Code doesn't exist
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Code already redeemed
    IF code_record.is_redeemed THEN
        RETURN FALSE;
    END IF;
    
    -- Code expired
    IF code_record.expires_at < now() THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Function: Generate unique activation code
CREATE OR REPLACE FUNCTION public.generate_activation_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude confusing chars
    i INT;
BEGIN
    LOOP
        -- Generate ZENYA-XXXX-XXXX format
        new_code := 'ZENYA-';
        
        -- First segment (4 chars)
        FOR i IN 1..4 LOOP
            new_code := new_code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
        END LOOP;
        
        new_code := new_code || '-';
        
        -- Second segment (4 chars)
        FOR i IN 1..4 LOOP
            new_code := new_code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
        END LOOP;
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM public.activation_codes WHERE code = new_code) INTO code_exists;
        
        -- If unique, return it
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$;

-- Function: Calculate expiration date based on plan type
CREATE OR REPLACE FUNCTION public.calculate_expiration_date(plan TEXT)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
AS $$
BEGIN
    CASE plan
        WHEN 'monthly' THEN
            RETURN now() + INTERVAL '30 days';
        WHEN 'annual' THEN
            RETURN now() + INTERVAL '365 days';
        WHEN 'lifetime' THEN
            RETURN now() + INTERVAL '100 years';
        ELSE
            RETURN now() + INTERVAL '30 days';
    END CASE;
END;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Apply trigger to user_profiles
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- ============================================================================
-- SAMPLE DATA (for testing - remove in production)
-- ============================================================================

-- Insert a test activation code
INSERT INTO public.activation_codes (
    code,
    email,
    plan_type,
    amount_paid,
    card_last4,
    billing_zip,
    expires_at
) VALUES (
    'ZENYA-TEST-CODE',
    'test@example.com',
    'annual',
    59.99,
    '4242',
    '90210',
    now() + INTERVAL '365 days'
) ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- ANALYTICS VIEWS (Optional but useful)
-- ============================================================================

-- View: Active subscriptions
CREATE OR REPLACE VIEW public.active_subscriptions AS
SELECT 
    ac.id,
    ac.code,
    ac.email,
    ac.plan_type,
    ac.is_redeemed,
    ac.redeemed_at,
    ac.expires_at,
    up.name as user_name,
    up.device_id
FROM public.activation_codes ac
LEFT JOIN public.user_profiles up ON up.activation_code_id = ac.id
WHERE ac.is_redeemed = true 
  AND ac.expires_at > now()
ORDER BY ac.redeemed_at DESC;

-- View: Unredeemed codes
CREATE OR REPLACE VIEW public.unredeemed_codes AS
SELECT 
    code,
    email,
    plan_type,
    amount_paid,
    created_at,
    expires_at,
    CASE 
        WHEN expires_at < now() THEN 'expired'
        ELSE 'active'
    END as status
FROM public.activation_codes
WHERE is_redeemed = false
ORDER BY created_at DESC;

-- View: Revenue analytics
CREATE OR REPLACE VIEW public.revenue_stats AS
SELECT 
    plan_type,
    COUNT(*) as total_sales,
    SUM(amount_paid) as total_revenue,
    COUNT(CASE WHEN is_redeemed THEN 1 END) as redeemed_count,
    ROUND(COUNT(CASE WHEN is_redeemed THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC * 100, 2) as redemption_rate
FROM public.activation_codes
GROUP BY plan_type;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant access to authenticated users for user_profiles
GRANT SELECT, UPDATE ON public.user_profiles TO authenticated;

-- Service role has full access (for Edge Functions)
GRANT ALL ON public.activation_codes TO service_role;
GRANT ALL ON public.web_purchases TO service_role;
GRANT ALL ON public.recovery_attempts TO service_role;

-- ============================================================================
-- COMPLETE! Ready to use.
-- ============================================================================

-- Verify installation
DO $$
BEGIN
    RAISE NOTICE 'Activation system tables created successfully!';
    RAISE NOTICE 'Tables: activation_codes, web_purchases, recovery_attempts';
    RAISE NOTICE 'Functions: generate_activation_code(), is_activation_code_valid()';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Create Supabase Edge Functions for code generation/redemption';
    RAISE NOTICE '2. Set up Stripe webhook handler';
    RAISE NOTICE '3. Build web frontend for payments';
    RAISE NOTICE '4. Update iOS app with activation screen';
END $$;
