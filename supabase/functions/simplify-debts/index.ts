import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { simplifyDebts, UserBalance } from "./simplify.ts"

serve(async (req) => {
  try {
    const url = new URL(req.url);
    const groupId = url.searchParams.get('group_id');

    if (!groupId) {
      return new Response(JSON.stringify({ error: "Missing group_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { "Content-Type": "application/json" }
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: { headers: { Authorization: authHeader } },
      }
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
       return new Response(JSON.stringify({ error: "Unauthorized" }), {
         status: 401,
         headers: { "Content-Type": "application/json" }
       });
    }
    const callerId = user.id;

    // Fetch raw balances from Postgres View
    // RLS protects this call because the view uses security_invoker = true
    const { data: balances, error } = await supabase
      .from('group_net_balances')
      .select('*')
      .eq('group_id', groupId);

    if (error) {
      console.error('Supabase error:', error);
      return new Response(JSON.stringify({ error: "Failed to fetch balances" }), {
        status: 500,
        headers: { "Content-Type": "application/json" }
      });
    }

    if (!balances || balances.length === 0) {
      return new Response(JSON.stringify({
        my_net_balance: 0,
        simplified_debts: []
      }), {
        headers: { "Content-Type": "application/json" }
      });
    }

    // Convert balances into the expected input format
    const parsedBalances: UserBalance[] = balances.map(b => ({
      user_id: b.user_id,
      user_name: b.user_name,
      to_user_upi: b.to_user_upi,
      // net_balance might come as string or number depending on Postgrest mapping
      net_balance: parseFloat(b.net_balance),
    }));

    // Find caller's net balance
    const callerBalance = parsedBalances.find(b => b.user_id === callerId);
    // Use Number() / parseFloat() to avoid string serialization if JS treats it differently
    const myNetBalance = callerBalance ? Number(callerBalance.net_balance) : 0;

    const instructions = simplifyDebts(parsedBalances);

    return new Response(JSON.stringify({
      my_net_balance: myNetBalance,
      simplified_debts: instructions
    }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  } catch (e) {
    console.error('Internal Error:', e);
    return new Response(JSON.stringify({ error: "Internal Server Error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});
