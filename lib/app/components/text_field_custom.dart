import 'package:buy_control/app/components/text_custom.dart';
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
  final int? maxLength;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
  final bool error;

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
    this.errorText,
    this.error = false,
    this.maxLength,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller?.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ModernTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _controller = widget.controller;
      _controller?.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textLength = widget.controller?.text.length ?? 0;
    final maxLength = widget.maxLength; // pode ser null

    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          final hasFocus = focusNode.hasFocus;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.error)
                    TextCustom(
                      text: widget.errorText ?? "",
                      color: AppColors.error,
                      fontSize: AppFontSizes.fz04,
                    )
                  else
                    const SizedBox(),

                  if (maxLength != null)
                    TextCustom(
                      text: "$textLength/$maxLength",
                      color: textLength >= maxLength
                          ? AppColors.error
                          : AppColors.textSecondaryLight,
                      fontSize: AppFontSizes.fz04,
                    )
                  else
                    const SizedBox(),
                ],
              ),
              const SizedBox(height: 4),

              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 50,
                decoration: BoxDecoration(
                  color: widget.filled
                      ? (widget.fillColor ?? AppColors.textPrimaryDark)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.error
                        ? AppColors.error
                        : hasFocus
                        ? AppColors.backgroundDark
                        : (widget.borderColor ?? AppColors.borderLight),
                  ),
                ),
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
                        maxLength: maxLength,
                        onTap: widget.onTap,
                        style: TextStyle(
                          fontSize: AppFontSizes.fz10,
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          counterText: '', // esconde o contador padrão
                          border: InputBorder.none,
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
              ),
            ],
          );
        },
      ),
    );
  }
}
