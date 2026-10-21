// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artify/app.dart';
import 'package:artify/auth/user_role_checker.dart';
import 'package:artify/data/product_catalog.dart';
import 'package:artify/models/product.dart';
import 'package:artify/screens/checkout/checkout_shipping_screen.dart';
import 'package:artify/screens/home_screen.dart';
import 'package:artify/screens/product_details_screen.dart';
import 'package:artify/state/cart_store.dart';

void main() {
  testWidgets('app starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ArtifyApp());
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('home explains which project has an empty live catalog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeScreen())),
    );

    expect(
      find.textContaining('No active products found in Supabase project'),
      findsOneWidget,
    );
    expect(find.text('Reload products'), findsOneWidget);
  });

  test('role checker reports guest before Supabase initializes', () async {
    expect(await UserRoleChecker.currentRole(), AccountRole.guest);
  });

  test('Supabase product rows map to product cards correctly', () {
    final product = Product.fromJson({
      'id': '10000000-0000-4000-8000-000000000001',
      'name': 'Live brush set',
      'brand': 'Artify',
      'category': 'Brushes',
      'description': 'A live catalog row',
      'price': 350,
      'stock': 0,
      'icon_name': 'brush_outlined',
      'tint_hex': 'E8D8C9',
      'image_url': 'https://example.com/brushes.png',
      'rating': 4.7,
      'reviews': 12,
    });

    expect(product.id, '10000000-0000-4000-8000-000000000001');
    expect(product.stock, 0);
    expect(product.icon, Icons.brush_outlined);
    expect(product.imageUrl, 'https://example.com/brushes.png');
  });

  test('demo catalog contains three bundled products with loadable images',
      () async {
    expect(ProductCatalog.demoProducts, hasLength(3));
    expect(
      ProductCatalog.demoProducts.every(
        (product) => product.id.startsWith('demo-'),
      ),
      isTrue,
    );
    expect(
      ProductCatalog.demoProducts.map((product) => product.name).toList(),
      [
        'Watercolor Paint Set',
        'Sketchbook',
        'Charcoal Pencil Set',
      ],
    );
    expect(
      ProductCatalog.demoProducts.map((product) => product.imageUrl).toList(),
      [
        'assets/products/watercolor-paint-set.jpg',
        'assets/products/sketchbook.jpg',
        'assets/products/charcoal-pencil-set.jpg',
      ],
    );
    for (final product in ProductCatalog.demoProducts) {
      await rootBundle.load(product.imageUrl!);
    }
  });

  test('inventory rejects purchases that would make stock negative', () {
    const product = Product(
      id: 'stock-boundary-test',
      name: 'Test brush',
      brand: 'Artify',
      category: 'Brushes',
      price: 100,
      icon: Icons.brush,
      tint: Colors.white,
      description: 'Test item',
      stock: 1,
    );
    final inventory = CartStore.instance;

    expect(inventory.add(product, 2), isFalse);
    expect(inventory.add(product), isTrue);
    expect(inventory.completePurchase({product: 2}), isFalse);
    expect(inventory.stockFor(product), 1);
    expect(
      inventory.completePurchase({product: 1}, removeFromCart: true),
      isTrue,
    );
    expect(inventory.stockFor(product), 0);
    expect(inventory.add(product), isFalse);
  });

  testWidgets('out-of-stock product disables purchase actions', (
    WidgetTester tester,
  ) async {
    const product = Product(
      id: 'unavailable-test',
      name: 'Unavailable paint',
      brand: 'Artify',
      category: 'Paint',
      price: 100,
      icon: Icons.palette,
      tint: Colors.white,
      description: 'Test item',
      stock: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(home: ProductDetailsScreen(product: product)),
    );

    expect(find.text('Unavailable'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Add to Cart'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Buy Now'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('checkout shows QRPH and lets customers choose payment method', (
    WidgetTester tester,
  ) async {
    const product = Product(
      id: 'payment-choice-test',
      name: 'Test paint',
      brand: 'Artify',
      category: 'Paint',
      price: 100,
      icon: Icons.palette,
      tint: Colors.white,
      description: 'Test item',
      stock: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CheckoutShippingScreen(items: {product: 1}),
      ),
    );

    expect(find.text('Cash on delivery'), findsOneWidget);
    expect(find.text('QRPH via PayMongo'), findsOneWidget);
    expect(find.text('Scan a QR code with your banking or wallet app.'),
        findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('Test paint'), findsOneWidget);
    await tester.tap(find.text('QRPH via PayMongo'));
    await tester.pumpAndSettle();
    expect(find.text('Continue to QRPH payment'), findsOneWidget);
  });

  testWidgets('checkout validates customer details before submitting', (
    WidgetTester tester,
  ) async {
    const product = Product(
      id: 'customer-details-validation-test',
      name: 'Test paint',
      brand: 'Artify',
      category: 'Paint',
      price: 100,
      icon: Icons.palette,
      tint: Colors.white,
      description: 'Test item',
      stock: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CheckoutShippingScreen(items: {product: 1}),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Sample Name');
    await tester.enterText(find.byType(TextFormField).at(1), '2423');
    await tester.enterText(find.byType(TextFormField).at(2), '123 Main St');
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place COD order'));
    await tester.pumpAndSettle();

    expect(
      find.text('Phone number must be at least 5 characters'),
      findsOneWidget,
    );
    expect(find.textContaining('Could not place order:'), findsNothing);
  });

  testWidgets('demo PayMongo checkout simulates payment without a backend', (
    WidgetTester tester,
  ) async {
    final product = ProductCatalog.demoProducts.first;

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutShippingScreen(items: {product: 1}),
      ),
    );

    expect(find.textContaining('Demo checkout only'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('QRPH via PayMongo'));
    await tester.tap(find.text('QRPH via PayMongo'));
    await tester.pumpAndSettle();
    expect(find.text('Continue to QRPH payment'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Demo Customer');
    await tester.enterText(find.byType(TextFormField).at(1), '09123456789');
    await tester.enterText(find.byType(TextFormField).at(2), '1 Test Street');
    await tester.tap(find.text('Continue to QRPH payment'));
    await tester.pumpAndSettle();

    expect(find.text('Demo payment session'), findsOneWidget);
    expect(find.text('Simulate successful payment'), findsOneWidget);
    await tester.tap(find.text('Simulate successful payment'));
    await tester.pumpAndSettle();

    expect(find.text('Demo checkout complete'), findsOneWidget);
    expect(
      find.textContaining('No order was saved and no payment was taken'),
      findsOneWidget,
    );
  });
}
