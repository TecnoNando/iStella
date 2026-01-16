import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  /// Hash a password using SHA-256
  /// En producción, considera usar bcrypt o argon2 para mayor seguridad
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify if a password matches the hash
  static bool verifyPassword(String password, String hashedPassword) {
    final hashedInput = hashPassword(password);
    return hashedInput == hashedPassword;
  }
}
