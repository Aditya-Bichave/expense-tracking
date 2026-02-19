import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { group_id } = await req.json()

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  const { data: { user } } = await supabaseClient.auth.getUser()
  if (!user) return new Response("Unauthorized", { status: 401 })

  const { data: member } = await supabaseClient
    .from('group_members')
    .select('role')
    .eq('group_id', group_id)
    .eq('user_id', user.id)
    .single()

  if (!member || member.role !== 'admin') {
    return new Response("Forbidden: Not an admin", { status: 403 })
  }

  const token = crypto.randomUUID()
  const expires_at = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()

  const { data, error } = await supabaseClient
    .from('invites')
    .insert({
      group_id,
      created_by: user.id,
      token,
      expires_at,
      max_uses: 100
    })
    .select()
    .single()

  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 })

  return new Response(JSON.stringify({ invite: data }), { headers: { "Content-Type": "application/json" } })
})
