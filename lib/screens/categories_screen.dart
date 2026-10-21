import 'package:flutter/material.dart';
import '../data/product_catalog.dart';
import '../theme/app_theme.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final String? initialCategory;
  const CategoriesScreen({super.key, this.initialCategory});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ProductCatalog.instance,
        builder: (context, _) {
          final catalog = ProductCatalog.instance;
          final categories = catalog.categories;
          return CustomScrollView(
            slivers: [
              const SliverAppBar(title: Text('Categories'), pinned: true),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              if (categories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      catalog.isLoading
                          ? 'Loading products...'
                            : !catalog.isConfigured
                              ? 'Not connected to Supabase.'
                          : catalog.error != null
                              ? 'Could not connect to Supabase.'
                              : 'No products available.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(18),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = categories[index];
                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductListScreen(category: category.$1),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const [
                                      Color(0xFFE8E0D3),
                                      Color(0xFFE4E4E4),
                                      Color(0xFFF1E0D1),
                                    ][index % 3],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    category.$2,
                                    size: 45,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.$1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: categories.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: .72,
                    ),
                  ),
                ),
            ],
          );
        },
      );
}
