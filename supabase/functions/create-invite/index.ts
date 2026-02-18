import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { group_id, max_uses } = await req.json()
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  // RLS will handle the permission check if we use the auth context correctly
  // But for admin check on invite creation, we might need to rely on the RLS policy we set:
  // "Admins can create invites." -> checked against group_members.

  const { data, error } = await supabaseClient
    .from('invites')
    .insert({
      group_id,
      created_by: (await supabaseClient.auth.getUser()).data.user?.id,
      token: crypto.randomUUID(),
      max_uses: max_uses || 1
    })
    .select()
    .single()

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 })
  }

  return new Response(JSON.stringify(data), { headers: { 'Content-Type': 'application/json' } })
})
