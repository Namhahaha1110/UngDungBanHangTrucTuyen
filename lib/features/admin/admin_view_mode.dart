import 'package:flutter/foundation.dart';

/// Global state notifier để quản lý chuyển đổi giữa giao diện admin và shop.
/// 
/// - `showShopInterface = false` → hiển thị admin interface
/// - `showShopInterface = true` → hiển thị shop interface
class AdminViewMode {
  AdminViewMode._();

  static final ValueNotifier<bool> showShopInterface = ValueNotifier(false);

  static void openAdmin() {
    showShopInterface.value = false;
  }

  static void openShop() {
    showShopInterface.value = true;
  }
}
