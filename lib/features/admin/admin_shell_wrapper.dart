import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/shop_repository.dart';
import '../shop/shop_shell.dart';
import 'admin_shell.dart';
import 'admin_view_mode.dart';

/// Wrapper component that manages switching between admin and shop interfaces.
/// 
/// This widget listens to [AdminViewMode.showShopInterface] and renders either:
/// - The admin interface when showShopInterface is false
/// - The shop interface when showShopInterface is true
/// 
/// Admin users can switch modes from the admin home page or shop shell.
class AdminShellWrapper extends StatelessWidget {
  const AdminShellWrapper({
    required this.authService,
    required this.user,
    required this.repository,
    super.key,
  });

  final AuthService authService;
  final User user;
  final ShopRepository repository;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminViewMode.showShopInterface,
      builder: (context, showShop, _) {
        if (showShop) {
          // Show shop interface - admin can toggle back via button
          return ShopShell(
            authService: authService,
            user: user,
          );
        } else {
          // Show admin interface
          return AdminShell(
            repository: repository,
            userId: user.uid,
          );
        }
      },
    );
  }
}
