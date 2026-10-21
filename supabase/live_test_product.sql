insert into public.products (
  id,
  slug,
  name,
  brand,
  category,
  description,
  price,
  stock,
  icon_name,
  tint_hex,
  image_url,
  rating,
  reviews,
  is_active
)
values (
  '10000000-0000-4000-8000-000000000104',
  'checkout-test-watercolor-set',
  'Checkout Test Watercolor Set',
  'Artify Studio',
  'Paints',
  'A test product for verifying live checkout and inventory updates.',
  1,
  50,
  'palette_outlined',
  'F4DCCB',
  'assets/products/watercolor-paint-set.jpg',
  5.0,
  1,
  true
)
on conflict (id) do update set
  slug = excluded.slug,
  name = excluded.name,
  brand = excluded.brand,
  category = excluded.category,
  description = excluded.description,
  price = excluded.price,
  stock = excluded.stock,
  icon_name = excluded.icon_name,
  tint_hex = excluded.tint_hex,
  image_url = excluded.image_url,
  rating = excluded.rating,
  reviews = excluded.reviews,
  is_active = excluded.is_active
returning id, name, price, stock, is_active;
