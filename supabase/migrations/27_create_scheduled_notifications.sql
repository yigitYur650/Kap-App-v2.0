-- Migration 27: Create scheduled_notifications table for Admin Notification Management

CREATE TABLE IF NOT EXISTS public.scheduled_notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    body text NOT NULL,
    scheduled_time time NOT NULL, -- e.g. '12:00:00', '17:00:00'
    is_active boolean NOT NULL DEFAULT true,
    notification_type text NOT NULL DEFAULT 'daily_reminder', -- 'water', 'market', 'nutrition', 'custom'
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Comments
COMMENT ON TABLE public.scheduled_notifications IS 'Table holding automated daily push notification schedules configured by System Admins';
COMMENT ON COLUMN public.scheduled_notifications.scheduled_time IS 'Daily recurring time (24h format HH:mm:ss)';

-- Enable RLS
ALTER TABLE public.scheduled_notifications ENABLE ROW LEVEL SECURITY;

-- 1. Everyone logged in can read active scheduled notifications (for mobile background sync)
CREATE POLICY "Everyone can view active scheduled notifications"
    ON public.scheduled_notifications
    FOR SELECT
    TO authenticated
    USING (true);

-- 2. Only System Admins can insert, update, or delete scheduled notifications
CREATE POLICY "Only System Admins can manage scheduled notifications"
    ON public.scheduled_notifications
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.system_admins
            WHERE user_id = auth.uid()
        )
    );

-- Seed initial default automated daily reminders
INSERT INTO public.scheduled_notifications (title, body, scheduled_time, is_active, notification_type)
VALUES
    ('💧 Su İçme Zamanı!', 'Günlük su hedefinize ulaşmak için bir bardak su içmeyi unutmayın.', '12:00:00', true, 'water'),
    ('🛒 Eve Dönüş & Market Zamanı!', 'Kap-App alışveriş listenizdeki eksikleri kapıp eve dönmeye ne dersiniz?', '17:00:00', true, 'market'),
    ('🥗 Akşam Yemeği & Beslenme!', 'Bugünkü kalori ve protein hedeflerinizi kontrol ettiniz mi?', '20:00:00', true, 'nutrition')
ON CONFLICT DO NOTHING;
