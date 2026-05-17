-- Crystal Messenger - Production Database Schema
-- Version: 3.0.0
-- Developed by Munir Waheed, Principal Architect

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ENUMS
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'profile_privacy') THEN
    CREATE TYPE profile_privacy AS ENUM ('public', 'contacts', 'private');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'room_type') THEN
    CREATE TYPE room_type AS ENUM ('direct', 'group');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'message_type') THEN
    CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'audio', 'document', 'system');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'contact_status') THEN
    CREATE TYPE contact_status AS ENUM ('pending', 'accepted', 'blocked');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'call_status') THEN
    CREATE TYPE call_status AS ENUM ('dialing', 'ringing', 'connected', 'ended', 'rejected');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'call_type') THEN
    CREATE TYPE call_type AS ENUM ('audio', 'video');
  END IF;
END$$;

-- 2. TABLES

-- Profiles Table (Extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  phone TEXT UNIQUE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  status TEXT DEFAULT 'Hey there! I am using Crystal Messenger.',
  profile_card_privacy profile_privacy DEFAULT 'public',
  is_premium BOOLEAN DEFAULT false,
  custom_ringtone_url TEXT,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  is_online BOOLEAN DEFAULT false,
  push_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rooms/Chats Table
CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type room_type NOT NULL,
  name TEXT, -- For groups
  description TEXT,
  avatar_url TEXT,
  created_by UUID REFERENCES profiles(id),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Participants Table
CREATE TABLE IF NOT EXISTS participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'admin', 'member'
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

-- Messages Table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  text_content TEXT,
  media_url TEXT,
  type message_type DEFAULT 'text',
  metadata JSONB DEFAULT '{}'::jsonb,
  is_delivered BOOLEAN DEFAULT false,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ -- For disappearing messages
);

-- Contacts Table
CREATE TABLE IF NOT EXISTS contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  alias TEXT,
  status contact_status DEFAULT 'accepted',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, contact_id)
);

-- Typing Indicators Table
CREATE TABLE IF NOT EXISTS typing_indicators (
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

-- WebRTC Call Sessions Table (Signaling Server)
CREATE TABLE IF NOT EXISTS call_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  caller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type call_type NOT NULL,
  status call_status DEFAULT 'dialing',
  sdp_offer JSONB,
  sdp_answer JSONB,
  ice_candidates_caller JSONB DEFAULT '[]'::jsonb,
  ice_candidates_receiver JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RLS POLICIES

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;

-- Profile Policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Room Policies
DROP POLICY IF EXISTS "Users can view rooms they are in" ON rooms;
CREATE POLICY "Users can view rooms they are in" ON rooms FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.room_id = rooms.id
    AND participants.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can create rooms" ON rooms;
CREATE POLICY "Users can create rooms" ON rooms FOR INSERT WITH CHECK (auth.uid() = created_by OR created_by IS NULL);

-- Participant Policies
DROP POLICY IF EXISTS "Users can view participants of their rooms" ON participants;
CREATE POLICY "Users can view participants of their rooms" ON participants FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM participants p2
    WHERE p2.room_id = participants.room_id
    AND p2.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can join/add to rooms" ON participants;
CREATE POLICY "Users can join/add to rooms" ON participants FOR INSERT WITH CHECK (true);

-- Message Policies
DROP POLICY IF EXISTS "Users can view messages in their rooms" ON messages;
CREATE POLICY "Users can view messages in their rooms" ON messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.room_id = messages.room_id
    AND participants.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can insert messages into their rooms" ON messages;
CREATE POLICY "Users can insert messages into their rooms" ON messages FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.room_id = messages.room_id
    AND participants.user_id = auth.uid()
  )
);

-- Contact Policies
DROP POLICY IF EXISTS "Users can view own contacts" ON contacts;
CREATE POLICY "Users can view own contacts" ON contacts FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own contacts" ON contacts;
CREATE POLICY "Users can manage own contacts" ON contacts FOR ALL USING (auth.uid() = user_id);

-- Typing Indicator Policies
DROP POLICY IF EXISTS "Users can view typing indicators of their rooms" ON typing_indicators;
CREATE POLICY "Users can view typing indicators of their rooms" ON typing_indicators FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.room_id = typing_indicators.room_id
    AND participants.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can manage own typing indicator" ON typing_indicators;
CREATE POLICY "Users can manage own typing indicator" ON typing_indicators FOR ALL USING (auth.uid() = user_id);

-- Call Session Policies
DROP POLICY IF EXISTS "Users can view own calls" ON call_sessions;
CREATE POLICY "Users can view own calls" ON call_sessions FOR SELECT USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can manage own calls" ON call_sessions;
CREATE POLICY "Users can manage own calls" ON call_sessions FOR ALL USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- 4. FUNCTIONS & TRIGGERS

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, full_name, avatar_url, username, status)
  VALUES (
    NEW.id,
    NEW.phone,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.raw_user_meta_data->>'avatar_url',
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    'Hey there! I am using Crystal Messenger.'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RPC for finding or creating a direct chat room between two users
CREATE OR REPLACE FUNCTION get_direct_room(user1 UUID, user2 UUID)
RETURNS JSONB AS $$
DECLARE
  found_room_id UUID;
  room_data JSONB;
BEGIN
  SELECT p1.room_id INTO found_room_id
  FROM participants p1
  JOIN participants p2 ON p1.room_id = p2.room_id
  JOIN rooms r ON p1.room_id = r.id
  WHERE r.type = 'direct'
    AND p1.user_id = user1
    AND p2.user_id = user2
  LIMIT 1;

  IF found_room_id IS NOT NULL THEN
    SELECT row_to_json(r)::jsonb INTO room_data FROM rooms r WHERE id = found_room_id;
    RETURN room_data;
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_rooms_updated_at ON rooms;
CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_call_sessions_updated_at ON call_sessions;
CREATE TRIGGER update_call_sessions_updated_at BEFORE UPDATE ON call_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. REALTIME
-- Enable Realtime for all interactive tables
-- Handled by Supabase publication updates
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;

ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE participants;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;
ALTER PUBLICATION supabase_realtime ADD TABLE call_sessions;
