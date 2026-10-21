import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/cart_store.dart';
import '../theme/app_theme.dart';
import 'product_art.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap, onAdd;
  const ProductCard({super.key, required this.product, required this.onTap, required this.onAdd});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: CartStore.instance,
        builder: (context, _) {
          final stock = CartStore.instance.stockFor(product);
          final canAdd = CartStore.instance.canAdd(product);

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ProductArt(product: product, height: 130)),
                    const SizedBox(height: 7),
                    Text(
                      product.brand,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stock > 0 ? 'Stock: $stock' : 'Unavailable',
                      style: TextStyle(
                        color: stock > 0 ? AppColors.muted : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₱ ${product.price}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add to cart',
                          onPressed: canAdd ? onAdd : null,
                          icon: const Icon(Icons.add_shopping_cart, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
