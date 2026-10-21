import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/user_role_checker.dart';
import '../../config/supabase_config.dart';
import '../../theme/app_theme.dart';
import '../auth_screen.dart';
import 'addresses_screen.dart';
import 'orders_screen.dart';
import 'payment_methods_screen.dart';
import 'settings_screen.dart';
import '../wishlist_screen.dart';
import '../notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
    const SizedBox(height: 20),
    const Row(children: [CircleAvatar(radius: 28, backgroundColor: Color(0xFFE8E0D3), child: Icon(Icons.person, size: 30)), SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Juan Dela Cruz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text('juan@email.com', style: TextStyle(color: AppColors.muted, fontSize: 12))])]),
    const SizedBox(height: 24),
        FutureBuilder<AccountRole>(
          future: UserRoleChecker.currentRole(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Account role could not be checked.');
            }
            final role = snapshot.data;
            if (role == null) return const Text('Checking account role...');

            final label = switch (role) {
              AccountRole.admin => 'ADMIN',
              AccountRole.user => 'USER',
              AccountRole.guest => 'DEMO MODE',
            };

            return Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(
                  role == AccountRole.admin ? Icons.admin_panel_settings : Icons.person,
                  size: 18,
                ),
                label: Text('Account type: $label'),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
    _ProfileItem(Icons.receipt_long_outlined, 'My Orders', () => _push(context, const OrdersScreen())),
    _ProfileItem(Icons.location_on_outlined, 'Addresses', () => _push(context, const AddressesScreen())),
    _ProfileItem(Icons.payment_outlined, 'Payment Methods', () => _push(context, const PaymentMethodsScreen())),
    _ProfileItem(Icons.favorite_border, 'Wishlist', () => _push(context, const WishlistScreen())),
    _ProfileItem(Icons.notifications_none, 'Notifications', () => _push(context, const NotificationsScreen())),
    _ProfileItem(Icons.settings_outlined, 'Settings', () => _push(context, const SettingsScreen())),
    _ProfileItem(Icons.help_outline, 'Help & Support', () => _message(context, 'Support contact details can be configured here.')),
    _ProfileItem(Icons.logout, 'Log Out', () => _signOut(context)),
  ]);
  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  Future<void> _signOut(BuildContext context) async {
    try {
      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'Could not sign out. Try again.');
      return;
    }
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _message(BuildContext context, String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
}
class _ProfileItem extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const _ProfileItem(this.icon, this.title, this.onTap);
  @override Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: Icon(icon, size: 21), title: Text(title, style: const TextStyle(fontSize: 14)), trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.muted), onTap: onTap);
}
