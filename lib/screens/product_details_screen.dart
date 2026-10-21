import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/cart_store.dart';
import '../theme/app_theme.dart';
import '../widgets/product_art.dart';
import 'checkout/checkout_shipping_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});
  @override State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}
class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return AnimatedBuilder(
      animation: CartStore.instance,
      builder: (context, _) {
        final inventory = CartStore.instance;
        final stock = inventory.stockFor(product);
        final canAdd = inventory.canAdd(product, quantity);

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            actions: [
              IconButton(
                onPressed: () => inventory.toggleWishlist(product),
                icon: Icon(
                  inventory.isSaved(product)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: inventory.isSaved(product)
                      ? AppColors.orange
                      : AppColors.ink,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    children: [
                      ProductArt(product: product, height: 300),
                      const SizedBox(height: 18),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        product.brand,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.orange, size: 18),
                          Text(
                            ' ${product.rating}  ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '(${product.reviews} reviews)',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₱ ${product.price}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stock > 0 ? 'Stock: $stock' : 'Unavailable',
                        style: TextStyle(
                          color: stock > 0 ? AppColors.muted : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        product.description,
                        style: const TextStyle(
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$quantity'),
                          IconButton(
                            onPressed: quantity < stock
                                ? () => setState(() => quantity++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canAdd
                              ? () {
                                  final added = inventory.add(product, quantity);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        added
                                            ? 'Added to cart'
                                            : 'Not enough stock available',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to Cart'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: stock > 0
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutShippingScreen(
                                        items: {product: quantity},
                                        removeFromCart: false,
                                      ),
                                    ),
                                  )
                              : null,
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Buy Now'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: AppColors.ink,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
