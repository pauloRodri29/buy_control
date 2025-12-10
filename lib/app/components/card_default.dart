import 'dart:developer';

import 'package:buy_control/app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CardDefault extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color? color;
  final double? radius;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  const CardDefault({
    super.key,
    required this.child,
    this.width,
    this.color = AppColors.cardDark,
    this.radius,
    this.padding,
    this.onPressed,
    this.height, this.onLongPressed,
  });

  @override
  State<CardDefault> createState() => _CardDefaultState();
}

class _CardDefaultState extends State<CardDefault> {
  bool _pressed = false;

  void _runAnimation(VoidCallback? action) async {
    setState(() => _pressed = true);
    await Future.delayed(120.ms);
    setState(() => _pressed = false);

    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _runAnimation(widget.onPressed),
      onLongPress: () {
        widget.onLongPressed?.call();
        log("onLongPress");
      },
      child:
          Container(
                padding: widget.padding ?? EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: widget.radius != null
                      ? BorderRadius.circular(widget.radius!)
                      : BorderRadius.circular(12),
                ),
                width: widget.width,
                height: widget.height,
                child: widget.child,
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
