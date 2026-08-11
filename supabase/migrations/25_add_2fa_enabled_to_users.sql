-- Migration 25: Make 2-Step Verification (2FA) mandatory for all accounts

-- 1. Add is_2fa_enabled column defaulting to true (Mandatory 2FA)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_2fa_enabled boolean NOT NULL DEFAULT true;

-- Update existing users to enable mandatory 2FA
UPDATE public.users SET is_2fa_enabled = true;

COMMENT ON COLUMN public.users.is_2fa_enabled IS 'Indicates whether 2-step email verification (2FA) is enabled for this account (Default: true)';

-- 2. Ensure halil@gmail.com is registered as System Admin and exempted from 2FA
INSERT INTO public.system_admins (user_id)
SELECT id FROM public.users WHERE email = 'halil@gmail.com'
ON CONFLICT DO NOTHING;

UPDATE public.users SET is_2fa_enabled = false WHERE email = 'halil@gmail.com';

