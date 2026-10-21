create or replace function public.get_my_orders()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(to_jsonb(order_row) order by order_row.placed_at desc),
    '[]'::jsonb
  )
  from (
    select
      orders.id,
      orders.order_number,
      orders.status::text as status,
      orders.payment_method,
      orders.payment_status,
      orders.subtotal,
      orders.delivery_fee,
      orders.total,
      orders.total_amount,
      orders.placed_at,
      coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'product_name', item.product_name,
            'quantity', item.quantity,
            'unit_price', item.unit_price,
            'line_total', item.line_total
          )
          order by item.product_name
        )
        from public.order_items as item
        where item.order_id = orders.id
      ), '[]'::jsonb) as items
    from public.orders
    where orders.user_id = auth.uid()
  ) as order_row;
$$;

revoke all on function public.get_my_orders() from public, anon;
grant execute on function public.get_my_orders() to authenticated;

notify pgrst, 'reload schema';
