alter table public.orders
  add column if not exists user_id uuid references auth.users(id),
  add column if not exists recipient_name text not null default '',
  add column if not exists recipient_phone text not null default '',
  add column if not exists shipping_address jsonb not null default '{}'::jsonb,
  add column if not exists delivery_method text not null default 'standard',
  add column if not exists delivery_fee numeric not null default 0,
  add column if not exists total numeric not null default 0;

alter table public.order_items
  add column if not exists line_total numeric not null default 0;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'orders'
      and column_name = 'status'
      and data_type = 'text'
  ) then
    alter table public.orders drop constraint if exists orders_status_check;
    alter table public.orders
      add constraint orders_status_check
      check (
        status in (
          'processing',
          'awaiting_payment',
          'pending_payment',
          'completed',
          'cancelled'
        )
      );
  end if;
end;
$$;

create or replace function public.create_order(
  p_user_id uuid,
  p_customer_name text,
  p_phone text,
  p_address text,
  p_payment_method text,
  p_items jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_order_id uuid := gen_random_uuid();
  v_access_token text := encode(gen_random_bytes(32), 'hex');
  v_item record;
  v_product_name text;
  v_unit_price integer;
  v_subtotal integer := 0;
  v_shipping_fee integer := 80;
  v_status public.orders.status%type;
  v_payment_status public.orders.payment_status%type;
begin
  if p_user_id is null then
    raise exception 'A signed-in customer is required';
  end if;

  if length(trim(coalesce(p_customer_name, ''))) not between 2 and 120
     or length(trim(coalesce(p_phone, ''))) not between 5 and 40
     or length(trim(coalesce(p_address, ''))) not between 5 and 500 then
    raise exception 'Invalid customer details';
  end if;

  if p_payment_method not in ('cod', 'paymongo') then
    raise exception 'Unsupported payment method';
  end if;

  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) not between 1 and 50 then
    raise exception 'Invalid order items';
  end if;

  if p_payment_method = 'cod' then
    v_status := 'processing';
    v_payment_status := 'unpaid';
  else
    v_status := 'pending_payment';
    v_payment_status := 'pending';
  end if;

  insert into public.orders (
    id, user_id, access_token_hash, customer_name, phone, address,
    payment_method, status, payment_status, shipping_fee,
    recipient_name, recipient_phone, shipping_address, delivery_method,
    delivery_fee, subtotal, total
  ) values (
    v_order_id, p_user_id,
    encode(digest(v_access_token, 'sha256'), 'hex'),
    trim(p_customer_name), trim(p_phone), trim(p_address),
    p_payment_method, v_status, v_payment_status, v_shipping_fee,
    trim(p_customer_name), trim(p_phone),
    jsonb_build_object('address', trim(p_address)),
    'standard', v_shipping_fee, 0, 0
  );

  for v_item in
    select (item.value ->> 'product_id')::uuid as product_id,
           sum((item.value ->> 'quantity')::integer)::integer as quantity
    from jsonb_array_elements(p_items) as item(value)
    group by (item.value ->> 'product_id')::uuid
    order by (item.value ->> 'product_id')::uuid
  loop
    if v_item.quantity <= 0 then
      raise exception 'Invalid item quantity';
    end if;

    update public.products as product
      set stock = product.stock - v_item.quantity
      where product.id = v_item.product_id
        and product.is_active
        and product.stock >= v_item.quantity
      returning product.name, product.price
        into v_product_name, v_unit_price;

    if not found then
      raise exception 'Product unavailable or insufficient stock: %', v_item.product_id;
    end if;

    insert into public.order_items (
      order_id, product_id, product_name, quantity, unit_price, line_total
    ) values (
      v_order_id, v_item.product_id, v_product_name, v_item.quantity,
      v_unit_price, v_unit_price * v_item.quantity
    );

    v_subtotal := v_subtotal + (v_unit_price * v_item.quantity);
  end loop;

  update public.orders
    set subtotal = v_subtotal,
        total = v_subtotal + v_shipping_fee,
        total_amount = v_subtotal + v_shipping_fee
    where id = v_order_id;

  return jsonb_build_object(
    'order_id', v_order_id,
    'access_token', v_access_token,
    'subtotal', v_subtotal,
    'shipping_fee', v_shipping_fee,
    'total_amount', v_subtotal + v_shipping_fee
  );
end;
$$;

do $$
begin
  if to_regprocedure('public.create_order(text,text,text,text,jsonb)') is not null then
    execute 'revoke all on function public.create_order(text, text, text, text, jsonb) from public, anon, authenticated, service_role';
    execute 'drop function public.create_order(text, text, text, text, jsonb)';
  end if;
end;
$$;

revoke all on function public.create_order(uuid, text, text, text, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.create_order(uuid, text, text, text, text, jsonb)
  to service_role;

create or replace function public.cancel_pending_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
begin
  update public.orders
    set status = 'cancelled', payment_status = 'failed'
    where id = p_order_id
      and payment_method = 'paymongo'
      and status = 'pending_payment'
      and payment_status = 'pending'
    returning id into v_order_id;

  if v_order_id is null then
    return;
  end if;

  update public.products as product
    set stock = product.stock + item.quantity
    from public.order_items as item
    where item.order_id = v_order_id
      and product.id = item.product_id;
end;
$$;

revoke all on function public.cancel_pending_order(uuid)
  from public, anon, authenticated;
grant execute on function public.cancel_pending_order(uuid) to service_role;

notify pgrst, 'reload schema';
