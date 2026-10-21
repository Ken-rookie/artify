import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

enum AccountRole { guest, user, admin }

class UserRoleChecker {
  const UserRoleChecker._();

  static Future<AccountRole> currentRole() async {
    if (!SupabaseConfig.isConfigured || !SupabaseConfig.isInitialized) {
      return AccountRole.guest;
    }

    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return AccountRole.guest;

    final role = await client.rpc('current_user_role');
    return role == 'admin' ? AccountRole.admin : AccountRole.user;
  }

  static Future<bool> isAdmin() async =>
      await currentRole() == AccountRole.admin;
}