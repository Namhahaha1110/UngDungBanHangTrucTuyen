import 'package:flutter/material.dart';

class AdminStatusBar extends StatelessWidget {
  const AdminStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xFFea580c),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '5:10',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const Text(
            '▮▮▮ ))) ◔',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    required this.title,
    this.onBackTap,
    this.onActionTap,
    this.onMenuTap,
    this.actionIcon = '＋',
    this.showBack = false,
    super.key,
  });

  final String title;
  final VoidCallback? onBackTap;
  final VoidCallback? onActionTap;
  final VoidCallback? onMenuTap;
  final String actionIcon;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: const Color(0xFFECECEC))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onMenuTap ?? onBackTap ?? () => Navigator.pop(context),
            child: Text(
              showBack ? '‹' : '≡',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFFea580c),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionIcon,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFFea580c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPageWrapper extends StatelessWidget {
  const AdminPageWrapper({
    required this.title,
    required this.child,
    this.onActionTap,
    this.actionIcon = '＋',
    this.showBack = false,
    this.onBackTap,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback? onActionTap;
  final String actionIcon;
  final bool showBack;
  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminStatusBar(),
        AdminTopBar(
          title: title,
          onActionTap: onActionTap,
          actionIcon: actionIcon,
          showBack: showBack,
          onBackTap: onBackTap,
        ),
        Expanded(child: child),
      ],
    );
  }
}
