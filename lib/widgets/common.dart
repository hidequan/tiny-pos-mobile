import 'package:flutter/material.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../theme/app_icons.dart';

/// Press-scale wrapper (the `:active{transform:scale()}` effect in the mockup).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}

/// `.iconbtn` — 40x40 rounded square button.
class IconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final bool dot;
  final Color? bg;
  final Color? fg;
  final double iconSize;
  const IconBtn(this.icon, {super.key, this.onTap, this.dot = false, this.bg, this.fg, this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      scale: 0.92,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg ?? p.paper,
              borderRadius: BorderRadius.circular(13),
              border: bg == null ? Border.all(color: p.line2) : null,
              boxShadow: const [BoxShadow(color: Color(0x10241008), blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: Icon(AppIcons.get(icon), size: iconSize, color: fg ?? p.ink),
          ),
          if (dot)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.terracotta,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.paper, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.avatar` — gradient initials chip.
class Avatar extends StatelessWidget {
  final String initials;
  final VoidCallback? onTap;
  final double size;
  final List<Color>? colors;
  const Avatar(this.initials, {super.key, this.onTap, this.size = 40, this.colors});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.92,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors ?? const [Color(0xFFC75B39), Color(0xFFD98A4E)],
          ),
          borderRadius: BorderRadius.circular(size * 0.325),
        ),
        alignment: Alignment.center,
        child: Text(initials,
            style: AppType.body(size: size * 0.375, weight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}

enum BtnVariant { pri, dark, ghost, soft }

/// `.btn` with variants.
class AppButton extends StatelessWidget {
  final String label;
  final String? icon;
  final BtnVariant variant;
  final VoidCallback? onTap;
  final bool large;
  final bool block;
  final bool enabled;
  final Color? textColor;
  const AppButton(
    this.label, {
    super.key,
    this.icon,
    this.variant = BtnVariant.pri,
    this.onTap,
    this.large = false,
    this.block = false,
    this.enabled = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadow;
    switch (variant) {
      case BtnVariant.pri:
        bg = p.terracotta;
        fg = Colors.white;
        shadow = [BoxShadow(color: p.terracotta.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))];
        break;
      case BtnVariant.dark:
        bg = p.espresso;
        fg = Colors.white;
        break;
      case BtnVariant.ghost:
        bg = p.paper;
        fg = p.ink;
        border = Border.all(color: p.line2);
        shadow = const [BoxShadow(color: Color(0x10241008), blurRadius: 3, offset: Offset(0, 1))];
        break;
      case BtnVariant.soft:
        bg = p.cream2;
        fg = p.ink;
        break;
    }
    final child = Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: block ? double.infinity : null,
        padding: EdgeInsets.symmetric(vertical: large ? 16 : 13, horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(large ? 16 : 14),
          border: border,
          boxShadow: enabled ? shadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(AppIcons.get(icon!), size: 19, color: textColor ?? fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body(size: large ? 16.5 : 15, weight: FontWeight.w700, color: textColor ?? fg)),
            ),
          ],
        ),
      ),
    );
    return Pressable(scale: 0.97, onTap: enabled ? onTap : null, child: child);
  }
}

/// `.chip` — horizontally-scrolling filter pill.
class PillChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool on;
  final VoidCallback? onTap;
  const PillChip(this.label, {super.key, this.emoji, this.on = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: on ? p.espresso : p.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? p.espresso : p.line2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: AppType.body(size: 13.5, weight: FontWeight.w700, color: on ? Colors.white : p.ink2)),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scroll strip of chips with the mockup's 16px padding.
class ChipsRow extends StatelessWidget {
  final List<Widget> children;
  const ChipsRow({super.key, required this.children});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
        itemBuilder: (_, i) => children[i],
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: children.length,
      ),
    );
  }
}

/// `.badge` color variants.
enum BadgeColor { green, amber, red, blue, gray }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeColor color;
  final bool pulse;
  const AppBadge(this.label, {super.key, this.color = BadgeColor.gray, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Color bg;
    Color fg;
    switch (color) {
      case BadgeColor.green:
        bg = p.greenBg;
        fg = p.greenD;
        break;
      case BadgeColor.amber:
        bg = p.amberBg;
        fg = p.amber;
        break;
      case BadgeColor.red:
        bg = p.redBg;
        fg = p.red;
        break;
      case BadgeColor.blue:
        bg = p.blueBg;
        fg = p.blue;
        break;
      case BadgeColor.gray:
        bg = p.cream2;
        fg = p.ink2;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            _Pulse(color: fg),
            const SizedBox(width: 5),
          ],
          Text(label, style: AppType.body(size: 11, weight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  final Color color;
  const _Pulse({required this.color});
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.3).animate(_c),
      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}

/// `.sw` toggle switch.
class SwitchDot extends StatelessWidget {
  final bool on;
  final VoidCallback? onTap;
  const SwitchDot({super.key, required this.on, this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 27,
        decoration: BoxDecoration(color: on ? p.green : p.line2, borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: 3,
              left: on ? 22 : 3,
              child: Container(
                width: 21,
                height: 21,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.card` container.
class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool clip;
  const CardBox({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.borderColor,
    this.radius = 16,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? p.paper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.line),
        boxShadow: const [BoxShadow(color: Color(0x0F3C1E0A), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: child,
    );
  }
}

/// `.sec-h` section header.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double titleSize;
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.titleSize = 17});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: AppType.display(size: titleSize, color: p.ink))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: AppType.body(size: 13, weight: FontWeight.w700, color: p.terracotta)),
            ),
        ],
      ),
    );
  }
}

/// `.lrow` list row: leading icon/emoji, title + subtitle, trailing.
class ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final FontWeight titleWeight;
  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: p.paper,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppType.body(size: 14.5, weight: titleWeight, color: p.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// `.lic` rounded leading icon container.
class LeadIcon extends StatelessWidget {
  final String? icon;
  final String? emoji;
  final Color? bg;
  final Color? fg;
  final double size;
  const LeadIcon({super.key, this.icon, this.emoji, this.bg, this.fg, this.size = 42});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg ?? p.cream2, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.48))
          : Icon(AppIcons.get(icon ?? 'coffee'), size: size * 0.48, color: fg ?? p.ink),
    );
  }
}

/// Divider list (rows separated by a hairline) inside a clipped card.
class RowList extends StatelessWidget {
  final List<Widget> children;
  const RowList(this.children, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(Container(height: 1, color: p.line));
      out.add(children[i]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: out);
  }
}

/// `.kv` key-value row.
class KvRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool last;
  final double size;
  final EdgeInsets? padding;
  const KvRow(this.label, this.value, {super.key, this.last = false, this.size = 14, this.padding});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body(size: size, weight: FontWeight.w600, color: p.ink2)),
          ),
          const SizedBox(width: 10),
          value,
        ],
      ),
    );
  }
}

/// `.stepper` quantity control.
class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChange;
  final bool small;
  const QtyStepper({super.key, required this.value, required this.onChange, this.small = false});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final btn = small ? 32.0 : 38.0;
    Widget b(String s, int d) => InkWell(
          onTap: () => onChange(d),
          child: SizedBox(
            width: btn,
            height: btn,
            child: Center(
                child: Text(s, style: TextStyle(fontSize: small ? 17 : 20, fontWeight: FontWeight.w700, color: p.ink))),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          b('−', -1),
          SizedBox(
            width: small ? 24 : 30,
            child: Center(
                child: Text('$value',
                    style: AppType.body(size: small ? 14 : 15, weight: FontWeight.w800, color: p.ink))),
          ),
          b('+', 1),
        ],
      ),
    );
  }
}

/// `.empty` empty-state block.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? sub;
  const EmptyState({super.key, required this.emoji, required this.title, this.sub});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: 0.5, child: Text(emoji, style: const TextStyle(fontSize: 46))),
          const SizedBox(height: 12),
          Text(title, style: AppType.display(size: 15, color: p.ink)),
          if (sub != null) ...[
            const SizedBox(height: 5),
            Text(sub!, textAlign: TextAlign.center, style: AppType.body(size: 13, color: p.muted)),
          ],
        ],
      ),
    );
  }
}

/// `.topbar` — title + subtitle on the left, actions on the right.
class TopBar extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  const TopBar({super.key, required this.title, this.subtitle, this.actions = const [], this.leading});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      color: p.cream,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          // Expanded so a long title/subtitle shrinks (ellipsis) instead of
          // pushing the action buttons off the right edge.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.display(size: 21, height: 1.05, color: p.ink)),
                if (subtitle != null) ...[const SizedBox(height: 1), subtitle!],
              ],
            ),
          ),
          const SizedBox(width: 10),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            actions[i],
          ],
        ],
      ),
    );
  }
}

/// `.seg` segmented control.
class Segmented extends StatelessWidget {
  final List<String> labels;
  final List<String?> icons;
  final int active;
  final ValueChanged<int> onTap;
  const Segmented({super.key, required this.labels, required this.active, required this.onTap, this.icons = const []});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active == i ? p.paper : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: active == i
                        ? const [BoxShadow(color: Color(0x10241008), blurRadius: 3, offset: Offset(0, 1))]
                        : null,
                  ),
                  // Scale the label down to fit narrow segments instead of
                  // overflowing (e.g. "Định lượng (BOM)").
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i < icons.length && icons[i] != null) ...[
                          Icon(AppIcons.get(icons[i]!), size: 18, color: active == i ? p.ink : p.ink2),
                          const SizedBox(width: 7),
                        ],
                        Text(labels[i],
                            style: AppType.body(size: 13.5, weight: FontWeight.w800, color: active == i ? p.ink : p.ink2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.hero` revenue gradient card.
class HeroCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? footer;
  final List<Color>? gradient;
  const HeroCard({super.key, required this.label, required this.value, this.footer, this.gradient});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient ?? [p.espresso, p.espresso2, const Color(0xFF5A2F1C)],
          // stops only match the default 3-colour gradient; a custom gradient
          // (e.g. the 2-colour reports hero) must not reuse them.
          stops: gradient == null ? const [0, 0.6, 1] : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppType.body(size: 13, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 3),
          Text(value, style: AppType.display(size: 34, color: Colors.white)),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: footer!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
