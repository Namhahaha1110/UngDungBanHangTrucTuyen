import 'package:flutter/material.dart';

class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFf0f0f0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(color: Color(0xFFea580c)),
                SizedBox(height: 16),
                Text(
                  'Đang tải dữ liệu...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFfff1f1),
            border: Border.all(color: const Color(0xFFef4444)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFef4444),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.error, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lỗi tải dữ liệu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFef4444),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFfff2e8),
            border: Border.all(color: const Color(0xFFffd2b1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFea580c),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.inbox, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFea580c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
