-- Migration 13: Enable Supabase Realtime for requests table
-- This allows real-time WebSocket updates across clients when requests are added or modified.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE requests;
  END IF;
END $$;
