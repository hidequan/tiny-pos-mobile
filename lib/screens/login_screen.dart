import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../data/models.dart';
import '../theme/typography.dart';
import '../widgets/common.dart';

/// `#login` — role picker on a dark espresso gradient.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1),
          end: Alignment(0.4, 1),
          colors: [Color(0xFF2A160C), Color(0xFF160B05)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 54),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC75B39), Color(0xFFD98A4E)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: const Color(0xFFC75B39).withValues(alpha: 0.7), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                alignment: Alignment.center,
                child: const Text('☕', style: TextStyle(fontSize: 38)),
              ),
              const SizedBox(height: 16),
              Text('Tiny POS', style: AppType.display(size: 32, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Hệ thống bán hàng chuỗi cà phê',
                  style: AppType.body(size: 13.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.62))),
              const SizedBox(height: 36),
              _RoleCard(
                emoji: '🧾',
                colors: const [Color(0xFFC75B39), Color(0xFFD98A4E)],
                title: 'Thu ngân',
                sub: 'Bán hàng tại quầy · take-away & tại bàn',
                onTap: () => state.enterRole(Role.cashier),
              ),
              const SizedBox(height: 13),
              _RoleCard(
                emoji: '🍳',
                colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)],
                title: 'KDS / Bar',
                sub: 'Màn hình pha chế real-time · FIFO',
                onTap: () => state.enterRole(Role.kds),
              ),
              const SizedBox(height: 13),
              _RoleCard(
                emoji: '⚙️',
                colors: const [Color(0xFF3A1F12), Color(0xFF6F4E37)],
                title: 'Quản trị',
                sub: 'Menu · kho/BOM · ca · báo cáo · RBAC',
                onTap: () => state.enterRole(Role.admin),
              ),
              const SizedBox(height: 30),
              Text('v0.1.1 · chọn vai trò để xem giao diện tương ứng',
                  textAlign: TextAlign.center,
                  style: AppType.body(size: 11.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.4))),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final List<Color> colors;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _RoleCard({required this.emoji, required this.colors, required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppType.body(size: 16.5, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppType.body(size: 12.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Text('→', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}
