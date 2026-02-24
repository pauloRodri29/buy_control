import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Classe utilitária para manipulação e formatação de datas
class DataTimeCustomFormatter {
  static List<String> months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static List<String> monthsAbbreviated = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  /// Formata um TimeOfDay no padrão "hh:mm"
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  /// Formata um TimeOfDay no padrão "hh:mm:ss"
  static String formatTimeWithSeconds(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00"; // Sem segundos reais
  }

  // Formata a data no padrão personalizado "dia, Mês, ano" (ex: 16, Julho, 2025)
  static String formatDateCustom(
    DateTime date, {
    bool abbreviated = false,
    bool withTime = false,
  }) {
    // Lista de nomes dos meses em português

    if (abbreviated) {
      if (withTime) {
        return '${date.day}, ${monthsAbbreviated[date.month - 1]}, ${date.year}, ${toHHMM(formatTimeHHMMSS(date))}';
      }
      return '${date.day}, ${monthsAbbreviated[date.month - 1]}, ${date.year}';
    } else {
      // Retorna a data formatada como "dia, Mês, ano"
      if (withTime) {
        return '${date.day}, ${months[date.month - 1]}, ${date.year}, ${toHHMM(formatTimeHHMMSS(date))}';
      } else {
        return '${date.day}, ${months[date.month - 1]}, ${date.year}';
      }
    }
  }

  // Formata a data no padrão "dd/MM/yyyy" (ex: 16/07/2025)
  static String formatDateDDMMYYYY(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Formata a data no padrão "yyyy-MM-dd" (ex: 2025-07-16)
  static String formatDateYYYYMMDD(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Formata a hora no padrão "HH:mm:ss" (ex: 16:00:00)
  static String formatTimeHHMMSS(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }

  // Formata a hora no padrão "HH:mm:ss" (ex: 16:00)
  static String toHHMM(String time) {
    return time.substring(0, 5);
  }

  // Formata a data e hora no padrão "dd/MM/yyyy HH:mm" (ex: 16/07/2025 17:28)
  static String formatDateTimeDDMMYYYYHHMM(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Formata a data no padrão "dd MMM yyyy" (ex: 16 Jul 2025)
  static String formatDateShortMonth(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Formata a data e hora no padrão "dd MMMM yyyy, HH:mm" (ex: 16 July 2025, 17:28)
  static String formatDateFullMonthWithTime(DateTime date) {
    return DateFormat('dd MMMM yyyy, HH:mm').format(date);
  }

  // Formata a data no padrão "EEE, dd MMM" (ex: Wed, 16 Jul)
  static String formatDateEdMMM(dynamic date) {
    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      throw ArgumentError(
        'O parâmetro deve ser uma String ISO 8601 ou DateTime',
      );
    }
    return DateFormat('EEE, dd MMM').format(dateTime);
  }

  // Permite escolher o formato via parâmetro, com 'custom' como padrão
  static String getFormattedCurrentDate({String format = 'custom'}) {
    final DateTime now = DateTime.now();
    switch (format) {
      case 'custom':
        return formatDateCustom(now); // Ex: 16, Julho, 2025
      case 'ddMMyyyy':
        return formatDateDDMMYYYY(now); // Ex: 16/07/2025
      case 'yyyyMMdd':
        return formatDateYYYYMMDD(now); // Ex: 2025-07-16
      case 'ddMMyyyyHHmm':
        return formatDateTimeDDMMYYYYHHMM(now); // Ex: 16/07/2025 17:28
      case 'shortMonth':
        return formatDateShortMonth(now); // Ex: 16 Jul 2025
      case 'fullMonthWithTime':
        return formatDateFullMonthWithTime(now); // Ex: 16 July 2025, 17:28
      default:
        return formatDateCustom(now); // Padrão: 16, Julho, 2025
    }
  }
}
