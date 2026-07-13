import 'package:flutter_test/flutter_test.dart';
import 'package:hcp_survey_app/core/utils/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('same password + salt yields the same hash', () {
      const salt = 'fixed-salt';
      expect(
        PasswordHasher.hash('Secret123', salt),
        PasswordHasher.hash('Secret123', salt),
      );
    });

    test('verify succeeds for the correct password', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash('Secret123', salt);
      expect(PasswordHasher.verify('Secret123', salt, hash), isTrue);
    });

    test('verify fails for a wrong password', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash('Secret123', salt);
      expect(PasswordHasher.verify('WrongPass', salt, hash), isFalse);
    });

    test('different salts produce different hashes for the same password', () {
      final h1 = PasswordHasher.hash('Secret123', PasswordHasher.generateSalt());
      final h2 = PasswordHasher.hash('Secret123', PasswordHasher.generateSalt());
      expect(h1, isNot(h2));
    });

    test('generateSalt returns unique values', () {
      final salts = List.generate(50, (_) => PasswordHasher.generateSalt());
      expect(salts.toSet().length, salts.length);
    });
  });
}
