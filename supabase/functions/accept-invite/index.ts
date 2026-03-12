import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { crypto } from 'https://deno.land/std@0.177.0/crypto/mod.ts'
import { encode as base64url } from 'https://deno.land/std@0.177.0/encoding/base64url.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  await new Promise((resolve) => setTimeout(resolve, 1000))

  try {
    const { token } = await req.json()
    if (!token) {
      throw new Error('Missing token')
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const {
      data: { user },
      error: userError,
    } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const tokenHashBuffer = await crypto.subtle.digest(
      'SHA-256',
      new TextEncoder().encode(token),
    )
    const tokenHash = base64url(new Uint8Array(tokenHashBuffer))

    const { data: invite, error: inviteError } = await supabaseAdmin
      .from('group_invites')
      .select('*')
      .eq('token_hash', tokenHash)
      .single()

    if (inviteError || !invite) {
      return new Response(JSON.stringify({ error: 'Invalid or expired invite' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (new Date(invite.expires_at) < new Date()) {
      return new Response(JSON.stringify({ error: 'Invite expired' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (invite.max_uses > 0 && invite.uses_count >= invite.max_uses) {
      return new Response(JSON.stringify({ error: 'Invite limit reached' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: existingMember } = await supabaseAdmin
      .from('group_members')
      .select('id, role')
      .eq('group_id', invite.group_id)
      .eq('user_id', user.id)
      .maybeSingle()

    const { data: group } = await supabaseAdmin
      .from('groups')
      .select('id, name')
      .eq('id', invite.group_id)
      .single()

    if (existingMember) {
      return new Response(
        JSON.stringify({
          message: 'Already a member',
          group_id: invite.group_id,
          group_name: group?.name,
          role: existingMember.role,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      )
    }

    const { error: insertError } = await supabaseAdmin.from('group_members').insert({
      group_id: invite.group_id,
      user_id: user.id,
      role: invite.role,
    })

    if (insertError) {
      throw insertError
    }

    await supabaseAdmin.rpc('increment_invite_uses', { invite_id: invite.id })

    return new Response(
      JSON.stringify({
        message: 'Joined group successfully',
        group_id: invite.group_id,
        group_name: group?.name,
        role: invite.role,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
