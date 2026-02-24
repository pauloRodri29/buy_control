import 'package:flutter/material.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';

class ModernDropdownList extends StatefulWidget {
  final String? hint;

  /// Valor selecionado (salva a KEY)
  final String? valueKey;

  /// Lista de itens: [{"key": "KG", "label": "Quilo (kg)"}]
  final List<Map<String, String>> items;

  /// Se true, mostra a KEY no campo/lista; se false, mostra LABEL (prioridade)
  final bool showKey;

  final bool readOnly;
  final bool filled;
  final Color? fillColor;
  final Color? borderColor;

  final Widget? prefix;
  final Widget? suffix;

  final bool error;
  final String? errorText;

  final double panelMaxHeight;

  /// Retorna a KEY selecionada
  final ValueChanged<String> onChanged;

  const ModernDropdownList({
    super.key,
    required this.items,
    required this.onChanged,
    this.valueKey,
    this.hint,
    this.showKey = false,
    this.readOnly = false,
    this.filled = true,
    this.fillColor,
    this.borderColor,
    this.prefix,
    this.suffix,
    this.error = false,
    this.errorText,
    this.panelMaxHeight = 240,
  });

  @override
  State<ModernDropdownList> createState() => _ModernDropdownListState();
}

class _ModernDropdownListState extends State<ModernDropdownList> {
  bool _isOpen = false;

  void _toggle() {
    if (widget.readOnly) return;
    setState(() => _isOpen = !_isOpen);
  }

  void _close() {
    if (_isOpen) setState(() => _isOpen = false);
  }

  String _getKey(Map<String, String> item) => item['key'] ?? '';

  String _getLabel(Map<String, String> item) => item['label'] ?? '';

  /// Texto exibido com prioridade pro label
  String _displayText(Map<String, String> item) {
    final key = _getKey(item);
    final label = _getLabel(item);

    if (widget.showKey) return key;
    return label.isNotEmpty ? label : key;
  }

  Map<String, String>? _selectedItem() {
    if (widget.valueKey == null) return null;
    for (final item in widget.items) {
      if (_getKey(item) == widget.valueKey) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem();

    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _close();
        setState(() {});
      },
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          final hasFocus = focusNode.hasFocus;

          final border = widget.error
              ? AppColors.error
              : (hasFocus || _isOpen)
                  ? AppColors.backgroundDark
                  : (widget.borderColor ?? AppColors.borderLight);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.error) ...[
                TextCustom(
                  text: widget.errorText ?? "",
                  color: AppColors.error,
                  fontSize: AppFontSizes.fz04,
                ),
                const SizedBox(height: 4),
              ],

              // Campo "fechado"
              GestureDetector(
                onTap: _toggle,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.filled
                        ? (widget.fillColor ?? AppColors.textPrimaryDark)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      if (widget.prefix != null) ...[
                        widget.prefix!,
                        const SizedBox(width: 8),
                      ],

                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextCustom(
                            text: (selected == null)
                                ? (widget.hint ?? "")
                                : _displayText(selected),
                            color: (selected == null)
                                ? AppColors.textSecondaryLight
                                : AppColors.textPrimaryLight,
                            fontSize: AppFontSizes.fz10,
                          ),
                        ),
                      ),

                      if (widget.suffix != null) ...[
                        const SizedBox(width: 8),
                        widget.suffix!,
                      ] else ...[
                        const SizedBox(width: 8),
                        Icon(
                          _isOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondaryLight,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Painel aberto (lista visível)
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: widget.filled
                        ? (widget.fillColor ?? AppColors.textPrimaryDark)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: widget.panelMaxHeight),
                    child: Scrollbar(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: (widget.borderColor ?? AppColors.borderLight)
                              .withValues(alpha: 0.5),
                        ),
                        itemBuilder: (_, i) {
                          final item = widget.items[i];
                          final key = _getKey(item);
                          final selected = key == widget.valueKey;

                          return InkWell(
                            onTap: () {
                              widget.onChanged(key); // sempre retorna a KEY
                              _close();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextCustom(
                                      text: _displayText(item),
                                      color: selected
                                          ? AppColors.textPrimaryLight
                                          : AppColors.textSecondaryLight,
                                      fontSize: AppFontSizes.fz10,
                                    ),
                                  ),
                                  if (selected)
                                    Icon(
                                      Icons.check_rounded,
                                      color: AppColors.textPrimaryLight,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                crossFadeState: _isOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 150),
              ),
            ],
          );
        },
      ),
    );
  }
}