-- Migration 28: Ensure health_profiles table exists and has all nutrition v2 fields

-- 1. Create table if it doesn't exist yet
CREATE TABLE IF NOT EXISTS public.health_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    weight NUMERIC(5,2) NOT NULL DEFAULT 70.0,
    height NUMERIC(5,2) NOT NULL DEFAULT 170.0,
    age INT NOT NULL DEFAULT 25,
    gender VARCHAR(10) NOT NULL DEFAULT 'male',
    activity_level VARCHAR(20) NOT NULL DEFAULT 'moderate',
    goal VARCHAR(20) NOT NULL DEFAULT 'maintain',
    fitness_goal VARCHAR(30) NOT NULL DEFAULT 'balanced',
    daily_water_intake_liters DOUBLE PRECISION DEFAULT 2.5,
    body_fat_percentage DOUBLE PRECISION DEFAULT 20.0,
    has_kidney_disease BOOLEAN DEFAULT false,
    allergens TEXT[] DEFAULT '{}',
    is_public BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Add columns if table already existed without them
ALTER TABLE public.health_profiles
ADD COLUMN IF NOT EXISTS fitness_goal VARCHAR(30) DEFAULT 'balanced',
ADD COLUMN IF NOT EXISTS daily_water_intake_liters DOUBLE PRECISION DEFAULT 2.5,
ADD COLUMN IF NOT EXISTS body_fat_percentage DOUBLE PRECISION DEFAULT 20.0,
ADD COLUMN IF NOT EXISTS has_kidney_disease BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS allergens TEXT[] DEFAULT '{}';

-- 3. Enable RLS
ALTER TABLE public.health_profiles ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
DROP POLICY IF EXISTS "Users can select own or public health profiles" ON public.health_profiles;
CREATE POLICY "Users can select own or public health profiles"
    ON public.health_profiles FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id OR is_public = true
    );

DROP POLICY IF EXISTS "Users can insert own health profile" ON public.health_profiles;
CREATE POLICY "Users can insert own health profile"
    ON public.health_profiles FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = user_id
    );

DROP POLICY IF EXISTS "Users can update own health profile" ON public.health_profiles;
CREATE POLICY "Users can update own health profile"
    ON public.health_profiles FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = user_id
    )
    WITH CHECK (
        auth.uid() = user_id
    );

-- 5. Updated_at Trigger
CREATE OR REPLACE FUNCTION public.handle_health_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_health_profiles_updated_at ON public.health_profiles;
CREATE TRIGGER tr_health_profiles_updated_at
    BEFORE UPDATE ON public.health_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_health_profiles_updated_at();
