import 'package:flutter/material.dart';
import '../state/cart_store.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: CartStore.instance, builder: (context, _) {
    final items = CartStore.instance.wishlist.toList();
    return Scaffold(appBar: AppBar(title: const Text('My Wishlist')), body: items.isEmpty
      ? const Center(child: Text('Your wishlist is empty. Tap the heart on a product to save it.'))
      : GridView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .68), itemBuilder: (context, i) => ProductCard(product: items[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: items[i]))), onAdd: () => CartStore.instance.add(items[i]))));
  });
}
