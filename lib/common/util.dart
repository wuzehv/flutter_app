import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';

String getRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random.secure();
  return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
}

String trimEndingChars(String s, String chars) {
  final escaped = RegExp.escape(chars);
  return s.replaceAll(RegExp('[$escaped]+\$'), '');
}

int compareVersions(String v1, String v2) {
  v1 = v1.startsWith('v') ? v1.substring(1) : v1;
  v2 = v2.startsWith('v') ? v2.substring(1) : v2;

  List<String> parts1 = v1.split('.');
  List<String> parts2 = v2.split('.');

  int maxLength = [parts1.length, parts2.length].reduce((a, b) => a > b ? a : b);

  for (int i = 0; i < maxLength; i++) {
    int num1 = i < parts1.length ? int.tryParse(parts1[i]) ?? 0 : 0;
    int num2 = i < parts2.length ? int.tryParse(parts2[i]) ?? 0 : 0;

    if (num1 > num2) return 1;
    if (num1 < num2) return -1;
  }

  return 0;
}

String snakeToCamel(String input) {
  return input.replaceAllMapped(RegExp(r'[_-]([a-z])'), (match) => match.group(1)!.toUpperCase());
}

void showError(String txt) {
  showToast(txt, backgroundColor: Colors.red, position: ToastPosition.bottom);
}

void showSucc(String txt) {
  showToast(txt, backgroundColor: Colors.green, position: ToastPosition.bottom);
}

void showInfo(String txt) {
  showToast(txt, backgroundColor: Colors.orangeAccent, position: ToastPosition.bottom);
}

String removeFirstSegment(String path) {
  if (path.contains('/')) {
    return path.substring(path.indexOf('/') + 1);
  }

  return path;
}

String formatChatTime(String timeStr) {
  DateTime time = DateTime.parse(timeStr);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final aDate = DateTime(time.year, time.month, time.day);

  final difference = today.difference(aDate).inDays;

  time = time.add(Duration(hours: 8));
  if (difference == 0) {
    return "今天 ${DateFormat.Hm().format(time)}";
  } else if (difference == 1) {
    return "昨天 ${DateFormat.Hm().format(time)}";
  } else {
    return DateFormat("yyyy-MM-dd HH:mm").format(time);
  }
}
