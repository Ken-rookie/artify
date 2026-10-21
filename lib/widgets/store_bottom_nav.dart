import 'package:flutter/material.dart';
import '../state/cart_store.dart';
import '../theme/app_theme.dart';

class StoreBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const StoreBottomNav({super.key, required this.selectedIndex, required this.onSelect});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: CartStore.instance,
    builder: (context, _) => NavigationBar(
      selectedIndex: selectedIndex, onDestinationSelected: onSelect,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Categories'),
        NavigationDestination(icon: _CountIcon(count: CartStore.instance.count), selectedIcon: _CountIcon(count: CartStore.instance.count, active: true), label: 'Cart'),
        const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}
class _CountIcon extends StatelessWidget {
  final int count; final bool active;
  const _CountIcon({required this.count, this.active = false});
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
    Icon(active ? Icons.shopping_cart : Icons.shopping_cart_outlined),
    if (count > 0) Positioned(right: -7, top: -5, child: Container(
      padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
      child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
    )),
  ]);
}
