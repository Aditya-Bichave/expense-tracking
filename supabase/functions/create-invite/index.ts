import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { crypto } from 'https://deno.land/std@0.177.0/crypto/mod.ts'
import { encode as base64url } from 'https://deno.land/std@0.177.0/encoding/base64url.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const {
      group_id,
      role = 'member',
      expiry_days = 7,
      max_uses = 0,
    } = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )

    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: member, error: memberError } = await supabaseClient
      .from('group_members')
      .select('role')
      .eq('group_id', group_id)
      .eq('user_id', user.id)
      .single()

    if (memberError || !member || member.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden: Not an admin' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rawToken = crypto.randomUUID()
    const tokenHashBuffer = await crypto.subtle.digest(
      'SHA-256',
      new TextEncoder().encode(rawToken),
    )
    const tokenHash = base64url(new Uint8Array(tokenHashBuffer))

    const expiryDaysValue = Number(expiry_days)
    const expiresAt =
      Number.isFinite(expiryDaysValue) && expiryDaysValue > 0
        ? new Date(
            Date.now() + expiryDaysValue * 24 * 60 * 60 * 1000,
          ).toISOString()
        : new Date('9999-12-31T23:59:59.999Z').toISOString()

    const maxUsesValue = Math.max(0, Number(max_uses) || 0)
    const inviteRole = role === 'viewer' ? 'viewer' : role === 'admin' ? 'admin' : 'member'

    const { data, error } = await supabaseClient
      .from('group_invites')
      .insert({
        group_id,
        created_by: user.id,
        token_hash: tokenHash,
        role: inviteRole,
        expires_at: expiresAt,
        max_uses: maxUsesValue,
      })
      .select('id, group_id, role, expires_at, max_uses')
      .single()

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const publicAppUrl = Deno.env.get('PUBLIC_APP_URL')
    const joinBaseUrl =
      Deno.env.get('APP_JOIN_BASE_URL') ??
      (publicAppUrl ? `${publicAppUrl.replace(/\/$/, '')}/join` : null) ??
      'https://spendos.app/join'
    const separator = joinBaseUrl.includes('?') ? '&' : '?'
    const inviteUrl = `${joinBaseUrl}${separator}token=${encodeURIComponent(rawToken)}`

    return new Response(
      JSON.stringify({
        invite_url: inviteUrl,
        invite: data,
      }),
      {
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
