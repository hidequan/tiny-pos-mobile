import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_config.dart';
import '../../state/session.dart';
import '../../theme/typography.dart';

/// Real username/password login against the shared tiny-pos backend.
class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});
  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final ok = await context.read<SessionState>().login(_user.text, _pass.text);
    if (mounted) setState(() => _busy = false);
    if (!ok && mounted) {
      final err = context.read<SessionState>().lastError ?? 'Đăng nhập thất bại';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
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
              const SizedBox(height: 56),
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
              Text('Đăng nhập để tiếp tục',
                  style: AppType.body(size: 13.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.62))),
              const SizedBox(height: 34),
              _field(controller: _user, hint: 'Tên đăng nhập', icon: Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _field(
                controller: _pass,
                hint: 'Mật khẩu',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                onSubmit: _submit,
                trailing: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.5), size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _busy ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC75B39),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFFC75B39).withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  alignment: Alignment.center,
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text('Đăng nhập', style: AppType.body(size: 16.5, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                ApiConfig.isProduction
                    ? 'Kết nối: pos.lptech.info.vn'
                    : 'Kết nối: ${ApiConfig.baseUrl}',
                textAlign: TextAlign.center,
                style: AppType.body(size: 11, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.35)),
              ),
              const SizedBox(height: 24),
              if (session.status == SessionStatus.loading)
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? trailing,
    VoidCallback? onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onSubmitted: (_) => onSubmit?.call(),
            textInputAction: onSubmit != null ? TextInputAction.done : TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            style: AppType.body(size: 15, weight: FontWeight.w600, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              hintText: hint,
              hintStyle: AppType.body(size: 15, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
        ),
        ?trailing,
      ]),
    );
  }
}
