-- ============================================================
-- KAP-APP v2.0 — Migration 22: Product Price Pool & Request History
-- ============================================================

-- 1. Add audit & categorization columns to public.requests
ALTER TABLE public.requests 
ADD COLUMN IF NOT EXISTS category text NOT NULL DEFAULT 'Genel',
ADD COLUMN IF NOT EXISTS bought_by uuid REFERENCES public.users(id),
ADD COLUMN IF NOT EXISTS bought_at timestamptz,
ADD COLUMN IF NOT EXISTS bought_price numeric(10,2);

-- 2. Create Crowdsourced Product Price Pool Table
CREATE TABLE IF NOT EXISTS public.product_price_pool (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_name text NOT NULL UNIQUE,
    category text NOT NULL DEFAULT 'Genel',
    estimated_price numeric(10,2) NOT NULL DEFAULT 0.00,
    min_price numeric(10,2) NOT NULL DEFAULT 0.00,
    max_price numeric(10,2) NOT NULL DEFAULT 0.00,
    sample_count integer NOT NULL DEFAULT 1,
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS on product_price_pool
ALTER TABLE public.product_price_pool ENABLE ROW LEVEL SECURITY;

-- RLS Policies for product_price_pool
DROP POLICY IF EXISTS "Allow authenticated read price pool" ON public.product_price_pool;
CREATE POLICY "Allow authenticated read price pool"
ON public.product_price_pool FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated write price pool" ON public.product_price_pool;
CREATE POLICY "Allow authenticated write price pool"
ON public.product_price_pool FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 3. Add default seed items to price pool for immediate AI & offline fallbacks
INSERT INTO public.product_price_pool (product_name, category, estimated_price, min_price, max_price, sample_count)
VALUES
    ('Süt (1L)', 'Süt & Kahvaltılık', 38.00, 32.00, 48.00, 10),
    ('Ekmek (Somun)', 'Temel Gıda', 10.00, 10.00, 15.00, 50),
    ('Yumurta (15li)', 'Süt & Kahvaltılık', 65.00, 55.00, 85.00, 15),
    ('Domates (1 kg)', 'Meyve & Sebze', 35.00, 25.00, 45.00, 20),
    ('Salatalık (1 kg)', 'Meyve & Sebze', 30.00, 20.00, 40.00, 18),
    ('Makarna (500g)', 'Temel Gıda', 18.00, 14.00, 25.00, 25),
    ('Ayçiçek Yağı (1L)', 'Temel Gıda', 60.00, 50.00, 75.00, 12),
    ('Çay (1 kg)', 'İçecek', 160.00, 140.00, 210.00, 8),
    ('Bulaşık Deterjanı', 'Temizlik', 45.00, 35.00, 65.00, 14),
    ('Tuvalet Kağıdı (12li)', 'Temizlik', 110.00, 85.00, 150.00, 10)
ON CONFLICT (product_name) DO NOTHING;
