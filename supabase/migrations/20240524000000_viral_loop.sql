-- Drop existing invites table to recreate with new schema
DROP TABLE IF EXISTS invites;

-- Create group_invites table
CREATE TABLE group_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    token_hash TEXT UNIQUE NOT NULL,
    role member_role DEFAULT 'member'::member_role,
    created_by UUID NOT NULL REFERENCES profiles(user_id),
    expires_at TIMESTAMPTZ NOT NULL,
    max_uses INT DEFAULT 0, -- 0 means unlimited
    uses_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE group_invites ENABLE ROW LEVEL SECURITY;

-- Policy: Admins manage invites
-- Only users who are admins of the group can SELECT/INSERT/UPDATE/DELETE
CREATE POLICY "Admins manage invites" ON group_invites
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM group_members
            WHERE group_members.group_id = group_invites.group_id
            AND group_members.user_id = auth.uid()
            AND group_members.role = 'admin'
        )
    );

-- Enforce created_by is current user on INSERT
-- (Supabase might need explicit CHECK for this in policy or trigger, but POLICY WITH CHECK is good)
-- The above "ALL" policy covers INSERT WITH CHECK as well.

-- Update group_members policies for Admin powers
-- Admin can UPDATE roles
CREATE POLICY "Admins can update member roles" ON group_members
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM group_members AS admin_check
            WHERE admin_check.group_id = group_members.group_id
            AND admin_check.user_id = auth.uid()
            AND admin_check.role = 'admin'
        )
    );

-- Admin can DELETE members (Kick)
CREATE POLICY "Admins can kick members" ON group_members
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM group_members AS admin_check
            WHERE admin_check.group_id = group_members.group_id
            AND admin_check.user_id = auth.uid()
            AND admin_check.role = 'admin'
        )
    );

-- User can DELETE own membership (Leave)
-- Placeholder: In future check for balance=0
CREATE POLICY "Users can leave group" ON group_members
    FOR DELETE
    USING (
        user_id = auth.uid()
    );

-- Function to handle new user profile creation if not exists
-- (Refining the existing one if needed, but 'handle_new_user' exists in previous migrations)
-- Ensuring it covers anonymous users too (auth.users inserts usually trigger it)

-- Create function to atomically increment invite uses
CREATE OR REPLACE FUNCTION increment_invite_uses(invite_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE group_invites
    SET uses_count = uses_count + 1,
        updated_at = NOW()
    WHERE id = invite_id;
END;
$$;
