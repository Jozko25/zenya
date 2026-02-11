-- ============================================================================
-- FIX RLS POLICIES FOR USER_GAME_STATS
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own game stats" ON public.user_game_stats;
DROP POLICY IF EXISTS "Users can insert their own game stats" ON public.user_game_stats;
DROP POLICY IF EXISTS "Users can update their own game stats" ON public.user_game_stats;

-- Enable RLS on user_game_stats table
ALTER TABLE public.user_game_stats ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own game stats
CREATE POLICY "Users can view their own game stats"
ON public.user_game_stats
FOR SELECT
USING (true);  -- Allow all reads (stats are not sensitive)

-- Policy: Users can insert their own game stats
CREATE POLICY "Users can insert their own game stats"
ON public.user_game_stats
FOR INSERT
WITH CHECK (true);  -- Allow all inserts (we handle user_id in app)

-- Policy: Users can update their own game stats  
CREATE POLICY "Users can update their own game stats"
ON public.user_game_stats
FOR UPDATE
USING (true)  -- Allow all updates
WITH CHECK (true);

-- Policy: Users can delete their own game stats (optional)
CREATE POLICY "Users can delete their own game stats"
ON public.user_game_stats
FOR DELETE
USING (true);

-- ============================================================================
-- FIX RLS FOR OTHER TABLES (if needed)
-- ============================================================================

-- Journal Entries
DROP POLICY IF EXISTS "Users can manage their own journal entries" ON public.journal_entries;

CREATE POLICY "Users can manage their own journal entries"
ON public.journal_entries
FOR ALL
USING (true)
WITH CHECK (true);

-- Challenge Responses
DROP POLICY IF EXISTS "Users can manage their own challenge responses" ON public.challenge_responses;

CREATE POLICY "Users can manage their own challenge responses"
ON public.challenge_responses
FOR ALL
USING (true)
WITH CHECK (true);

-- Mood Entries
DROP POLICY IF EXISTS "Users can manage their own mood entries" ON public.mood_entries;

CREATE POLICY "Users can manage their own mood entries"
ON public.mood_entries
FOR ALL
USING (true)
WITH CHECK (true);

-- Breathing Sessions
DROP POLICY IF EXISTS "Users can manage their own breathing sessions" ON public.breathing_sessions;

CREATE POLICY "Users can manage their own breathing sessions"
ON public.breathing_sessions
FOR ALL
USING (true)
WITH CHECK (true);

-- ============================================================================
-- VERIFY POLICIES
-- ============================================================================

-- Check policies on user_game_stats
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'user_game_stats';

-- Check policies on journal_entries
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'journal_entries';

-- ============================================================================
-- NOTES
-- ============================================================================

/*
IMPORTANT: These policies are permissive for MVP/development.

For production, you should use proper user authentication and restrict policies like:

CREATE POLICY "Users can view their own game stats"
ON public.user_game_stats
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own game stats"
ON public.user_game_stats
FOR INSERT
WITH CHECK (auth.uid() = user_id);

But since you're using device-based UUIDs without Supabase auth,
we use permissive policies and trust the app to send correct user_id.
*/
