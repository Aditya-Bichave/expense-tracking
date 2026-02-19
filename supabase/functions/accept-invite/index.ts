import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { token } = await req.json()

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )

  const authHeader = req.headers.get('Authorization')!
  const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''))

  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
  }

  const { data: invite, error: inviteError } = await supabaseClient
    .from('invites')
    .select('*')
    .eq('token', token)
    .single()

  if (inviteError || !invite) {
    return new Response(JSON.stringify({ error: 'Invalid invite' }), { status: 404 })
  }

  if (new Date(invite.expires_at) < new Date()) {
    return new Response(JSON.stringify({ error: 'Invite expired' }), { status: 400 })
  }
  if (invite.max_uses && invite.uses_count >= invite.max_uses) {
    return new Response(JSON.stringify({ error: 'Invite max uses reached' }), { status: 400 })
  }

  const { data: existingMember } = await supabaseClient
    .from('group_members')
    .select('id')
    .eq('group_id', invite.group_id)
    .eq('user_id', user.id)
    .maybeSingle()

  if (existingMember) {
    return new Response(JSON.stringify({ message: 'Already a member' }), { status: 200 })
  }

  const { error: memberError } = await supabaseClient
    .from('group_members')
    .insert({
      group_id: invite.group_id,
      user_id: user.id,
      role: 'member'
    })

  if (memberError) {
    return new Response(JSON.stringify({ error: memberError.message }), { status: 500 })
  }

  await supabaseClient
    .from('invites')
    .update({ uses_count: invite.uses_count + 1 })
    .eq('id', invite.id)

  return new Response(JSON.stringify({ message: 'Joined group successfully', group_id: invite.group_id }), { headers: { "Content-Type": "application/json" } })
})
