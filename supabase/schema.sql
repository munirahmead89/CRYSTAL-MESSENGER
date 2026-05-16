-- Crystal Messenger - Database Schema
-- Version: 2.1.0

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ENUMS
CREATE TYPE profile_privacy AS ENUM ('public', 'contacts', 'private');
CREATE TYPE room_type AS ENUM ('direct', 'group');
CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'audio', 'document', 'system');
CREATE TYPE contact_status AS ENUM ('pending', 'accepted', 'blocked');

-- 2. TABLES

-- Profiles Table (Extends auth.users)
CREATE TABLE profiles (
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
CREATE TABLE rooms (
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
CREATE TABLE participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'admin', 'member'
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

-- Messages Table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  text_content TEXT,
  media_url TEXT,
  type message_type DEFAULT 'text',
  metadata JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ -- For disappearing messages
);

-- Contacts Table
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  alias TEXT,
  status contact_status DEFAULT 'accepted',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, contact_id)
);

-- 3. RLS POLICIES

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Profile Policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Room Policies
CREATE POLICY "Users can view rooms they are in" ON rooms
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM participants
      WHERE participants.room_id = rooms.id
      AND participants.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create rooms" ON rooms
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Participant Policies
CREATE POLICY "Users can view participants of their rooms" ON participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM participants p2
      WHERE p2.room_id = participants.room_id
      AND p2.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join/add to rooms" ON participants
  FOR INSERT WITH CHECK (true);

-- Message Policies
CREATE POLICY "Users can view messages in their rooms" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM participants
      WHERE participants.room_id = messages.room_id
      AND participants.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert messages into their rooms" ON messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM participants
      WHERE participants.room_id = messages.room_id
      AND participants.user_id = auth.uid()
    )
  );

-- Contact Policies
CREATE POLICY "Users can view own contacts" ON contacts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own contacts" ON contacts
  FOR ALL USING (auth.uid() = user_id);

-- 4. FUNCTIONS & TRIGGERS

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
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
  SELECT room_id INTO found_room_id
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

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. REALTIME
-- Enable Realtime for specific tables
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE participants;


