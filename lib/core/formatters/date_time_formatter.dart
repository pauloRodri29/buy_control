import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Datas formatadas no idioma atual. Os nomes seguem o padrão brasileiro,
/// mas em inglês a ordem vira mês/dia (ex.: `ddMMyyyy` → "11/21/2026").
class DateTimeFormatter {
  static String ddMMyyyy(DateTime date) => DateFormat('format.date'.tr, AppLocale.intl).format(date);

  static String ddMMyyyyHHmm(DateTime date) => DateFormat('format.dateTime'.tr, AppLocale.intl).format(date);

  static String ddMMMyyyy(DateTime date) => DateFormat('format.dateShortMonth'.tr, AppLocale.intl).format(date);

  /// Retorna "hoje", "ontem", "há N dias" para datas recentes, ou dd/MM/yyyy.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'common.todayLower'.tr;
    if (diff == 1) return 'common.yesterdayLower'.tr;
    if (diff > 1 && diff < 7) return 'common.daysAgoDiff'.trParams({'diff': '$diff'});
    return ddMMyyyy(date);
  }
}
