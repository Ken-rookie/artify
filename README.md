# Artify — Full Flutter UI Flow

This is a multi-file Flutter starter based on the supplied Artify screen-flow reference.

## Included screens
1. Splash Screen
2. Loading Screen
3. Login / Sign Up
4. Home
5. Categories
6. Product Details
7. Cart
8. Checkout — Shipping
9. Checkout — Payment
10. Order Review
11. Order Success
12. Profile / Account
13. Search
14. Wishlist
15. Orders
16. Order Tracking
17. Notifications
18. Addresses
19. Payment Methods
20. Settings

## Run
Install Flutter, extract this folder, then run:
```bash
flutter pub get
flutter run
```

## Mobile layout and safe areas
Screens use `SafeArea`, scrollable content, bottom-safe navigation, and padded fixed bottom actions. Flutter reads the device safe insets, so the layout avoids the camera cutout/notch, status bar, and gesture-navigation area without hard-coded device-specific dimensions.

## Current implementation status
- The app uses reusable widgets and separate Dart files by screen and responsibility.
- Product screens read active rows from Supabase. Debug builds show bundled demo products when the catalog is empty or Supabase is not configured; demo checkout is simulated and never creates an order or payment.
- Product catalog rows and stock are defined by the migration in `supabase/migrations/`.
- Cart and wishlist state are local in-memory state in `lib/state/cart_store.dart`.
- Delivery addresses are stored per signed-in user in Supabase with row-level security. The default saved address automatically fills checkout; customers can manage addresses from Account or checkout.
- Email/password sign-in and signup use Supabase Auth when configured; social providers still need setup in Supabase.
- The profile checks the signed-in user's role. Users default to `user`; roles are read from trusted Supabase `app_metadata` and cannot be changed by a Flutter client.
- COD orders and PayMongo checkout sessions are created by a Supabase Edge Function. Inventory is checked and reserved in the database.
- PayMongo orders are marked paid only after the signed PayMongo webhook is processed.

## Supabase integration
The app initializes `supabase_flutter` at startup with the configured Artify project URL and public anon key. You can override either value at launch if needed:
```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
```

Apply the migration to create the products and orders tables, then deploy the checkout function:
```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy create-checkout
```

For local development, load the three disposable products and schema with:
```bash
supabase db reset
```
For a hosted test project, run `supabase/seed.sql` in the Supabase SQL Editor after applying migrations. These demo products are deliberately kept out of production migrations. When Supabase is configured but has no active products, the app now shows an empty catalog instead of simulated checkout products.

To add just one inexpensive live checkout product instead, run `supabase/live_test_product.sql` in the Supabase SQL Editor. This adds a 99-peso test product with 50 units of stock and is safe to re-run.

Sign in with an email/password account before placing a live order. Cash-on-delivery orders are saved in `public.orders`, with line items in `public.order_items`; inventory is reserved when the order is created. Deploy the `create-checkout` function, open the app with the same Supabase project, sign in, and place a cash-on-delivery order for the test product. Verify recent orders in the Supabase SQL Editor:
```sql
select id, customer_name, payment_method, status, payment_status,
       total_amount, created_at
from public.orders
order by created_at desc;
```

Email/password login uses Supabase Auth. The role checker reads `app_metadata.role` from the signed-in user's JWT; missing or non-admin roles are treated as `user`. To promote an existing account, run this in the Supabase SQL Editor as a trusted administrator, replacing the UUID with the Auth user ID:
```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
	|| jsonb_build_object('role', 'admin')
where id = 'AUTH_USER_UUID';
```
The account must sign out and back in to receive the updated role claim. The Flutter client cannot change `app_metadata`; a future admin panel should use a protected Edge Function for role changes. Social login providers still need to be configured separately in Supabase Auth.

COD orders and PayMongo checkout sessions are created by Supabase Edge Functions. COD only requires the migration, active products, a signed-in user, and the deployed `create-checkout` function. Configure PayMongo only as Function secrets, then deploy its functions:
```bash
supabase secrets set PAYMONGO_SECRET_KEY=YOUR_TEST_SECRET PAYMONGO_WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET PAYMONGO_SUCCESS_URL=https://YOUR_PROJECT_REF.supabase.co/functions/v1/payment-return?result=success PAYMONGO_CANCEL_URL=https://YOUR_PROJECT_REF.supabase.co/functions/v1/payment-return?result=cancel
supabase functions deploy create-checkout
supabase functions deploy paymongo-webhook
supabase functions deploy payment-return
```

In PayMongo, register `https://YOUR_PROJECT_REF.supabase.co/functions/v1/paymongo-webhook` for `checkout_session.payment.paid` and `checkout_session.expired`. Never put a PayMongo secret or Supabase service-role key in Flutter or source control. Live checkout requires the migration, deployed functions, and webhook configuration.
PayMongo hosted checkout is configured to accept QRPH only. The payment-return function redirects customers to `artify://payment/success` or `artify://payment/cancel`; Android and iOS builds register the `artify` URL scheme.
The `20261021010000` pricing migration sets every product price and the delivery fee to ₱1 for new checkouts. Previously placed orders retain their original totals.
