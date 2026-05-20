-- Crystal Messenger schema for Supabase (Postgres)
-- Run this in your Supabase SQL editor.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

create table profiles (
  id uuid primary key DEFAULT uuid_generate_v4(),
  auth_id uuid references auth.users(id) ON DELETE CASCADE,
  email text UNIQUE,
  display_name text,
  avatar_url text,
  status_text text,
  phone text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table contacts (
  id uuid primary key DEFAULT uuid_generate_v4(),
  owner_id uuid references profiles(id) ON DELETE CASCADE,
  contact_profile_id uuid references profiles(id),
  phone text,
  name text,
  created_at timestamptz default now()
);

create table chats (
  id uuid primary key DEFAULT uuid_generate_v4(),
  is_group boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table chat_members (
  id uuid primary key DEFAULT uuid_generate_v4(),
  chat_id uuid references chats(id) ON DELETE CASCADE,
  profile_id uuid references profiles(id) ON DELETE CASCADE,
  joined_at timestamptz default now(),
  role text default 'member'
);

create table messages (
  id uuid primary key DEFAULT uuid_generate_v4(),
  chat_id uuid references chats(id) ON DELETE CASCADE,
  sender_id uuid references profiles(id) ON DELETE CASCADE,
  content text,
  message_type text default 'text',
  media_url text,
  media_meta jsonb,
  ephemeral boolean default false,
  created_at timestamptz default now()
);

create index on messages (chat_id, created_at desc);

create table message_statuses (
  id uuid primary key DEFAULT uuid_generate_v4(),
  message_id uuid references messages(id) ON DELETE CASCADE,
  profile_id uuid references profiles(id) ON DELETE CASCADE,
  delivered_at timestamptz,
  read_at timestamptz
);

create table typing_indicators (
  id uuid primary key DEFAULT uuid_generate_v4(),
  chat_id uuid references chats(id) ON DELETE CASCADE,
  profile_id uuid references profiles(id),
  is_typing boolean default false,
  updated_at timestamptz default now()
);

create table calls (
  id uuid primary key DEFAULT uuid_generate_v4(),
  call_sid text,
  chat_id uuid references chats(id),
  caller_id uuid references profiles(id),
  callee_id uuid references profiles(id),
  sdp_offer jsonb,
  sdp_answer jsonb,
  status text default 'initiated',
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz default now()
);

create or replace function update_updated_at_column()
returns trigger as $$
begin
   NEW.updated_at = now();
   return NEW;
end;
$$ language 'plpgsql';

create trigger set_chats_updated_at
before update on chats
for each row execute procedure update_updated_at_column();

create trigger set_profiles_updated_at
before update on profiles
for each row execute procedure update_updated_at_column();
