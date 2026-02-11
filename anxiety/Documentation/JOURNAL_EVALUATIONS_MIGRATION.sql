-- Migration Script for journal_evaluations
-- This handles the TEXT to UUID conversion for user_id

-- Step 1: Check if table exists and what type user_id is
DO $$ 
BEGIN
    -- If table doesn't exist, create it with UUID
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'journal_evaluations') THEN
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
            UNIQUE(user_id, evaluation_date)
        );
        
        RAISE NOTICE 'Created journal_evaluations table with UUID user_id';
    ELSE
        -- Table exists, check if user_id needs conversion
        RAISE NOTICE 'Table exists, checking user_id type...';
        
        -- If user_id is TEXT, we need to convert it
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'journal_evaluations' 
            AND column_name = 'user_id' 
            AND data_type = 'text'
        ) THEN
            RAISE NOTICE 'Converting user_id from TEXT to UUID...';
            
            -- Drop existing policies
            DROP POLICY IF EXISTS "Users can view own evaluations" ON journal_evaluations;
            DROP POLICY IF EXISTS "Users can insert own evaluations" ON journal_evaluations;
            DROP POLICY IF EXISTS "Users can update own evaluations" ON journal_evaluations;
            DROP POLICY IF EXISTS "Users can delete own evaluations" ON journal_evaluations;
            
            -- Drop the unique constraint
            ALTER TABLE journal_evaluations DROP CONSTRAINT IF EXISTS journal_evaluations_user_id_evaluation_date_key;
            
            -- Convert column from TEXT to UUID
            ALTER TABLE journal_evaluations 
            ALTER COLUMN user_id TYPE UUID USING user_id::UUID;
            
            -- Add back the unique constraint
            ALTER TABLE journal_evaluations 
            ADD CONSTRAINT journal_evaluations_user_id_evaluation_date_key UNIQUE(user_id, evaluation_date);
            
            -- Add foreign key constraint
            ALTER TABLE journal_evaluations
            ADD CONSTRAINT journal_evaluations_user_id_fkey 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'Successfully converted user_id to UUID';
        END IF;
    END IF;
END $$;

-- Step 2: Create indexes
CREATE INDEX IF NOT EXISTS idx_journal_evaluations_user_date 
ON journal_evaluations(user_id, evaluation_date DESC);

CREATE INDEX IF NOT EXISTS idx_journal_evaluations_created 
ON journal_evaluations(created_at DESC);

-- Step 3: Enable RLS
ALTER TABLE journal_evaluations ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view own evaluations" ON journal_evaluations;
DROP POLICY IF EXISTS "Users can insert own evaluations" ON journal_evaluations;
DROP POLICY IF EXISTS "Users can update own evaluations" ON journal_evaluations;
DROP POLICY IF EXISTS "Users can delete own evaluations" ON journal_evaluations;

-- Step 5: Create RLS policies (now with UUID comparison)
CREATE POLICY "Users can view own evaluations"
    ON journal_evaluations
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own evaluations"
    ON journal_evaluations
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own evaluations"
    ON journal_evaluations
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own evaluations"
    ON journal_evaluations
    FOR DELETE
    USING (auth.uid() = user_id);

-- Step 6: Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_journal_evaluations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create trigger
DROP TRIGGER IF EXISTS update_journal_evaluations_timestamp ON journal_evaluations;
CREATE TRIGGER update_journal_evaluations_timestamp
    BEFORE UPDATE ON journal_evaluations
    FOR EACH ROW
    EXECUTE FUNCTION update_journal_evaluations_updated_at();

-- Step 8: Grant permissions
GRANT ALL ON journal_evaluations TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '✅ Migration complete!';
    RAISE NOTICE 'Table: journal_evaluations';
    RAISE NOTICE 'user_id type: UUID';
    RAISE NOTICE 'RLS: enabled';
    RAISE NOTICE 'Policies: 4 (view, insert, update, delete)';
END $$;
