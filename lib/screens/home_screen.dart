import 'package:flutter/material.dart';
import '../data/product_catalog.dart';
import '../models/product.dart';
import '../state/cart_store.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/product_card.dart';
import '../widgets/section_title.dart';
import 'categories_screen.dart';
import 'notifications_screen.dart';
import 'product_details_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ProductCatalog.instance,
        builder: (context, _) {
          final catalog = ProductCatalog.instance;
          final products = catalog.products;
          final categories = catalog.categories;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Expanded(child: BrandLogo(size: 34)),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_none),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: const IgnorePointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for art supplies...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: Icon(Icons.tune),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (catalog.isDemoCatalog)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DEMO MODE: These sample products are local. Checkout is simulated; no real order or payment will be created.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    height: 162,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [AppColors.ink, Color(0xFF30302D)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -8,
                          bottom: -24,
                          child: Icon(
                            Icons.brush,
                            size: 142,
                            color: AppColors.orange.withValues(alpha: .22),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Premium Art Supplies',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'for Your Next Masterpiece',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: products.isEmpty
                                  ? null
                                  : () => _openProduct(context, products.first),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: AppColors.ink,
                              ),
                              child: const Text('Shop Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 82,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final category in categories.take(6))
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: SizedBox(
                              width: 60,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CategoriesScreen(
                                      initialCategory: category.$1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.orange.withValues(
                                          alpha: .18,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(category.$2),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      category.$1,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionTitle(
                    title: 'Popular Products',
                    actionLabel: 'See All',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProductListScreen(category: 'All Products'),
                      ),
                    ),
                  ),
                ),
              ),
              if (products.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            catalog.isLoading
                                ? 'Loading products...'
                                : !catalog.isConfigured
                                    ? 'Not connected to Supabase.'
                                    : catalog.error != null
                                        ? 'Could not connect to Supabase.'
                                        : 'No active products found in Supabase '
                                            'project ${catalog.projectRef}. '
                                            'Run supabase/seed.sql in this '
                                            'project, then reload.',
                            textAlign: TextAlign.center,
                          ),
                          if (!catalog.isLoading &&
                              catalog.isConfigured &&
                              catalog.error == null)
                            TextButton(
                              onPressed: catalog.refresh,
                              child: const Text('Reload products'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(
                      product: products[index],
                      onTap: () => _openProduct(context, products[index]),
                      onAdd: () {
                        CartStore.instance.add(products[index]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                    ),
                    childCount: products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .68,
                  ),
                ),
              ),
            ],
          );
        },
      );

  void _openProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );
  }
}
