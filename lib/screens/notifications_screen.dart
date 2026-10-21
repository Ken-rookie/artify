import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifications')), body: ListView(padding: const EdgeInsets.all(16), children: const [
    _Notice(icon: Icons.local_shipping_outlined, title: 'Your order has shipped', subtitle: 'Order #ART12345 is on its way.', time: 'Today · 9:15 AM'),
    _Notice(icon: Icons.local_offer_outlined, title: '20% OFF on Art Canvases', subtitle: 'Special offer for your next masterpiece.', time: 'Yesterday'),
    _Notice(icon: Icons.auto_awesome, title: 'New arrivals', subtitle: 'Check out our latest art supplies.', time: 'Oct 10'),
  ]));
}
class _Notice extends StatelessWidget {
  final IconData icon; final String title, subtitle, time;
  const _Notice({required this.icon, required this.title, required this.subtitle, required this.time});
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppColors.orange.withValues(alpha: .18), child: Icon(icon, color: AppColors.ink)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('$subtitle\n$time'), isThreeLine: true));
}
