import 'package:flutter/material.dart';
import 'dart:async';
import '../data/product_catalog.dart';
import '../widgets/store_bottom_nav.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'account/profile_screen.dart';

class StoreShell extends StatefulWidget {
  const StoreShell({super.key});
  @override State<StoreShell> createState() => _StoreShellState();
}
class _StoreShellState extends State<StoreShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    unawaited(ProductCatalog.instance.refresh());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: IndexedStack(index: tab, children: const [HomeScreen(), CategoriesScreen(), CartScreen(), ProfileScreen()])),
    bottomNavigationBar: SafeArea(top: false, child: StoreBottomNav(selectedIndex: tab, onSelect: (i) => setState(() => tab = i))),
  );
}
