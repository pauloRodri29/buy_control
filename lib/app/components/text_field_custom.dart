import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';

class ModernTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool readOnly;
  final bool isValid;
  final bool autofocus;
  final bool filled;
  final Color? fillColor;
  final Color? borderColor;
  final int maxLines;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Widget? prefix;
  final Widget? suffix;

  const ModernTextField({
    super.key,
    this.controller,
    this.hint,
    this.readOnly = false,
    this.isValid = true,
    this.autofocus = false,
    this.filled = true,
    this.fillColor,
    this.borderColor,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.prefix,
    this.suffix,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller?.text.isNotEmpty ?? false;

    return StatefulBuilder(
      builder: (_, setState) {
        return Focus(
          onFocusChange: (_) => setState(() {}),
          child: Builder(
            builder: (context) {
              final focusNode = Focus.of(context);
              final hasFocus = focusNode.hasFocus;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 50,
                decoration: BoxDecoration(
                  color: widget.filled
                      ? (widget.fillColor ?? AppColors.textPrimaryDark)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: !widget.isValid
                        ? Colors.red
                        : hasFocus
                        ? AppColors.backgroundDark
                        : (widget.borderColor ?? AppColors.borderLight),
                    width: hasFocus ? 1.3 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    if (widget.prefix != null) ...[
                      widget.prefix!,
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        autofocus: widget.autofocus,
                        readOnly: widget.readOnly,
                        inputFormatters: widget.inputFormatters,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        textAlign: widget.textAlign,
                        onChanged: widget.onChanged,
                        maxLines: widget.maxLines,
                        onTap: widget.onTap,
                        style: TextStyle(
                          fontSize: AppFontSizes.fz10,
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none, // Adicionedwed
                          focusedBorder: InputBorder.none, // Adicione
                          errorBorder: InputBorder.none, // Adicione
                          disabledBorder: InputBorder.none, // Adicione
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: widget.hint,
                          hintStyle: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: AppFontSizes.fz08,
                          ),
                        ),
                      ),
                    ),
                    if (widget.suffix != null) ...[
                      const SizedBox(width: 8),
                      widget.suffix!,
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
