import 'package:flutter/material.dart';
import '../data/product_catalog.dart';
import '../state/cart_store.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProductCatalog.instance,
      builder: (context, _) {
        final catalog = ProductCatalog.instance;
        final query = controller.text.toLowerCase();
        final items = catalog.products
            .where(
              (product) =>
                  '${product.name} ${product.brand} ${product.category}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Search Art Supplies')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search for art supplies...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: catalog.isLoading && catalog.products.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : !catalog.isConfigured && catalog.products.isEmpty
                        ? const Center(
                            child: Text('Not connected to Supabase.'),
                          )
                    : catalog.error != null && catalog.products.isEmpty
                        ? const Center(
                            child: Text('Could not connect to Supabase.'),
                          )
                        : catalog.products.isEmpty
                            ? const Center(
                                child: Text('No products available.'),
                              )
                        : query.isEmpty
                            ? const Center(
                                child: Text(
                                  'Search pencils, paints, brushes and more.',
                                ),
                              )
                            : items.isEmpty
                                ? const Center(
                                    child: Text('No products found.'),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: items.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: .68,
                                    ),
                                    itemBuilder: (context, index) => ProductCard(
                                      product: items[index],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductDetailsScreen(
                                            product: items[index],
                                          ),
                                        ),
                                      ),
                                      onAdd: () =>
                                          CartStore.instance.add(items[index]),
                                    ),
                                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}
