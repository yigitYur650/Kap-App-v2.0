-- Migration 26: Add daily_water_intake_liters and body_fat_percentage to health_profiles

ALTER TABLE public.health_profiles
ADD COLUMN IF NOT EXISTS daily_water_intake_liters double precision DEFAULT 2.5,
ADD COLUMN IF NOT EXISTS body_fat_percentage double precision DEFAULT 20.0;

COMMENT ON COLUMN public.health_profiles.daily_water_intake_liters IS 'User average daily water intake in Liters';
COMMENT ON COLUMN public.health_profiles.body_fat_percentage IS 'User body fat percentage';
