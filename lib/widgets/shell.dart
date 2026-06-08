import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../theme/app_icons.dart';

/// Controls the bottom-sheet + toast overlays that live INSIDE the phone frame
/// (so they never spill outside the centered 480px column on web).
class ShellController extends ChangeNotifier {
  WidgetBuilder? _sheet;
  WidgetBuilder? get sheet => _sheet;

  String? toastMsg;
  String? toastIcon;
  int toastSeq = 0;
  Timer? _toastTimer;

  void showSheet(WidgetBuilder builder) {
    _sheet = builder;
    notifyListeners();
  }

  void closeSheet() {
    if (_sheet == null) return;
    _sheet = null;
    notifyListeners();
  }

  void toast(String msg, [String? icon]) {
    toastMsg = msg;
    toastIcon = icon;
    toastSeq++;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      toastMsg = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}

/// Inherited access to the [ShellController] for the current phone frame.
class ShellScope extends InheritedNotifier<ShellController> {
  const ShellScope({super.key, required ShellController controller, required super.child})
      : super(notifier: controller);

  static ShellController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellScope>();
    assert(scope != null, 'ShellScope not found');
    return scope!.notifier!;
  }
}

extension ShellContext on BuildContext {
  ShellController get shell => ShellScope.of(this);
}

/// Standard sheet chrome: grab handle, header row, scrollable body, footer.
class AppSheet extends StatelessWidget {
  final String? title;
  final List<Widget> headerExtra;
  final Widget body;
  final Widget? footer;
  final bool showClose;
  const AppSheet({
    super.key,
    this.title,
    this.headerExtra = const [],
    required this.body,
    this.footer,
    this.showClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            margin: const EdgeInsets.fromLTRB(0, 9, 0, 2),
            decoration: BoxDecoration(color: p.line2, borderRadius: BorderRadius.circular(3)),
          ),
          if (title != null || headerExtra.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(child: Text(title!, style: AppType.display(size: 19, color: p.ink))),
                  ...headerExtra,
                  if (showClose) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => context.shell.closeSheet(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.close_rounded, size: 18, color: p.ink2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: body,
            ),
          ),
          if (footer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(
                color: p.cream,
                border: Border(top: BorderSide(color: p.line)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// The animated scrim + sheet + toast layer painted on top of the phone body.
class ShellOverlay extends StatelessWidget {
  const ShellOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.shell;
    final p = context.palette;
    final hasSheet = shell.sheet != null;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !hasSheet && shell.toastMsg == null,
        child: Stack(
          children: [
            // scrim
            IgnorePointer(
              ignoring: !hasSheet,
              child: GestureDetector(
                onTap: shell.closeSheet,
                child: AnimatedOpacity(
                  opacity: hasSheet ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(color: const Color(0x80140803)),
                ),
              ),
            ),
            // sheet
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: hasSheet ? 0 : -1000,
              child: hasSheet
                  ? ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
                      child: Material(
                        color: Colors.transparent,
                        child: shell.sheet!(context),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // toast
            if (shell.toastMsg != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 96,
                child: Center(
                  child: _Toast(
                    key: ValueKey(shell.toastSeq),
                    msg: shell.toastMsg!,
                    icon: shell.toastIcon,
                    paper: p.espresso,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  final String msg;
  final String? icon;
  final Color paper;
  const _Toast({super.key, required this.msg, this.icon, required this.paper});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x47281206), blurRadius: 50, offset: Offset(0, 18))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(AppIcons.get(icon!), size: 18, color: Colors.white),
              const SizedBox(width: 9),
            ],
            Flexible(child: Text(msg, style: AppType.body(size: 13.5, weight: FontWeight.w700, color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
