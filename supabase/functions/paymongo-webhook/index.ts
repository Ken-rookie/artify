import { createClient } from "jsr:@supabase/supabase-js@2";

const respond = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const toHex = (bytes: Uint8Array) =>
  Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");

async function verifySignature(rawBody: string, header: string, secret: string) {
  const values = Object.fromEntries(
    header.split(",").map((part) => {
      const separator = part.indexOf("=");
      return [part.slice(0, separator).trim(), part.slice(separator + 1).trim()];
    }),
  );
  const timestamp = values.t;
  const signature = values.li ?? values.te;
  if (!timestamp || !signature) return false;
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 600) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${rawBody}`),
  );
  return toHex(new Uint8Array(digest)) === signature;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  const webhookSecret = Deno.env.get("PAYMONGO_WEBHOOK_SECRET");
  const signature = request.headers.get("Paymongo-Signature") ?? "";
  const rawBody = await request.text();
  if (!webhookSecret || !(await verifySignature(rawBody, signature, webhookSecret))) {
    return respond({ error: "Invalid webhook signature" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return respond({ error: "Webhook is not configured" }, 500);
  }

  try {
    const event = JSON.parse(rawBody);
    const attributes = event?.data?.attributes;
    const eventType = attributes?.type ?? event?.type;
    const sessionId = attributes?.data?.id;
    if (!sessionId) return respond({ received: true });

    const database = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    if (eventType === "checkout_session.payment.paid") {
      const { error } = await database
        .from("orders")
        .update({ status: "processing", payment_status: "paid" })
        .eq("paymongo_checkout_session_id", sessionId)
        .eq("status", "pending_payment")
        .eq("payment_status", "pending");
      if (error) throw error;
    } else if (eventType === "checkout_session.expired") {
      const { data: order, error } = await database
        .from("orders")
        .select("id")
        .eq("paymongo_checkout_session_id", sessionId)
        .maybeSingle();
      if (error) throw error;
      if (order) {
        const { error: cancelError } = await database.rpc(
          "cancel_pending_order",
          { p_order_id: order.id },
        );
        if (cancelError) throw cancelError;
      }
    }

    return respond({ received: true });
  } catch (error) {
    console.error("paymongo-webhook failed", error);
    return respond({ error: "Could not process webhook" }, 500);
  }
});