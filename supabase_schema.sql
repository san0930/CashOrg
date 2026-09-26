-- ==============================================================================
-- SUPABASE DATABASE SETUP SCRIPT FOR EXPENSE TRACKER APP
-- Run this entire script in your Supabase SQL Editor (https://supabase.com/dashboard)
-- ==============================================================================

-- 1. Create PROFILES Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow individual read access" ON public.profiles;
DROP POLICY IF EXISTS "Allow individual insert access" ON public.profiles;
DROP POLICY IF EXISTS "Allow individual update access" ON public.profiles;

CREATE POLICY "Allow individual read access" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow individual insert access" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Allow individual update access" ON public.profiles FOR UPDATE USING (auth.uid() = id);


-- 2. Create ACCOUNTS Table
CREATE TABLE IF NOT EXISTS public.accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_name TEXT NOT NULL,
  account_type TEXT NOT NULL DEFAULT 'bank', -- 'bank', 'cash', 'wallet', 'other'
  opening_balance NUMERIC NOT NULL DEFAULT 0.0,
  current_balance NUMERIC NOT NULL DEFAULT 0.0,
  color TEXT,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow individual select on accounts" ON public.accounts;
DROP POLICY IF EXISTS "Allow individual insert on accounts" ON public.accounts;
DROP POLICY IF EXISTS "Allow individual update on accounts" ON public.accounts;
DROP POLICY IF EXISTS "Allow individual delete on accounts" ON public.accounts;

CREATE POLICY "Allow individual select on accounts" ON public.accounts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow individual insert on accounts" ON public.accounts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual update on accounts" ON public.accounts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Allow individual delete on accounts" ON public.accounts FOR DELETE USING (auth.uid() = user_id);


-- 3. Create / Modify TRANSACTIONS Table
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID REFERENCES public.accounts(id) ON DELETE RESTRICT,
  type TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  transaction_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
  date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure columns exist if table was created in earlier version
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES public.accounts(id) ON DELETE RESTRICT;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS transaction_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow individual select on transactions" ON public.transactions;
DROP POLICY IF EXISTS "Allow individual insert on transactions" ON public.transactions;
DROP POLICY IF EXISTS "Allow individual update on transactions" ON public.transactions;
DROP POLICY IF EXISTS "Allow individual delete on transactions" ON public.transactions;

CREATE POLICY "Allow individual select on transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow individual insert on transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual update on transactions" ON public.transactions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Allow individual delete on transactions" ON public.transactions FOR DELETE USING (auth.uid() = user_id);


-- 4. Create EXPENSE_CATEGORIES Table
CREATE TABLE IF NOT EXISTS public.expense_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow individual select on expense_categories" ON public.expense_categories;
DROP POLICY IF EXISTS "Allow individual insert on expense_categories" ON public.expense_categories;
DROP POLICY IF EXISTS "Allow individual delete on expense_categories" ON public.expense_categories;

CREATE POLICY "Allow individual select on expense_categories" ON public.expense_categories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow individual insert on expense_categories" ON public.expense_categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual delete on expense_categories" ON public.expense_categories FOR DELETE USING (auth.uid() = user_id);


-- 5. Create INCOME_CATEGORIES Table
CREATE TABLE IF NOT EXISTS public.income_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.income_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow individual select on income_categories" ON public.income_categories;
DROP POLICY IF EXISTS "Allow individual insert on income_categories" ON public.income_categories;
DROP POLICY IF EXISTS "Allow individual delete on income_categories" ON public.income_categories;

CREATE POLICY "Allow individual select on income_categories" ON public.income_categories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow individual insert on income_categories" ON public.income_categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Allow individual delete on income_categories" ON public.income_categories FOR DELETE USING (auth.uid() = user_id);


-- 6. Create Storage Bucket for Profile Images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;
