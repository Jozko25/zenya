-- Journal Evaluations Table
-- Stores AI-powered daily journal analysis and insights

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own evaluations" ON journal_evaluations;
DROP POLICY IF EXISTS "Users can insert own evaluations" ON journal_evaluations;
DROP POLICY IF EXISTS "Users can update own evaluations" ON journal_evaluations;
DROP POLICY IF EXISTS "Users can delete own evaluations" ON journal_evaluations;

-- Drop and recreate table with UUID user_id
DROP TABLE IF EXISTS journal_evaluations CASCADE;

CREATE TABLE journal_evaluations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    evaluation_date DATE NOT NULL,
    maturity_score INTEGER NOT NULL CHECK (maturity_score >= 1 AND maturity_score <= 10),
    summary TEXT NOT NULL,
    key_insights TEXT[] NOT NULL DEFAULT '{}',
    emotional_themes TEXT[] NOT NULL DEFAULT '{}',
    growth_areas TEXT[] NOT NULL DEFAULT '{}',
    entry_count INTEGER NOT NULL DEFAULT 0,
    analyzed_content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure one evaluation per user per day
    UNIQUE(user_id, evaluation_date)
);

-- Index for faster queries
CREATE INDEX idx_journal_evaluations_user_date ON journal_evaluations(user_id, evaluation_date DESC);
CREATE INDEX idx_journal_evaluations_created ON journal_evaluations(created_at DESC);

-- RLS Policies
ALTER TABLE journal_evaluations ENABLE ROW LEVEL SECURITY;

-- Users can view their own evaluations
CREATE POLICY "Users can view own evaluations"
    ON journal_evaluations
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own evaluations
CREATE POLICY "Users can insert own evaluations"
    ON journal_evaluations
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own evaluations
CREATE POLICY "Users can update own evaluations"
    ON journal_evaluations
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own evaluations
CREATE POLICY "Users can delete own evaluations"
    ON journal_evaluations
    FOR DELETE
    USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_journal_evaluations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_journal_evaluations_timestamp ON journal_evaluations;
CREATE TRIGGER update_journal_evaluations_timestamp
    BEFORE UPDATE ON journal_evaluations
    FOR EACH ROW
    EXECUTE FUNCTION update_journal_evaluations_updated_at();

-- Grant permissions
GRANT ALL ON journal_evaluations TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
