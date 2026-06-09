// supabase/functions/create-razorpay-order/index.ts
//
// Creates a Razorpay order server-side. The KEY_SECRET never leaves this function.
// Called by the Flutter app before opening the Razorpay checkout sheet.
//
// Required Supabase secrets (set via: supabase secrets set KEY=VALUE):
//   RAZORPAY_KEY_ID
//   RAZORPAY_KEY_SECRET

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  // Require authenticated user
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: { amount: number; currency?: string; receipt?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { amount, currency = "INR", receipt } = body;

  if (!amount || amount < 100) {
    return new Response(JSON.stringify({ error: "Amount must be at least 100 paise" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const keyId     = Deno.env.get("RAZORPAY_KEY_ID")!;
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET")!;
  const credentials = btoa(`${keyId}:${keySecret}`);

  const razorpayRes = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount,
      currency,
      receipt: receipt ?? `rcpt_${user.id.slice(0, 8)}_${Date.now()}`,
    }),
  });

  if (!razorpayRes.ok) {
    const err = await razorpayRes.json().catch(() => ({}));
    console.error("Razorpay order creation failed:", err);
    return new Response(JSON.stringify({ error: "Failed to create order" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const order = await razorpayRes.json();

  return new Response(
    JSON.stringify({
      order_id: order.id,
      amount:   order.amount,
      currency: order.currency,
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
});
