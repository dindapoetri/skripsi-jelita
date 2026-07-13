import 'package:intl/intl.dart';

String capitalizeWords(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy • HH:mm').format(dateTime);
}
