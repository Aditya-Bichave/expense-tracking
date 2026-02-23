import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";
import { encode as base64url } from "https://deno.land/std@0.177.0/encoding/base64url.ts";

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Artificial delay to mitigate brute-force timing attacks (1 second)
  await new Promise(resolve => setTimeout(resolve, 1000));

  try {
    const { token } = await req.json()
    if (!token) throw new Error('Missing token')

    // Initialize Supabase Admin client (Service Role) to bypass RLS for invite lookup & member insertion
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Verify user from Authorization header
    const authHeader = req.headers.get('Authorization')!
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Hash token to lookup
    const tokenHashBuffer = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
    const tokenHash = base64url(new Uint8Array(tokenHashBuffer));

    // Find invite
    const { data: invite, error: inviteError } = await supabaseAdmin
      .from('group_invites')
      .select('*')
      .eq('token_hash', tokenHash)
      .single()

    if (inviteError || !invite) {
      return new Response(JSON.stringify({ error: 'Invalid or expired invite' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Check expiry
    if (new Date(invite.expires_at) < new Date()) {
      return new Response(JSON.stringify({ error: 'Invite expired' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Check usage limit
    if (invite.max_uses > 0 && invite.uses_count >= invite.max_uses) {
      return new Response(JSON.stringify({ error: 'Invite limit reached' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Check if already a member
    const { data: existingMember } = await supabaseAdmin
      .from('group_members')
      .select('id, role')
      .eq('group_id', invite.group_id)
      .eq('user_id', user.id)
      .maybeSingle()

    if (existingMember) {
      // Already member, just return success + group info
       const { data: group } = await supabaseAdmin
        .from('groups')
        .select('id, name')
        .eq('id', invite.group_id)
        .single()

      return new Response(JSON.stringify({
        message: 'Already a member',
        group_id: invite.group_id,
        group_name: group?.name,
        role: existingMember.role
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      })
    }

    // Add to group
    const { error: insertError } = await supabaseAdmin
      .from('group_members')
      .insert({
        group_id: invite.group_id,
        user_id: user.id,
        role: invite.role
      })

    if (insertError) throw insertError

    // Increment usage atomically via RPC
    await supabaseAdmin.rpc('increment_invite_uses', { invite_id: invite.id })

    // Get group info for UI
    const { data: group } = await supabaseAdmin
        .from('groups')
        .select('id, name')
        .eq('id', invite.group_id)
        .single()

    return new Response(JSON.stringify({
      message: 'Joined group successfully',
      group_id: invite.group_id,
      group_name: group?.name,
      role: invite.role
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400
    })
  }
})
