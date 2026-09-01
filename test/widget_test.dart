import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hcp_survey_app/app.dart';
import 'package:hcp_survey_app/core/di/providers.dart';
import 'package:hcp_survey_app/core/storage/secure_storage_service.dart';
import 'package:hcp_survey_app/features/auth/presentation/pages/login_page.dart';

/// In-memory secure storage so widget tests don't hit the real plugin
/// (which has no implementation in the Flutter test VM).
class _InMemorySecureStorage extends SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> saveAccessToken(String token) async => _data['at'] = token;
  @override
  Future<String?> readAccessToken() async => _data['at'];
  @override
  Future<void> saveRefreshToken(String token) async => _data['rt'] = token;
  @override
  Future<String?> readRefreshToken() async => _data['rt'];
  @override
  Future<void> clear() async => _data.clear();
}

void main() {
  testWidgets('App boots to the login page when no session is cached',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(_InMemorySecureStorage()),
        ],
        child: const HcpSurveyApp(),
      ),
    );

    // Let the async session-restore settle (no cached agent).
    await tester.pump();
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
