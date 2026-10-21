import 'package:flutter/material.dart';
import '../data/product_catalog.dart';
import '../state/cart_store.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class ProductListScreen extends StatelessWidget {
  final String category;
  const ProductListScreen({super.key, required this.category});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProductCatalog.instance,
      builder: (context, _) {
        final catalog = ProductCatalog.instance;
        final products = catalog.products;
        final list = category == 'All Products'
            ? products
            : products.where((product) => product.category == category).toList();

        return Scaffold(
          appBar: AppBar(title: Text(category)),
          body: catalog.isLoading && products.isEmpty
              ? const Center(child: CircularProgressIndicator())
                : !catalog.isConfigured && products.isEmpty
                  ? const Center(child: Text('Not connected to Supabase.'))
              : catalog.error != null && products.isEmpty
                  ? const Center(child: Text('Could not connect to Supabase.'))
                  : list.isEmpty
                      ? Center(
                          child: Text(
                            category == 'All Products'
                                ? 'No active products found in Supabase '
                                    'project ${catalog.projectRef}. Run '
                                    'supabase/seed.sql in this project, then '
                                    'return Home and reload.'
                                : 'No products in this category yet.',
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(18),
                          itemCount: list.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .68,
                          ),
                          itemBuilder: (context, index) => ProductCard(
                            product: list[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(
                                  product: list[index],
                                ),
                              ),
                            ),
                            onAdd: () => CartStore.instance.add(list[index]),
                          ),
                        ),
        );
      },
    );
  }
}
