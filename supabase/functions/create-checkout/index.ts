import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type CheckoutInput = {
  customerName: string;
  phone: string;
  address: string;
  paymentMethod: "cod" | "paymongo";
  items: { productId: string; quantity: number }[];
};

type CreatedOrder = {
  order_id: string;
  access_token: string;
  subtotal: number;
  shipping_fee: number;
  total_amount: number;
};

const respond = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return respond({ error: "Order service is not configured" }, 500);
  }

  const database = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  let reservedOrderId: string | null = null;

  try {
    const authorization = request.headers.get("Authorization");
    const accessToken = authorization?.replace(/^Bearer\s+/i, "");
    if (!accessToken) {
      return respond({ error: "Sign in before placing an order" }, 401);
    }

    const { data: authData, error: authError } = await database.auth.getUser(accessToken);
    if (authError || !authData.user) {
      return respond({ error: "Your session has expired. Sign in and try again." }, 401);
    }

    const input = await request.json() as CheckoutInput;
    if (
      typeof input.customerName !== "string" ||
      typeof input.phone !== "string" ||
      typeof input.address !== "string" ||
      !["cod", "paymongo"].includes(input.paymentMethod) ||
      !Array.isArray(input.items) ||
      input.items.length === 0 ||
      input.items.length > 50
    ) {
      return respond({ error: "Invalid checkout request" }, 400);
    }

    const { data, error } = await database.rpc("create_order", {
      p_user_id: authData.user.id,
      p_customer_name: input.customerName,
      p_phone: input.phone,
      p_address: input.address,
      p_payment_method: input.paymentMethod,
      p_items: input.items.map((item) => ({
        product_id: item.productId,
        quantity: item.quantity,
      })),
    });
    if (error) return respond({ error: error.message }, 409);

    const order = data as CreatedOrder;
    reservedOrderId = order.order_id;

    if (input.paymentMethod === "cod") {
      return respond({
        orderId: order.order_id,
        accessToken: order.access_token,
        paymentMethod: "cod",
        status: "processing",
        totalAmount: order.total_amount,
      });
    }

    const secretKey = Deno.env.get("PAYMONGO_SECRET_KEY");
    const successUrl = Deno.env.get("PAYMONGO_SUCCESS_URL");
    const cancelUrl = Deno.env.get("PAYMONGO_CANCEL_URL");
    if (!secretKey || !successUrl || !cancelUrl) {
      await database.rpc("cancel_pending_order", { p_order_id: order.order_id });
      return respond({ error: "PayMongo checkout is not configured" }, 503);
    }

    const [{ data: items, error: itemsError }, { data: orderRow, error: orderError }] =
      await Promise.all([
        database
          .from("order_items")
          .select("product_name, quantity, unit_price")
          .eq("order_id", order.order_id),
        database
          .from("orders")
          .select("shipping_fee")
          .eq("id", order.order_id)
          .single(),
      ]);

    if (itemsError || orderError || !items || !orderRow) {
      await database.rpc("cancel_pending_order", { p_order_id: order.order_id });
      return respond({ error: "Could not load order details" }, 500);
    }

    let paymongoResponse: Response;
    try {
      paymongoResponse = await fetch("https://api.paymongo.com/v2/checkout_sessions", {
        method: "POST",
        headers: {
          Authorization: `Basic ${btoa(`${secretKey}:`)}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          data: {
            attributes: {
              line_items: [
                ...items.map((item) => ({
                  currency: "PHP",
                  amount: item.unit_price * 100,
                  name: item.product_name,
                  quantity: item.quantity,
                })),
                {
                  currency: "PHP",
                  amount: orderRow.shipping_fee * 100,
                  name: "Shipping",
                  quantity: 1,
                },
              ],
              payment_method_types: ["qrph"],
              success_url: successUrl,
              cancel_url: cancelUrl,
              description: `Artify order ${order.order_id}`,
              reference_number: order.order_id,
              metadata: { order_id: order.order_id },
            },
          },
        }),
      });
    } catch {
      await database.rpc("cancel_pending_order", { p_order_id: order.order_id });
      return respond({ error: "Could not reach PayMongo" }, 502);
    }

    const paymongoBody = await paymongoResponse.json();
    const session = paymongoBody?.data;
    const checkoutUrl = session?.attributes?.checkout_url;
    if (!paymongoResponse.ok || !session?.id || !checkoutUrl) {
      await database.rpc("cancel_pending_order", { p_order_id: order.order_id });
      return respond({ error: "PayMongo could not create checkout" }, 502);
    }

    const { error: saveSessionError } = await database
      .from("orders")
      .update({ paymongo_checkout_session_id: session.id })
      .eq("id", order.order_id);
    if (saveSessionError) {
      await database.rpc("cancel_pending_order", { p_order_id: order.order_id });
      return respond({ error: "Could not save payment session" }, 500);
    }

    return respond({
      orderId: order.order_id,
      accessToken: order.access_token,
      paymentMethod: "paymongo",
      status: "awaiting_payment",
      totalAmount: order.total_amount,
      checkoutUrl,
    });
  } catch (error) {
    if (reservedOrderId) {
      await database.rpc("cancel_pending_order", { p_order_id: reservedOrderId });
    }
    console.error("create-checkout failed", error);
    return respond({ error: "Could not create order" }, 500);
  }
});