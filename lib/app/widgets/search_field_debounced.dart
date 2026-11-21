import 'package:get/get.dart';
import 'dart:async';

import 'package:buy_control/app/theme/app_durations.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Campo de busca nativo ([TextField]) que só avisa a mudança depois de
/// uma pausa na digitação. Sem borda em repouso; ao focar, usa a borda de
/// foco do `inputDecorationTheme`.
class SearchFieldDebounced extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  const SearchFieldDebounced({
    super.key,
    this.hint = 'common.search',
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

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noBorder = OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: BorderSide.none);

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint.tr,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        prefixIcon: const Icon(Symbols.search, size: 18),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Symbols.close, size: 16), tooltip: 'common.clear'.tr, onPressed: _clear),
        border: noBorder,
        enabledBorder: noBorder,
      ),
    );
  }
}
