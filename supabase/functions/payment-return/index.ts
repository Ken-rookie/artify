const appReturnUrls: Record<string, string> = {
  success: "artify://payment/success",
  cancel: "artify://payment/cancel",
};

Deno.serve((request) => {
  if (request.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const result = new URL(request.url).searchParams.get("result");
  const appReturnUrl = result ? appReturnUrls[result] : undefined;
  if (!appReturnUrl) {
    return new Response("Invalid payment result", { status: 400 });
  }

  return new Response(null, {
    status: 302,
    headers: {
      "Cache-Control": "no-store",
      Location: appReturnUrl,
    },
  });
});
