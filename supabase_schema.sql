-- ==========================================================
-- DUOCHAT - SUPABASE DATABASE SCHEMA (FOR 2 PEOPLE TEXT CHAT)
-- Copy and paste this into Supabase SQL Editor
-- ==========================================================

-- 1. Create Profiles Table (User 1 and User 2)
CREATE TABLE IF NOT EXISTS public.profiles (
  id TEXT PRIMARY KEY,
  pair_code TEXT NOT NULL DEFAULT 'DUO2026',
  name TEXT NOT NULL,
  avatar_url TEXT,
  status_message TEXT DEFAULT 'Hey there! I am using DuoChat.',
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_typing BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Default 2-Person Pair Profiles
INSERT INTO public.profiles (id, pair_code, name, status_message)
VALUES 
  ('user_a', 'DUO2026', 'Partner 1', 'Always here for you ❤️'),
  ('user_b', 'DUO2026', 'Partner 2', 'Texting on DuoChat 💬')
ON CONFLICT (id) DO NOTHING;

-- 2. Create Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
  id TEXT PRIMARY KEY,
  pair_code TEXT NOT NULL DEFAULT 'DUO2026',
  sender_id TEXT NOT NULL REFERENCES public.profiles(id),
  receiver_id TEXT NOT NULL REFERENCES public.profiles(id),
  content TEXT NOT NULL,
  reaction TEXT,
  reply_to_id TEXT,
  reply_to_content TEXT,
  status TEXT NOT NULL DEFAULT 'sent', -- 'sent', 'delivered', 'read'
  is_starred BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Indexes for fast real-time querying
CREATE INDEX IF NOT EXISTS idx_messages_pair_code ON public.messages(pair_code);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- 4. Enable Supabase Realtime for Messages & Profiles
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- 5. Row Level Security (RLS) Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous full access for DuoChat" ON public.profiles FOR ALL USING (true);
CREATE POLICY "Allow anonymous full access for DuoChat Messages" ON public.messages FOR ALL USING (true);
