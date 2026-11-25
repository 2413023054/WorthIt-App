-- ====================================================================
-- WORTHIT - SUPABASE DATABASE SCHEMA WITH ROW LEVEL SECURITY (RLS)
-- ====================================================================
-- Jalankan skrip ini langsung di Supabase SQL Editor pada dashboard proyek Anda.
-- Skrip ini idempotent dan aman dijalankan ulang.

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL PROFILES (Profil Pengguna)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger pembuatan profil otomatis saat pengguna baru mendaftar via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. TABEL PURCHASE_ANALYSES (Riwayat Analisis Kelayakan Beli)
CREATE TABLE IF NOT EXISTS public.purchase_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    price NUMERIC(15, 2) NOT NULL,
    budget NUMERIC(15, 2) NOT NULL,
    need_level TEXT NOT NULL, -- 'Primer', 'Sekunder', 'Tersier'
    benefit_frequency TEXT NOT NULL, -- 'Setiap Hari', 'Beberapa Kali Seminggu', 'Jarang'
    recommendation_result TEXT NOT NULL, -- 'Worth It', 'Consider', 'Not Worth It'
    budget_ratio NUMERIC(5, 2) NOT NULL, -- Persentase (misal: 45.50%)
    reason_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TABEL PRICE_COMPARISONS (Riwayat Perbandingan Harga Produk)
CREATE TABLE IF NOT EXISTS public.price_comparisons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    comparison_category TEXT NOT NULL, -- 'Berat', 'Volume', 'Jumlah'
    user_budget NUMERIC(15, 2) DEFAULT 0,
    winner_product_name TEXT NOT NULL,
    winner_unit_price NUMERIC(15, 4) NOT NULL,
    reference_unit TEXT NOT NULL, -- 'per gram', 'per kg', 'per ml', 'per liter', 'per pcs'
    savings_percentage NUMERIC(5, 2) DEFAULT 0, -- Persentase penghematan dibanding termahal
    products_data JSONB NOT NULL, -- Array objek: [{name, price, size, unit, normalized_price, is_winner}]
    smart_budget_warning TEXT, -- Teks peringatan jika pemenang melebihi anggaran
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_purchase_analyses_user_id ON public.purchase_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_purchase_analyses_created_at ON public.purchase_analyses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_price_comparisons_user_id ON public.price_comparisons(user_id);
CREATE INDEX IF NOT EXISTS idx_price_comparisons_created_at ON public.price_comparisons(created_at DESC);

-- 6. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_comparisons ENABLE ROW LEVEL SECURITY;

-- 7. RLS POLICIES UNTUK TABEL PROFILES
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 8. RLS POLICIES UNTUK TABEL PURCHASE_ANALYSES
DROP POLICY IF EXISTS "Users can view their own purchase analyses" ON public.purchase_analyses;
CREATE POLICY "Users can view their own purchase analyses"
    ON public.purchase_analyses FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own purchase analyses" ON public.purchase_analyses;
CREATE POLICY "Users can insert their own purchase analyses"
    ON public.purchase_analyses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own purchase analyses" ON public.purchase_analyses;
CREATE POLICY "Users can update their own purchase analyses"
    ON public.purchase_analyses FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own purchase analyses" ON public.purchase_analyses;
CREATE POLICY "Users can delete their own purchase analyses"
    ON public.purchase_analyses FOR DELETE
    USING (auth.uid() = user_id);

-- 9. RLS POLICIES UNTUK TABEL PRICE_COMPARISONS
DROP POLICY IF EXISTS "Users can view their own price comparisons" ON public.price_comparisons;
CREATE POLICY "Users can view their own price comparisons"
    ON public.price_comparisons FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own price comparisons" ON public.price_comparisons;
CREATE POLICY "Users can insert their own price comparisons"
    ON public.price_comparisons FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own price comparisons" ON public.price_comparisons;
CREATE POLICY "Users can update their own price comparisons"
    ON public.price_comparisons FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own price comparisons" ON public.price_comparisons;
CREATE POLICY "Users can delete their own price comparisons"
    ON public.price_comparisons FOR DELETE
    USING (auth.uid() = user_id);
