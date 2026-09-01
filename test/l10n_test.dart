import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcp_survey_app/l10n/app_localizations.dart';

/// The agent app's own chrome has to follow the selected language, not just the
/// survey content. Switching to Arabic used to translate the questions while
/// leaving every button, tab and label in French, because those strings were
/// hardcoded. These tests pin the two properties that regression depended on:
/// both locales resolve, and neither falls back to the other's text.
void main() {
  late AppLocalizations fr;
  late AppLocalizations ar;

  setUpAll(() async {
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  test('both locales are supported', () {
    expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('ar')), isTrue);
    expect(AppLocalizations.supportedLocales.length, 2);
  });

  test('French strings are French', () {
    expect(fr.surveysTitle, 'Enquêtes');
    expect(fr.profileTitle, 'Profil');
    expect(fr.questionnaireNew, 'Nouvelle réponse');
    expect(fr.statusPending, 'En attente');
  });

  test('Arabic strings are Arabic, not a French fallback', () {
    expect(ar.surveysTitle, 'الأبحاث');
    expect(ar.profileTitle, 'الملف الشخصي');
    expect(ar.questionnaireNew, 'جواب جديد');
    expect(ar.statusPending, 'في الانتظار');
  });

  test('every key differs between the two locales', () {
    // A key left untranslated silently falls back to the template locale, which
    // is exactly the bug this suite exists to catch. Language names and pure
    // punctuation are legitimately identical, so nothing here should be.
    final pairs = <String, List<String>>{
      'surveysTitle': [fr.surveysTitle, ar.surveysTitle],
      'surveysEmpty': [fr.surveysEmpty, ar.surveysEmpty],
      'surveyDownload': [fr.surveyDownload, ar.surveyDownload],
      'surveyDownloaded': [fr.surveyDownloaded, ar.surveyDownloaded],
      'historyTitle': [fr.historyTitle, ar.historyTitle],
      'historyEmpty': [fr.historyEmpty, ar.historyEmpty],
      'profileTitle': [fr.profileTitle, ar.profileTitle],
      'profileSignOut': [fr.profileSignOut, ar.profileSignOut],
      'profileRegion': [fr.profileRegion, ar.profileRegion],
      'loginTitle': [fr.loginTitle, ar.loginTitle],
      'loginSubmit': [fr.loginSubmit, ar.loginSubmit],
      'loginMatricule': [fr.loginMatricule, ar.loginMatricule],
      'questionnaireNew': [fr.questionnaireNew, ar.questionnaireNew],
      'questionnaireFinalize': [fr.questionnaireFinalize, ar.questionnaireFinalize],
      'questionnaireSaveDraft': [fr.questionnaireSaveDraft, ar.questionnaireSaveDraft],
      'questionnaireRequired': [fr.questionnaireRequired, ar.questionnaireRequired],
      'questionnaireLockedBanner': [fr.questionnaireLockedBanner, ar.questionnaireLockedBanner],
      'helpExplainWithAi': [fr.helpExplainWithAi, ar.helpExplainWithAi],
      'syncNow': [fr.syncNow, ar.syncNow],
      'syncUpToDate': [fr.syncUpToDate, ar.syncUpToDate],
      'statusDraft': [fr.statusDraft, ar.statusDraft],
      'statusSynced': [fr.statusSynced, ar.statusSynced],
      'statusFailed': [fr.statusFailed, ar.statusFailed],
      'retry': [fr.retry, ar.retry],
      'appTitle': [fr.appTitle, ar.appTitle],
    };

    for (final entry in pairs.entries) {
      expect(
        entry.value[0] == entry.value[1],
        isFalse,
        reason: '${entry.key} est identique en fr et en ar — traduction manquante',
      );
      expect(entry.value[1].trim(), isNotEmpty, reason: '${entry.key} ar est vide');
    }
  });

  test('parameterised strings interpolate in both locales', () {
    expect(fr.surveyVersion(3), contains('3'));
    expect(ar.surveyVersion(3), contains('3'));
    expect(fr.surveyDownloadedToast('Ménages'), contains('Ménages'));
    expect(ar.surveyDownloadedToast('Ménages'), contains('Ménages'));
    expect(fr.syncDone(1), isNotEmpty);
    expect(ar.syncDone(1), isNotEmpty);
    expect(ar.syncDone(5), isNot(ar.syncDone(1)), reason: 'pluriel arabe');
  });
}
