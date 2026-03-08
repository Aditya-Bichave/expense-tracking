import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Helper to generate a Google OAuth2 token using djwt and the service account key
async function getFirebaseAccessToken(serviceAccount: any): Promise<string> {
  const iat = getNumericDate(0);
  const exp = getNumericDate(3600); // 1 hour expiration

  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: "https://oauth2.googleapis.com/token",
      exp,
      iat,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    },
    serviceAccount.private_key
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Failed to generate Google access token: ${text}`);
  }

  const data = await response.json();
  return data.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { to_user_id, group_id, amount_owed, currency, group_name } = await req.json();

    if (!to_user_id || !group_id || amount_owed === undefined || !currency) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    if (amount_owed <= 0) {
      return new Response(JSON.stringify({ error: "Invalid amount" }), {
        status: 400,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    // 1. Setup Supabase Client (Service Role to bypass RLS for logs)
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
        throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Get Caller ID from JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));

    if (authError || !user) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const from_user_id = user.id;

    if (from_user_id === to_user_id) {
       return new Response(JSON.stringify({ error: "Cannot nudge yourself" }), {
        status: 400,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    // Verify both users are in the group
    const { data: senderMember, error: senderError } = await supabase
      .from("group_members")
      .select("id")
      .eq("group_id", group_id)
      .eq("user_id", from_user_id)
      .single();

    if (senderError || !senderMember) {
      return new Response(JSON.stringify({ error: "Sender not in group" }), {
        status: 403,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    const { data: targetMember, error: targetError } = await supabase
      .from("group_members")
      .select("id")
      .eq("group_id", group_id)
      .eq("user_id", to_user_id)
      .single();

    if (targetError || !targetMember) {
      return new Response(JSON.stringify({ error: "Target not in group" }), {
        status: 403,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    // 3. RATE LIMIT CHECK (Critical)
    const { data: lastNudge, error: nudgeQueryError } = await supabase
      .from("nudge_logs")
      .select("created_at")
      .eq("from_user_id", from_user_id)
      .eq("to_user_id", to_user_id)
      .eq("group_id", group_id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (lastNudge) {
      const hoursSinceNudge =
        (new Date().getTime() - new Date(lastNudge.created_at).getTime()) /
        (1000 * 60 * 60);
      if (hoursSinceNudge < 24) {
        return new Response(
          JSON.stringify({ error: "Rate limit exceeded. Try again tomorrow." }),
          {
            status: 429,
            headers: { "Content-Type": "application/json", ...corsHeaders },
          }
        );
      }
    }

    // 4. Fetch Target User's FCM Tokens
    const { data: tokens, error: tokensError } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token")
      .eq("user_id", to_user_id);

    if (tokensError) {
      console.error("Tokens Query Error:", tokensError);
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ error: "User has no registered devices." }),
        {
          status: 404,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    // 5. Generate Firebase Access Token
    const serviceAccountJsonStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJsonStr) {
       console.error("FIREBASE_SERVICE_ACCOUNT secret missing");
       return new Response(JSON.stringify({ error: "Internal Configuration Error" }), {
          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders },
       });
    }

    const serviceAccount = JSON.parse(serviceAccountJsonStr);
    const accessToken = await getFirebaseAccessToken(serviceAccount);

    // 6. Format Friendly Notification
    // Fetch sender name for personalization
    const { data: senderProfile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", from_user_id)
      .maybeSingle();

    const senderName = senderProfile?.full_name || "A group member";
    const displayGroupName = group_name || "the group";

    const fcmPayloadBase = {
      message: {
        notification: {
          title: `Catching up on ${displayGroupName}!`,
          body: `${senderName} sent a gentle reminder to settle your balance of ${currency} ${amount_owed}. Tap to clear it easily.`,
        },
        data: {
          group_id: group_id, // Deep linking payload
          type: "NUDGE",
        },
      },
    };

    let successfulDispatch = false;

    // 7. Dispatch to FCM (Loop through all user devices)
    for (const t of tokens) {
      const payload = JSON.parse(JSON.stringify(fcmPayloadBase));
      payload.message.token = t.fcm_token;

      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        }
      );

      // 8. Hygiene: Delete dead tokens
      if (!response.ok) {
        const errorData = await response.json();
        const status = errorData.error?.status;
        if (status === "UNREGISTERED" || status === "NOT_FOUND" || status === "INVALID_ARGUMENT") {
           console.log(`Pruning invalid/dead token: ${t.fcm_token.substring(0, 10)}... (Status: ${status})`);
           await supabase
             .from("user_fcm_tokens")
             .delete()
             .eq("fcm_token", t.fcm_token);
        } else {
           console.error(`FCM dispatch failed with status ${status}:`, errorData);
        }
      } else {
        successfulDispatch = true;
      }
    }

    if (!successfulDispatch) {
        return new Response(JSON.stringify({ error: "Failed to dispatch notification to any device." }), {
            status: 500,
            headers: { "Content-Type": "application/json", ...corsHeaders }
        });
    }

    // 9. Audit Log the Nudge
    const { error: logError } = await supabase.from("nudge_logs").insert({
      group_id,
      from_user_id,
      to_user_id,
      amount_owed,
      currency,
    });

    if (logError) {
        console.error("Failed to insert nudge log:", logError);
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: any) {
    console.error("Unexpected error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
