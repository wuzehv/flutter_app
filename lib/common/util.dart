import 'dart:math';

import 'package:flutter/material.dart';
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

void showError(String txt) {
  showToast(txt, backgroundColor: Colors.red, position: ToastPosition.bottom);
}

void showSucc(String txt) {
  showToast(txt, backgroundColor: Colors.green, position: ToastPosition.bottom);
}
