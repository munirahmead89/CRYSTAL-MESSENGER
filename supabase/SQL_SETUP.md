# Crystal Messenger - Supabase Backend Setup

Follow these steps to fully "stitch" the backend and make the app work instantly.

## 1. SQL Setup
Go to your **Supabase Project -> SQL Editor -> New Query**.
Paste the entire content of [schema.sql](./schema.sql) and click **Run**.

This will:
- Create all tables (`profiles`, `rooms`, `participants`, `messages`, `contacts`).
- Enable Row Level Security (RLS) with optimized policies.
- Set up a trigger to automatically create a profile when a user signs up.
- Add a helper function (`get_direct_room`) for instant chat creation.
- Enable Realtime for all messaging tables.

## 2. Environment Variables
1. Copy `.env.template` to `.env`.
2. Replace the following with your Supabase values (found in **Project Settings -> API**):
   ```env
   SUPABASE_URL=your_project_url
   SUPABASE_ANON_KEY=your_anon_key
   ```

## 3. Realtime Configuration
Ensure that **Broadcast** and **Presence** are enabled in your Supabase dashboard for the tables mentioned in the schema. This is usually handled by the SQL script, but double-check the "Realtime" section in the Supabase Dashboard.

## 4. Auth Settings
- Go to **Authentication -> Providers**.
- Ensure **Email** and **Phone** (if needed) are enabled.
- Disable **Confirm Email** for instant testing during development.

---
**Done!** Your Crystal Messenger is now fully connected to a production-ready Supabase backend.
