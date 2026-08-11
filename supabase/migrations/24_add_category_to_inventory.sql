-- ============================================================
-- KAP-APP v2.0 — Migration 24: Add Category Column to Inventory
-- ============================================================

ALTER TABLE public.inventory 
ADD COLUMN IF NOT EXISTS category text;
