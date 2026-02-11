# Database Authentication Setup

## Current Setup: Device-Based Users (No Auth)

The app uses device-based UUIDs for user identification while Apple Developer Program is not active.

### How It Works

1. **Device UUID Generation**: Each device gets a unique UUID stored in Keychain
2. **User Creation**: On app launch, user profile is created in `public.users` table
3. **Data Storage**: Journal entries, evaluations stored with device UUID as `user_id`

### Database Tables

```sql
-- Device-based users table
CREATE TABLE public.users (
    id UUID PRIMARY KEY,
    email TEXT,
    name TEXT DEFAULT 'User',
    apple_user_id UUID,           -- For future Apple Auth linking
    auth_provider TEXT DEFAULT 'device',  -- 'device' or 'apple'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies (permissive for device users)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous insert" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow read own data" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow update own data" ON public.users FOR UPDATE USING (true);
```

---

## Future Setup: Apple Sign In

When Apple Developer Program is activated:

### Changes Required

1. **Enable Supabase Auth**
   - Configure Apple provider in Supabase Dashboard
   - Apple Auth users stored in `auth.users` (Supabase built-in)

2. **Update RLS Policies**
   ```sql
   -- Switch to auth-based policies
   DROP POLICY "Allow anonymous insert" ON public.users;
   CREATE POLICY "Authenticated insert" ON public.users 
       FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
   ```

3. **Link Device Users to Apple Auth**
   ```swift
   // In app: when user signs in with Apple
   func linkDeviceToAppleAuth(deviceUserId: UUID, appleUserId: UUID) {
       // Update public.users.apple_user_id
       // Migrate journal_entries.user_id to Apple UUID
       // Migrate journal_evaluations.user_id to Apple UUID
   }
   ```

### Migration Script

```sql
-- Run when migrating a device user to Apple Auth
UPDATE public.users 
SET apple_user_id = 'APPLE_AUTH_UUID', 
    auth_provider = 'apple'
WHERE id = 'DEVICE_UUID';

-- Update all related data
UPDATE journal_entries SET user_id = 'APPLE_AUTH_UUID' WHERE user_id = 'DEVICE_UUID';
UPDATE journal_evaluations SET user_id = 'APPLE_AUTH_UUID' WHERE user_id = 'DEVICE_UUID';
```

---

## Quick Reference

| State | User ID Source | Auth Provider |
|-------|---------------|---------------|
| Development (now) | Device Keychain UUID | `device` |
| Production (future) | Apple Auth UUID | `apple` |

### Logs to Watch

```
✅ User profile created in Supabase: <UUID>  -- Success
ℹ️ User profile already exists: <UUID>        -- Already registered
⚠️ Could not create user in Supabase          -- Check RLS/table
```
