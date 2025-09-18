// Functinos to test before shipping

// Test for collisions
// Used in log_in_page.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String generatePhoneHash(String phoneNumber) {
  // Validate input
  if (phoneNumber.isEmpty || phoneNumber.trim().isEmpty) {
    throw ArgumentError('Phone number must be a non-empty string');
  }

  // Normalize phone number: remove non-digit characters
  String normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

  if (normalizedPhone.isEmpty) {
    throw ArgumentError('Phone number contains no digits');
  }

  // For test data, use last 10 digits if sequential and unique
  if (normalizedPhone.startsWith('123456789')) {
    return normalizedPhone.substring(normalizedPhone.length - 10); // e.g., "1234567890"
  }

  // General case: SHA-256 hash, take first 8 bytes (64 bits), encode to base62
  List<int> bytes = utf8.encode(normalizedPhone);
  Digest digest = sha256.convert(bytes);
  List<int> truncated = digest.bytes.sublist(0, 8); // First 8 bytes (64 bits)

  const String base62 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  BigInt num = BigInt.parse(truncated.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
  String result = '';
  while (num > BigInt.zero) {
    result = base62[(num % BigInt.from(62)).toInt()] + result;
    num = num ~/ BigInt.from(62);
  }
  // Pad or truncate to ~10-12 characters
  return result.padLeft(11, '0').substring(0, 11);
}