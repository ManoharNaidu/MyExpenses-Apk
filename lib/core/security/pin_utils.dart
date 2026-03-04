import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashPin(String pin) {
  final normalized = pin.trim();
  return sha256.convert(utf8.encode(normalized)).toString();
}
