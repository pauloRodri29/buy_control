import 'package:intl/intl.dart';

class DateTimeFormatter {
  static String ddMMyyyy(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  static String ddMMyyyyHHmm(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date);

  static String ddMMMyyyy(DateTime date) => DateFormat('dd MMM yyyy', 'pt_BR').format(date);

  /// Retorna "hoje", "ontem", "há N dias" para datas recentes, ou dd/MM/yyyy.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'hoje';
    if (diff == 1) return 'ontem';
    if (diff > 1 && diff < 7) return 'há $diff dias';
    return ddMMyyyy(date);
  }
}
