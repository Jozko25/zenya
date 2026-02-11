-- ============================================================================
-- MOOD PATTERNS TABLE SCHEMA
-- ============================================================================
-- This table stores LLM-extracted mood patterns for each user.
-- Patterns are synced from the iOS app to enable cross-device persistence.
-- Users won't lose their personalized prediction data when changing devices.
-- ============================================================================

-- Create the mood_patterns table
CREATE TABLE IF NOT EXISTS public.mood_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,

    -- Pattern identification
    pattern_type VARCHAR(50) NOT NULL,           -- occupationType, weekdayPreference, significantDate, seasonalPattern, recurringTrigger
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Mood impact data
    mood_impact NUMERIC(4,2),                    -- -3.0 to +3.0 (how much this pattern affects mood)
    confidence NUMERIC(4,2),                     -- 0.0 to 1.0 (how confident we are in this pattern)

    -- Pattern-specific fields
    day_of_week INTEGER,                         -- 1-7 for weekday patterns (1=Sunday, 7=Saturday)
    month_day VARCHAR(5),                        -- "MM-DD" format for recurring yearly dates (e.g., "03-15" for March 15)
    occupation_type VARCHAR(50),                 -- employee, businessOwner, student, freelancer, unemployed, retired
    trigger_keywords TEXT[],                     -- Array of keywords that trigger this pattern

    -- Provenance tracking
    extracted_from_entry_id UUID,                -- Which journal entry this was extracted from
    extracted_snippet TEXT,                      -- Relevant text snippet from journal
    last_validated TIMESTAMPTZ,                  -- When this pattern was last confirmed

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT mood_patterns_mood_impact_range CHECK (mood_impact >= -3.0 AND mood_impact <= 3.0),
    CONSTRAINT mood_patterns_confidence_range CHECK (confidence >= 0.0 AND confidence <= 1.0),
    CONSTRAINT mood_patterns_day_of_week_range CHECK (day_of_week IS NULL OR (day_of_week >= 1 AND day_of_week <= 7)),
    CONSTRAINT mood_patterns_pattern_type_valid CHECK (pattern_type IN ('occupationType', 'weekdayPreference', 'significantDate', 'seasonalPattern', 'recurringTrigger'))
);

-- Add foreign key to users table (optional - comment out if users table has issues)
-- ALTER TABLE public.mood_patterns
--     ADD CONSTRAINT mood_patterns_user_id_fkey
--     FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_mood_patterns_user_id ON public.mood_patterns(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_patterns_user_created ON public.mood_patterns(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mood_patterns_pattern_type ON public.mood_patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_mood_patterns_day_of_week ON public.mood_patterns(day_of_week) WHERE day_of_week IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE public.mood_patterns ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Allow all access (permissive for MVP - tighten in production)
CREATE POLICY "Enable all access for mood_patterns"
ON public.mood_patterns
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- For production, use this more restrictive policy instead:
-- CREATE POLICY "Users can manage their own mood patterns"
-- ON public.mood_patterns
-- FOR ALL
-- TO authenticated
-- USING (auth.uid() = user_id)
-- WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- USER MOOD PROFILE TABLE (optional - for compact profile summaries)
-- ============================================================================
-- This table stores a compressed summary of each user's mood profile,
-- reducing the need to query all patterns for every prediction.

CREATE TABLE IF NOT EXISTS public.user_mood_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,

    -- Quick-access fields
    occupation_type VARCHAR(50),                 -- Cached occupation type for fast access
    llm_summary TEXT,                            -- Compressed text summary from LLM

    -- Metadata
    total_entries_analyzed INTEGER DEFAULT 0,    -- How many journal entries contributed to this profile
    last_extraction_date TIMESTAMPTZ,            -- When patterns were last extracted

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast user lookup
CREATE INDEX IF NOT EXISTS idx_user_mood_profiles_user_id ON public.user_mood_profiles(user_id);

-- Enable RLS
ALTER TABLE public.user_mood_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all access for user_mood_profiles"
ON public.user_mood_profiles
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- ============================================================================
-- ADD OCCUPATION TYPE COLUMN TO USERS TABLE (if needed)
-- ============================================================================
-- Run this if you want to store occupation type directly in the users table:

-- ALTER TABLE public.users
-- ADD COLUMN IF NOT EXISTS occupation_type VARCHAR(50);

-- ============================================================================
-- USAGE NOTES
-- ============================================================================
--
-- Pattern Types:
--   - occupationType: User's work situation (affects weekday mood patterns)
--   - weekdayPreference: Specific day preferences ("I hate Mondays")
--   - significantDate: Important recurring dates (birthdays, anniversaries, trauma dates)
--   - seasonalPattern: Seasonal mood variations (SAD, summer happiness)
--   - recurringTrigger: Keywords/topics that affect mood
--
-- Example patterns:
--   1. Employee occupation: pattern_type='occupationType', occupation_type='employee'
--      → Automatically applies -0.6 on Monday, +0.8 on Friday
--
--   2. Mother's death anniversary: pattern_type='significantDate', month_day='03-15', mood_impact=-2.0
--      → Every March 15, mood prediction decreases by 2 points
--
--   3. Hates Wednesdays: pattern_type='weekdayPreference', day_of_week=4, mood_impact=-1.5
--      → Every Wednesday, mood prediction decreases by 1.5 points
--
--   4. Work stress trigger: pattern_type='recurringTrigger', trigger_keywords=['deadline', 'boss', 'meeting'], mood_impact=-0.8
--      → When these words appear in journal, prediction adjusts
--
-- Data is extracted via LLM (PatternExtractionService) from journal entries
-- and synced to Supabase for cross-device persistence.
-- ============================================================================
