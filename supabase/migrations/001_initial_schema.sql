-- Crystal Messenger - Supabase Initial Schema
-- This migration creates the core tables with Row Level Security

-- ============================================================
-- PROFILES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL DEFAULT '',
    profile_pic TEXT DEFAULT '',
    status TEXT DEFAULT '',
    is_online BOOLEAN DEFAULT false,
    last_seen TIMESTAMPTZ,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium')),
    privacy_mode TEXT DEFAULT 'public' CHECK (privacy_mode IN ('public', 'contacts', 'private')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles RLS policies
CREATE POLICY "Users can view profiles"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================================
-- CHATS TABLE (Rooms)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participants UUID[] NOT NULL DEFAULT '{}',
    last_message TEXT,
    last_message_time TIMESTAMPTZ,
    last_message_sender_id UUID REFERENCES public.profiles(id),
    unread_count INTEGER DEFAULT 0,
    is_group BOOLEAN DEFAULT false,
    group_name TEXT,
    group_image TEXT,
    is_broadcast BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

-- Chats RLS policies
CREATE POLICY "Users can view their chats"
    ON public.chats FOR SELECT
    USING (auth.uid() = ANY(participants));

CREATE POLICY "Users can create chats"
    ON public.chats FOR INSERT
    WITH CHECK (auth.uid() = ANY(participants));

CREATE POLICY "Users can update their chats"
    ON public.chats FOR UPDATE
    USING (auth.uid() = ANY(participants));

-- ============================================================
-- MESSAGES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'audio', 'file')),
    media_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    status TEXT DEFAULT 'sent' CHECK (status IN ('sending', 'sent', 'delivered', 'read')),
    is_deleted BOOLEAN DEFAULT false
);

-- Index for faster message queries
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_expires_at ON public.messages(expires_at);

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Messages RLS policies
CREATE POLICY "Users can view messages in their chats"
    ON public.messages FOR SELECT
    USING (
        auth.uid() IN (
            SELECT unnest(participants) FROM public.chats WHERE id = chat_id
        )
    );

CREATE POLICY "Users can send messages"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can delete their own messages"
    ON public.messages FOR UPDATE
    USING (auth.uid() = sender_id)
    WITH CHECK (auth.uid() = sender_id);

-- ============================================================
-- CALL SIGNALS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.call_signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caller_id UUID NOT NULL REFERENCES public.profiles(id),
    target_user_id UUID NOT NULL REFERENCES public.profiles(id),
    type TEXT NOT NULL CHECK (type IN ('audio_call', 'video_call')),
    status TEXT DEFAULT 'ringing' CHECK (status IN ('ringing', 'answered', 'declined', 'missed', 'ended')),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    duration_seconds INTEGER DEFAULT 0
);

-- Enable RLS
ALTER TABLE public.call_signals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their calls"
    ON public.call_signals FOR SELECT
    USING (auth.uid() = caller_id OR auth.uid() = target_user_id);

CREATE POLICY "Users can create call signals"
    ON public.call_signals FOR INSERT
    WITH CHECK (auth.uid() = caller_id);

-- ============================================================
-- AUTOMATIC TIMESTAMPS FUNCTION
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic updated_at
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_chats_updated_at
    BEFORE UPDATE ON public.chats
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();