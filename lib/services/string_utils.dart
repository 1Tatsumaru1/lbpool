import 'package:flutter/material.dart';

class StringUtils {

  static String htmlStripTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static void snackMessenger(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3),)
    );
  }

  static int parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return (value == 1) ? true : false;
    if (value is String) return (value == 'true') ? true : false;
    return false;
  }

  static String? formatDate(dynamic value) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    DateTime? d = (value is String) ? DateTime.tryParse(value) : value;
    if (d == null) return null;
    return '${d.day} ${months[d.month - 1]} ${d.year} @ ${d.hour < 10 ? "0${d.hour}" : d.hour}:${d.minute < 10 ? "0${d.minute}" : d.minute}';
  }

  static String? formatDateJMAHM(dynamic value) {
    DateTime? d = (value is String) ? DateTime.tryParse(value) : value;
    if (d == null) return null;
    return '${d.day < 10 ? "0${d.day}" : d.day }/${d.month < 10 ? "0${d.month}" : d.month}/${d.year} ${d.hour < 10 ? "0${d.hour}" : d.hour}:${d.minute < 10 ? "0${d.minute}" : d.minute}';
  }

  /// Get formatted DateTime string YYYY-MM-DDTHH:MM:SSZ
  static String formatIso(DateTime dateTime) {
    String formattedDate = "${dateTime.year.toString()}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    String formattedTime = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00Z";
    return "${formattedDate}T$formattedTime";
  }
}