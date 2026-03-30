-- 1. Create Admins Table (Hidden Backend Table)
CREATE TABLE IF NOT EXISTS public.admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'super_admin',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login TIMESTAMPTZ
);

-- 2. Update Profiles Table to match requested structure
-- columns: id, name, email, role, is_disabled, created_at
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT false;

-- 3. Add other administrative columns for establishments and products
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT false;
ALTER TABLE public.doctors ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT false;

-- 4. Set up a Super Admin (Replace email with your actual admin email)
-- Ensure 'ajhadk453@gimail.com' is marked as an admin
UPDATE public.profiles SET role = 'admin' WHERE email = 'ajhadk453@gimail.com';

-- 5. Enable Row Level Security (RLS) on core tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 6. Create Administrative RLS Policies
-- Profiles: Allow users to read all profiles, but only admins can update/delete any profile
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
CREATE POLICY "Admins can manage all profiles" ON public.profiles
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "Users can read all profiles" ON public.profiles;
CREATE POLICY "Users can read all profiles" ON public.profiles FOR SELECT USING (true);

-- Shops: Admins can manage all, others only read
DROP POLICY IF EXISTS "Admins can manage all shops" ON public.shops;
CREATE POLICY "Admins can manage all shops" ON public.shops
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "Public can view shops" ON public.shops;
CREATE POLICY "Public can view shops" ON public.shops FOR SELECT USING (true);

-- Products: Admins can manage all, others only read
DROP POLICY IF EXISTS "Admins can manage all products" ON public.products;
CREATE POLICY "Admins can manage all products" ON public.products
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "Public can view products" ON public.products;
CREATE POLICY "Public can view products" ON public.products FOR SELECT USING (true);

