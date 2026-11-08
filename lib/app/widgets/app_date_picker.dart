import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

/// Atalho exibido acima do calendário ("Hoje", "Fim do mês"...).
class AppDateShortcut {
  final String label;
  final DateTime date;
  const AppDateShortcut(this.label, this.date);
}

/// Atalho de intervalo ("Este mês", "Últimos 30 dias"...).
class AppDateRangeShortcut {
  final String label;
  final DateTimeRange range;
  const AppDateRangeShortcut(this.label, this.range);
}

/// Seletor de data do app, em bottom sheet, no lugar do `showDatePicker`
/// nativo. Usa `table_calendar` com o visual do design system (cores,
/// raios, tipografia) e suporta data única ou intervalo.
class AppDatePicker {
  AppDatePicker._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Atalhos comuns para datas futuras (planejamento).
  static List<AppDateShortcut> futureShortcuts() {
    final today = _dateOnly(DateTime.now());
    return [
      AppDateShortcut('Hoje', today),
      AppDateShortcut('Fim do mês', DateTime(today.year, today.month + 1, 0)),
      AppDateShortcut('Próximo mês', DateTime(today.year, today.month + 2, 0)),
      AppDateShortcut('Fim do ano', DateTime(today.year, 12, 31)),
    ];
  }

  /// Atalhos comuns para datas passadas/recentes (registro de compras).
  static List<AppDateShortcut> recentShortcuts() {
    final today = _dateOnly(DateTime.now());
    return [
      AppDateShortcut('Hoje', today),
      AppDateShortcut('Ontem', today.subtract(const Duration(days: 1))),
      AppDateShortcut('Fim do mês passado', DateTime(today.year, today.month, 0)),
    ];
  }

  static List<AppDateRangeShortcut> rangeShortcuts() {
    final today = _dateOnly(DateTime.now());
    return [
      AppDateRangeShortcut('Últimos 7 dias', DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today)),
      AppDateRangeShortcut('Últimos 30 dias', DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today)),
      AppDateRangeShortcut('Este mês', DateTimeRange(start: DateTime(today.year, today.month, 1), end: today)),
      AppDateRangeShortcut(
        'Mês passado',
        DateTimeRange(start: DateTime(today.year, today.month - 1, 1), end: DateTime(today.year, today.month, 0)),
      ),
    ];
  }

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String confirmLabel = 'Confirmar',
    List<AppDateShortcut> shortcuts = const [],
  }) {
    return AppBottomSheet.show<DateTime>(
      context,
      child: _AppDatePickerSheet(
        title: title,
        confirmLabel: confirmLabel,
        firstDate: _dateOnly(firstDate),
        lastDate: _dateOnly(lastDate),
        initialDate: _dateOnly(initialDate),
        shortcuts: shortcuts,
      ),
    );
  }

  static Future<DateTimeRange?> showRange(
    BuildContext context, {
    required String title,
    DateTimeRange? initialRange,
    required DateTime firstDate,
    required DateTime lastDate,
    String confirmLabel = 'Aplicar',
    List<AppDateRangeShortcut> shortcuts = const [],
  }) {
    return AppBottomSheet.show<DateTimeRange>(
      context,
      child: _AppDatePickerSheet(
        title: title,
        confirmLabel: confirmLabel,
        firstDate: _dateOnly(firstDate),
        lastDate: _dateOnly(lastDate),
        initialRange: initialRange == null
            ? null
            : DateTimeRange(start: _dateOnly(initialRange.start), end: _dateOnly(initialRange.end)),
        isRange: true,
        rangeShortcuts: shortcuts,
      ),
    );
  }
}

class _AppDatePickerSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final DateTimeRange? initialRange;
  final bool isRange;
  final List<AppDateShortcut> shortcuts;
  final List<AppDateRangeShortcut> rangeShortcuts;

  const _AppDatePickerSheet({
    required this.title,
    required this.confirmLabel,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.initialRange,
    this.isRange = false,
    this.shortcuts = const [],
    this.rangeShortcuts = const [],
  });

  @override
  State<_AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<_AppDatePickerSheet> {
  static const _locale = 'pt_BR';

  late DateTime focusedDay;
  DateTime? selectedDay;
  DateTime? rangeStart;
  DateTime? rangeEnd;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDate;
    rangeStart = widget.initialRange?.start;
    rangeEnd = widget.initialRange?.end;
    focusedDay = _clamp(selectedDay ?? rangeEnd ?? DateTime.now());
  }

  DateTime _clamp(DateTime d) {
    if (d.isBefore(widget.firstDate)) return widget.firstDate;
    if (d.isAfter(widget.lastDate)) return widget.lastDate;
    return d;
  }

  bool _within(DateTime d) => !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  bool get _canConfirm => widget.isRange ? rangeStart != null : selectedDay != null;

  void _confirm() {
    if (widget.isRange) {
      final start = rangeStart!;
      Navigator.of(context).pop(DateTimeRange(start: start, end: rangeEnd ?? start));
    } else {
      Navigator.of(context).pop(selectedDay);
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String get _summary {
    final fmt = DateFormat("EEE, d 'de' MMM 'de' y", _locale);
    if (!widget.isRange) {
      return selectedDay == null ? 'Nenhuma data selecionada' : _capitalize(fmt.format(selectedDay!));
    }
    if (rangeStart == null) return 'Toque no dia inicial';
    final short = DateFormat('dd/MM/yyyy', _locale);
    final end = rangeEnd ?? rangeStart!;
    final days = end.difference(rangeStart!).inDays + 1;
    if (rangeEnd == null) return '${short.format(rangeStart!)} · toque no dia final';
    return '${short.format(rangeStart!)} → ${short.format(end)} · $days ${days == 1 ? 'dia' : 'dias'}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = AppColors.textPrimary(isDark);
    final secondaryText = AppColors.textSecondary(isDark);

    // Todas as decorações com o mesmo formato: o table_calendar anima entre
    // elas e não aceita misturar círculo com borda arredondada.
    BoxDecoration cell([Color? color, Border? border]) =>
        BoxDecoration(color: color, borderRadius: AppRadius.borderMd, border: border);
    final dayStyle = TextStyle(fontSize: AppFontSizes.fz07, color: primaryText, fontWeight: FontWeight.w500);
    const onAccent = TextStyle(
      fontSize: AppFontSizes.fz07,
      color: AppColors.textOnDarkButton,
      fontWeight: FontWeight.bold,
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title(widget.title, fontSize: AppFontSizes.fz09),
          if (widget.shortcuts.isNotEmpty || widget.rangeShortcuts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in widget.shortcuts.where((s) => _within(s.date)))
                    _ShortcutChip(
                      label: s.label,
                      selected: selectedDay != null && isSameDay(selectedDay, s.date),
                      onTap: () => setState(() {
                        selectedDay = s.date;
                        focusedDay = s.date;
                      }),
                    ),
                  for (final s in widget.rangeShortcuts)
                    _ShortcutChip(
                      label: s.label,
                      selected: rangeStart != null &&
                          isSameDay(rangeStart, s.range.start) &&
                          isSameDay(rangeEnd ?? rangeStart, s.range.end),
                      onTap: () => setState(() {
                        rangeStart = _clamp(s.range.start);
                        rangeEnd = _clamp(s.range.end);
                        focusedDay = rangeEnd!;
                      }),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant(isDark),
              borderRadius: AppRadius.borderLg,
            ),
            child: Column(
              children: [
                _MonthHeader(
                  title: _capitalize(DateFormat('MMMM y', _locale).format(focusedDay)),
                  canGoBack: DateTime(focusedDay.year, focusedDay.month).isAfter(
                    DateTime(widget.firstDate.year, widget.firstDate.month),
                  ),
                  canGoForward: DateTime(focusedDay.year, focusedDay.month).isBefore(
                    DateTime(widget.lastDate.year, widget.lastDate.month),
                  ),
                  onPrevious: () => _pageController?.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                  onNext: () => _pageController?.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                  onToday: _within(DateTime.now())
                      ? () => setState(() => focusedDay = AppDatePicker._dateOnly(DateTime.now()))
                      : null,
                ),
                const SizedBox(height: AppSpacing.xs),
                TableCalendar<void>(
                  locale: _locale,
                  firstDay: widget.firstDate,
                  lastDay: widget.lastDate,
                  focusedDay: focusedDay,
                  headerVisible: false,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  rowHeight: 44,
                  daysOfWeekHeight: 28,
                  onCalendarCreated: (controller) => _pageController = controller,
                  onPageChanged: (day) => setState(() => focusedDay = day),
                  rangeSelectionMode: widget.isRange ? RangeSelectionMode.toggledOn : RangeSelectionMode.toggledOff,
                  rangeStartDay: rangeStart,
                  rangeEndDay: rangeEnd,
                  selectedDayPredicate: (day) => !widget.isRange && isSameDay(selectedDay, day),
                  // O table_calendar entrega os dias em UTC; o app trabalha
                  // com datas locais sem horário.
                  onDaySelected: (selected, focused) => setState(() {
                    selectedDay = AppDatePicker._dateOnly(selected);
                    focusedDay = AppDatePicker._dateOnly(focused);
                  }),
                  onRangeSelected: (start, end, focused) => setState(() {
                    rangeStart = start == null ? null : AppDatePicker._dateOnly(start);
                    rangeEnd = end == null ? null : AppDatePicker._dateOnly(end);
                    focusedDay = AppDatePicker._dateOnly(focused);
                  }),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    dowTextFormatter: (date, locale) =>
                        DateFormat.E(locale).format(date).substring(0, 1).toUpperCase(),
                    weekdayStyle: TextStyle(
                      fontSize: AppFontSizes.fz05,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                    weekendStyle: TextStyle(
                      fontSize: AppFontSizes.fz05,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(3),
                    outsideDaysVisible: false,
                    defaultTextStyle: dayStyle,
                    weekendTextStyle: dayStyle,
                    holidayTextStyle: dayStyle,
                    defaultDecoration: cell(),
                    weekendDecoration: cell(),
                    holidayDecoration: cell(),
                    outsideDecoration: cell(),
                    disabledDecoration: cell(),
                    disabledTextStyle: TextStyle(
                      fontSize: AppFontSizes.fz07,
                      color: secondaryText.withValues(alpha: 0.35),
                    ),
                    todayDecoration: cell(null, Border.all(color: AppColors.accent, width: 1.5)),
                    todayTextStyle: dayStyle.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                    selectedDecoration: cell(AppColors.accent),
                    selectedTextStyle: onAccent,
                    rangeStartDecoration: cell(AppColors.accent),
                    rangeStartTextStyle: onAccent,
                    rangeEndDecoration: cell(AppColors.accent),
                    rangeEndTextStyle: onAccent,
                    withinRangeDecoration: cell(),
                    withinRangeTextStyle: dayStyle,
                    rangeHighlightColor: AppColors.accent.withValues(alpha: 0.15),
                    rangeHighlightScale: 0.82,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(LucideIcons.calendarCheck, size: 16, color: secondaryText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppText(_summary, fontSize: AppFontSizes.fz06, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppButton(label: widget.confirmLabel, onPressed: _canConfirm ? _confirm : null)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String title;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  const _MonthHeader({
    required this.title,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget arrow(IconData icon, bool enabled, VoidCallback onTap) {
      return Material(
        color: AppColors.surface(isDark),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? AppColors.textPrimary(isDark) : AppColors.textSecondary(isDark).withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: AppText(title, fontSize: AppFontSizes.fz08, fontWeight: FontWeight.bold)),
          if (onToday != null)
            TextButton(
              onPressed: onToday,
              style: TextButton.styleFrom(foregroundColor: AppColors.accent, visualDensity: VisualDensity.compact),
              child: const Text('Hoje'),
            ),
          arrow(LucideIcons.chevronLeft, canGoBack, onPrevious),
          const SizedBox(width: AppSpacing.xs),
          arrow(LucideIcons.chevronRight, canGoForward, onNext),
        ],
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ShortcutChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.accent : AppColors.surfaceVariant(isDark),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: AppText(
              label,
              fontSize: AppFontSizes.fz06,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textOnDarkButton : AppColors.textPrimary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}
