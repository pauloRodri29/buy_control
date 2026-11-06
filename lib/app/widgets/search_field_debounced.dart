import 'dart:async';

import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_durations.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SearchFieldDebounced extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  const SearchFieldDebounced({
    super.key,
    this.hint = 'Buscar',
    required this.onChanged,
    this.debounce = AppDurations.searchDebounce,
  });

  @override
  State<SearchFieldDebounced> createState() => _SearchFieldDebouncedState();
}

class _SearchFieldDebouncedState extends State<SearchFieldDebounced> {
  final _controller = TextEditingController();
  Timer? _timer;

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(isDark),
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary(isDark)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: TextStyle(color: AppColors.textPrimary(isDark)),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: widget.hint,
                hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                _onChanged('');
              },
              child: Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary(isDark)),
            ),
        ],
      ),
    );
  }
}
