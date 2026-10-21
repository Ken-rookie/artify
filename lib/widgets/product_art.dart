import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductArt extends StatelessWidget {
  final Product product;
  final double height;
  const ProductArt({super.key, required this.product, this.height = 130});

  Widget _fallbackIcon(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) =>
      Icon(
        product.icon,
        size: height * .45,
        color: AppColors.ink.withValues(alpha: .8),
      );

  Widget _image(String imageUrl) {
    return imageUrl.startsWith('assets/')
        ? Image.asset(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: _fallbackIcon,
          )
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: _fallbackIcon,
          );
  }

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
            color: product.tint, borderRadius: BorderRadius.circular(14)),
        child: Stack(alignment: Alignment.center, children: [
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _image(product.imageUrl!),
              ),
            )
          else
            Icon(
              product.icon,
              size: height * .45,
              color: AppColors.ink.withValues(alpha: .8),
            ),
          const Positioned(
              right: 8,
              bottom: 7,
              child:
                  Icon(Icons.auto_awesome, color: AppColors.orange, size: 19)),
        ]),
      );
}
