import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/providers/auth_state.dart';
import 'features/surveys/presentation/pages/surveys_page.dart';

/// Root widget. Watches the selected language so the whole app (including text
/// direction — RTL for Arabic) follows it.
class HcpSurveyApp extends ConsumerWidget {
  const HcpSurveyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeControllerProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      locale: language.locale,
      supportedLocales: const [Locale('fr'), Locale('ar')],
      // These delegates make Directionality follow the locale — Arabic = RTL.
      localizationsDelegates: const [
        // Generated from lib/l10n/*.arb — this is what makes the app's own
        // chrome follow the selected language, not just the survey content.
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// Chooses the screen based on auth state. This is our lightweight alternative
/// to a full router while there is only login + a placeholder home. `go_router`
/// will replace this once there are multiple guarded routes.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    return switch (state) {
      AuthChecking() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthAuthenticated() => const SurveysPage(),
      AuthAuthenticating() || AuthUnauthenticated() => const LoginPage(),
    };
  }
}
