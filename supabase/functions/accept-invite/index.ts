import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { token } = await req.json()
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Use service role to bypass RLS for invite lookup if needed, or stick to user context
  )

  // We probably want to use the user's auth context for the membership insertion,
  // but for checking the invite validity and incrementing usage, we might need elevated privileges
  // or specific RLS.
  // The requirements said "Use Edge Function for token validation + membership insert".

  // Let's use service role for the heavy lifting to ensure atomicity and permission overrides where strictly needed
  // but we must validate the user is authenticated.

  const authHeader = req.headers.get('Authorization')!
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } }
  )

  const { data: { user }, error: userError } = await userClient.auth.getUser()
  if (userError || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })

  // 1. Validate Invite
  // We use service role client here to read invites even if user is not a member yet
  // (Assuming invites table is not public readable)
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { data: invite, error: inviteError } = await adminClient
    .from('invites')
    .select('*')
    .eq('token', token)
    .single()

  if (inviteError || !invite) {
    return new Response(JSON.stringify({ error: 'Invalid token' }), { status: 400 })
  }

  if (invite.max_uses && invite.uses_count >= invite.max_uses) {
    return new Response(JSON.stringify({ error: 'Invite expired' }), { status: 400 })
  }

  // 2. Add Member
  const { error: memberError } = await adminClient
    .from('group_members')
    .insert({
      group_id: invite.group_id,
      user_id: user.id,
      role: 'member'
    })

  if (memberError) {
    // Check if already member
    if (memberError.code === '23505') { // Unique violation
       return new Response(JSON.stringify({ message: 'Already a member' }), { status: 200 })
    }
    return new Response(JSON.stringify({ error: memberError.message }), { status: 400 })
  }

  // 3. Increment usage
  await adminClient
    .from('invites')
    .update({ uses_count: invite.uses_count + 1 })
    .eq('id', invite.id)

  return new Response(JSON.stringify({ success: true, group_id: invite.group_id }), { headers: { 'Content-Type': 'application/json' } })
})
