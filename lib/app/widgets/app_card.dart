import 'package:buy_control/app/theme/app_durations.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// [Card] nativo (cor, borda e raio vêm do `cardTheme`) com toque opcional
/// e um leve "afundar" ao pressionar.
class AppCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final content = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
        child: widget.child,
      ),
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: AppDurations.fast,
      curve: Curves.easeOut,
      child: Card(
        child: interactive
            ? InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onTapDown: (_) => _setPressed(true),
                onTapCancel: () => _setPressed(false),
                onTapUp: (_) => _setPressed(false),
                child: content,
              )
            : content,
      ),
    );
  }
}
