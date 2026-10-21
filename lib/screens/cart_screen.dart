import 'package:flutter/material.dart';
import '../state/cart_store.dart';
import '../theme/app_theme.dart';
import '../widgets/product_art.dart';
import '../widgets/primary_button.dart';
import 'checkout/checkout_shipping_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: CartStore.instance, builder: (context, _) {
    final cart = CartStore.instance.items;
    final subtotal = CartStore.instance.subtotal;
    return Scaffold(appBar: AppBar(title: const Text('My Cart')), body: cart.isEmpty
      ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart_outlined, size: 58, color: AppColors.muted), SizedBox(height: 12), Text('Your cart is empty'), Text('Add supplies to start creating.', style: TextStyle(color: AppColors.muted))]))
      : Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in cart.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 82,
                          child: ProductArt(product: entry.key, height: 88),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '₱ ${entry.key.price}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        CartStore.instance.setQuantity(
                                      entry.key,
                                      entry.value - 1,
                                    ),
                                    icon: const Icon(Icons.remove, size: 18),
                                  ),
                                  Text('${entry.value}'),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        CartStore.instance.setQuantity(
                                      entry.key,
                                      entry.value + 1,
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => CartStore.instance.setQuantity(
                            entry.key,
                            0,
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(20, 18, 20, 16), child: Column(children: [
          _PriceRow('Subtotal', '₱ $subtotal'), const _PriceRow('Shipping', 'Calculated at checkout'),
          const Divider(height: 24), _PriceRow('Total', '₱ $subtotal', bold: true), const SizedBox(height: 12),
          PrimaryButton(label: 'Checkout', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutShippingScreen(items: cart, removeFromCart: true)))),
        ])),
        ]));
  });
}
class _PriceRow extends StatelessWidget {
  final String label, value; final bool bold;
  const _PriceRow(this.label, this.value, {this.bold = false});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
    Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
    const Spacer(), Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
  ]));
}
