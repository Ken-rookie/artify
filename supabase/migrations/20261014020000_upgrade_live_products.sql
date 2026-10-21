alter table public.products
  add column if not exists brand text not null default '',
  add column if not exists category text not null default 'Uncategorized',
  add column if not exists description text not null default '',
  add column if not exists price integer not null default 0,
  add column if not exists stock integer not null default 0,
  add column if not exists icon_name text not null default 'palette_outlined',
  add column if not exists tint_hex text not null default 'E9D8C3',
  add column if not exists image_url text,
  add column if not exists rating numeric(2, 1) not null default 4.8,
  add column if not exists reviews integer not null default 0,
  add column if not exists is_active boolean not null default true;

alter table public.products
  drop constraint if exists products_stock_check;

alter table public.products
  add constraint products_stock_check check (stock >= 0);

alter table public.products
  drop constraint if exists products_price_check;

alter table public.products
  add constraint products_price_check check (price >= 0);

alter table public.products
  drop constraint if exists products_reviews_check;

alter table public.products
  add constraint products_reviews_check check (reviews >= 0);

notify pgrst, 'reload schema';