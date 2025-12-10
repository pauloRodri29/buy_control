import 'package:buy_control/app/components/lucide_icon_container.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ButtonCircle extends StatefulWidget {
  final IconData icon;
  final Color? backgroundColor;
  final Color? color;
  final double? size;
  final Color? colorIcon;
  final double? sizeIcon;
  final bool border;
  final void Function()? onPressed;

  const ButtonCircle({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.color,
    this.size = 40,
    this.onPressed,
    this.colorIcon,
    this.sizeIcon,
    this.border = false,
  });

  @override
  State<ButtonCircle> createState() => _ButtonCircleState();
}

class _ButtonCircleState extends State<ButtonCircle> {
  bool _pressed = false;

  void _runAnimation(VoidCallback? action) async {
    setState(() => _pressed = true);
    await Future.delayed(120.ms);
    setState(() => _pressed = false);

    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _runAnimation(widget.onPressed),
      child:
          Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? AppColors.buttonPrimaryDark,
                  shape: BoxShape.circle,
                  border: widget.border
                      ? Border.all(
                          color: AppColors.buttonPrimaryLight,
                          width: 1,
                        )
                      : null,
                ),
                constraints: BoxConstraints(
                  minHeight: widget.size!,
                  minWidth: widget.size!,
                ),
                child: LucideIconContainer(
                  icon: widget.icon,
                  size: widget.sizeIcon ?? (widget.size! * 0.5),
                  color: widget.colorIcon ?? AppColors.buttonSecondaryLight,
                ),
              )
              .animate(target: _pressed ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(0.85, 0.85),
                duration: 120.ms,
                curve: Curves.easeOut,
              ),
    );
  }
}
