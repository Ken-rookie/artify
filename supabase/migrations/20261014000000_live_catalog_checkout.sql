create extension if not exists pgcrypto with schema extensions;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text not null default '',
  category text not null,
  description text not null default '',
  price integer not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  icon_name text not null default 'palette_outlined',
  tint_hex text not null default 'E9D8C3',
  image_url text,
  rating numeric(2, 1) not null default 4.8,
  reviews integer not null default 0 check (reviews >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  access_token_hash text not null,
  customer_name text not null,
  phone text not null,
  address text not null,
  payment_method text not null check (payment_method in ('cod', 'paymongo')),
  status text not null check (
    status in ('processing', 'awaiting_payment', 'completed', 'cancelled')
  ),
  payment_status text not null check (
    payment_status in ('unpaid', 'pending', 'paid', 'failed')
  ),
  subtotal integer not null default 0 check (subtotal >= 0),
  shipping_fee integer not null default 80 check (shipping_fee >= 0),
  total_amount integer not null default 0 check (total_amount >= 0),
  paymongo_checkout_session_id text unique,
  created_at timestamptz not null default now()
);

alter table public.orders
  add column if not exists access_token_hash text,
  add column if not exists customer_name text not null default '',
  add column if not exists phone text not null default '',
  add column if not exists address text not null default '',
  add column if not exists payment_method text not null default 'cod',
  add column if not exists status text not null default 'processing',
  add column if not exists payment_status text not null default 'unpaid',
  add column if not exists subtotal integer not null default 0,
  add column if not exists shipping_fee integer not null default 80,
  add column if not exists total_amount integer not null default 0,
  add column if not exists paymongo_checkout_session_id text;

alter table public.orders
  drop constraint if exists orders_payment_status_check;

alter table public.orders
  add constraint orders_payment_status_check
  check (payment_status in ('unpaid', 'pending', 'paid', 'failed'));

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price integer not null check (unit_price >= 0),
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

grant select on public.products to anon, authenticated;
drop policy if exists "Active products are visible to everyone" on public.products;
create policy "Active products are visible to everyone"
  on public.products for select to anon, authenticated
  using (is_active);

revoke all on public.orders, public.order_items from anon, authenticated;

create or replace function public.create_order(
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
begin
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

  insert into public.orders (
    id, access_token_hash, customer_name, phone, address, payment_method,
    status, payment_status, shipping_fee
  ) values (
    v_order_id,
    encode(digest(v_access_token, 'sha256'), 'hex'),
    trim(p_customer_name), trim(p_phone), trim(p_address), p_payment_method,
    case when p_payment_method = 'cod' then 'processing' else 'awaiting_payment' end,
    case when p_payment_method = 'cod' then 'unpaid' else 'pending' end,
    v_shipping_fee
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
      order_id, product_id, product_name, quantity, unit_price
    ) values (
      v_order_id, v_item.product_id, v_product_name, v_item.quantity, v_unit_price
    );

    v_subtotal := v_subtotal + (v_unit_price * v_item.quantity);
  end loop;

  update public.orders
    set subtotal = v_subtotal,
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

revoke all on function public.create_order(text, text, text, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.create_order(text, text, text, text, jsonb)
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
      and status = 'awaiting_payment'
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

create or replace function public.get_order_status(
  p_order_id uuid,
  p_access_token text
) returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'status', orders.status,
    'payment_status', orders.payment_status
  )
  from public.orders
  where orders.id = p_order_id
    and orders.access_token_hash = encode(digest(p_access_token, 'sha256'), 'hex');
$$;

revoke all on function public.get_order_status(uuid, text) from public;
grant execute on function public.get_order_status(uuid, text) to anon, authenticated;


create or replace function public.current_user_role()
returns text
language sql
stable
security invoker
set search_path = public, auth
as $$
  select case
    when coalesce(auth.jwt() -> 'app_metadata' ->> 'role', 'user') = 'admin'
      then 'admin'
    else 'user'
  end;
$$;

revoke all on function public.current_user_role() from public, anon;
grant execute on function public.current_user_role() to authenticated;