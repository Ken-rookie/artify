import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/product.dart';

class ProductCatalog extends ChangeNotifier {
  ProductCatalog._();

  static final instance = ProductCatalog._();

  List<Product> _products = [];
  bool _isLoading = false;
  bool _isDemoCatalog = false;
  String? _error;

  static const demoProducts = <Product>[
    Product(
      id: 'demo-watercolor-paint-set',
      name: 'Watercolor Paint Set',
      brand: 'Artify Studio',
      category: 'Paints',
      description:
          'A watercolor paint set with a wide range of colors, mixing palette, and brushes for painting and illustration.',
      price: 1,
      stock: 25,
      icon: Icons.palette_outlined,
      tint: Color(0xFFF4DCCB),
      imageUrl: 'assets/products/watercolor-paint-set.jpg',
      rating: 4.8,
      reviews: 24,
    ),
    Product(
      id: 'demo-sketchbook',
      name: 'Sketchbook',
      brand: 'Artify Studio',
      category: 'Paper',
      description:
          'A spiral-bound sketchbook for drawing, sketching, and everyday creative work.',
      price: 1,
      stock: 40,
      icon: Icons.description_outlined,
      tint: Color(0xFFD8E5D4),
      imageUrl: 'assets/products/sketchbook.jpg',
      rating: 4.7,
      reviews: 18,
    ),
    Product(
      id: 'demo-charcoal-pencil-set',
      name: 'Charcoal Pencil Set',
      brand: 'Artify Studio',
      category: 'Drawing',
      description:
          'A charcoal drawing set with pencils, sticks, and blending tools for sketching and shading.',
      price: 1,
      stock: 30,
      icon: Icons.edit_outlined,
      tint: Color(0xFFD9DDF0),
      imageUrl: 'assets/products/charcoal-pencil-set.jpg',
      rating: 4.9,
      reviews: 31,
    ),
  ];

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConfigured => SupabaseConfig.isConfigured;
  bool get isDemoCatalog => _isDemoCatalog;
  bool get isDemoCheckoutEnabled => kDebugMode && _isDemoCatalog;
  String get projectRef =>
      Uri.parse(SupabaseConfig.projectUrl).host.split('.').first;

  List<(String, IconData)> get categories {
    final seen = <String>{};
    return [
      for (final product in _products)
        if (seen.add(product.category)) (product.category, product.icon),
    ];
  }

  Future<void> refresh() async {
    if (!isConfigured) {
      _products = kDebugMode ? demoProducts : [];
      _isDemoCatalog = kDebugMode;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _products = [];
    _error = null;
    notifyListeners();

    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('name');
      _products = rows
          .map((row) => Product.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      _isDemoCatalog = false;
    } catch (error) {
      _products = [];
      _isDemoCatalog = false;
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
