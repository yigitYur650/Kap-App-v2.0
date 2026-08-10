-- Migration 23: Personal Health Profiles & Privacy Sharing Schema

CREATE TABLE IF NOT EXISTS public.health_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    weight NUMERIC(5,2) NOT NULL DEFAULT 70.0,
    height NUMERIC(5,2) NOT NULL DEFAULT 170.0,
    age INT NOT NULL DEFAULT 25,
    gender VARCHAR(10) NOT NULL DEFAULT 'male',
    activity_level VARCHAR(20) NOT NULL DEFAULT 'moderate',
    goal VARCHAR(20) NOT NULL DEFAULT 'maintain',
    is_public BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.health_profiles ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can SELECT their own profile or any profile that is marked public
CREATE POLICY "Users can select own or public health profiles"
    ON public.health_profiles FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id OR is_public = true
    );

-- Policy 2: Users can INSERT their own profile
CREATE POLICY "Users can insert own health profile"
    ON public.health_profiles FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = user_id
    );

-- Policy 3: Users can UPDATE their own profile
CREATE POLICY "Users can update own health profile"
    ON public.health_profiles FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = user_id
    )
    WITH CHECK (
        auth.uid() = user_id
    );

-- Updated_at trigger
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
