import 'package:flutter/material.dart';

class Product {
  final String id, name, brand, category, description;
  final int price;
  final int stock;
  final String? imageUrl;
  final IconData icon;
  final Color tint;
  final double rating;
  final int reviews;
  const Product({
    required this.id, required this.name, required this.brand,
    required this.category, required this.price, required this.icon,
    required this.tint, required this.description,
    this.stock = 10,
    this.imageUrl,
    this.rating = 4.8, this.reviews = 124,
  }) : assert(stock >= 0);

  factory Product.fromJson(Map<String, dynamic> json) {
    final tintValue = (json['tint_hex'] as String? ?? 'E9D8C3')
        .replaceFirst('#', '');
    final parsedTint = int.tryParse(tintValue, radix: 16) ?? 0xFFE9D8C3;

    return Product(
      id: json['id'].toString(),
      name: json['name'] as String,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? 'Uncategorized',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.round() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      icon: _iconFor(json['icon_name'] as String? ?? ''),
      tint: Color(0xFF000000 | parsedTint),
      imageUrl: json['image_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
    );
  }

  static IconData _iconFor(String name) => switch (name) {
        'edit_outlined' => Icons.edit_outlined,
        'brush_outlined' => Icons.brush_outlined,
        'crop_16_9_outlined' => Icons.crop_16_9_outlined,
        'gesture_outlined' => Icons.gesture_outlined,
        'description_outlined' => Icons.description_outlined,
        _ => Icons.palette_outlined,
      };
}
