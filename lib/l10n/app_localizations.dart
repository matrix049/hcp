import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Enquêtes HCP'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion enquêteur'**
  String get loginTitle;

  /// No description provided for @loginMatricule.
  ///
  /// In fr, this message translates to:
  /// **'Matricule'**
  String get loginMatricule;

  /// No description provided for @loginMatriculeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le matricule est obligatoire'**
  String get loginMatriculeRequired;

  /// No description provided for @loginPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPassword;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est obligatoire'**
  String get loginPasswordRequired;

  /// No description provided for @loginSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginSubmit;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Matricule ou mot de passe incorrect.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginNeedsInternetFirstTime.
  ///
  /// In fr, this message translates to:
  /// **'La première connexion nécessite Internet.'**
  String get loginNeedsInternetFirstTime;

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Veuillez vous reconnecter.'**
  String get sessionExpired;

  /// No description provided for @surveysTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enquêtes'**
  String get surveysTitle;

  /// No description provided for @surveysEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune enquête disponible.'**
  String get surveysEmpty;

  /// No description provided for @surveysNoneDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'Aucune enquête téléchargée.'**
  String get surveysNoneDownloaded;

  /// No description provided for @surveysOfflineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne — enquêtes téléchargées uniquement.'**
  String get surveysOfflineBanner;

  /// No description provided for @surveysServerUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable'**
  String get surveysServerUnreachable;

  /// No description provided for @surveyVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String surveyVersion(int version);

  /// No description provided for @surveyVersionTapToOpen.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} · Appuyez pour ouvrir'**
  String surveyVersionTapToOpen(int version);

  /// No description provided for @surveyDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargée'**
  String get surveyDownloaded;

  /// No description provided for @surveyDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get surveyDownload;

  /// No description provided for @surveyDownloadedToast.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » téléchargée'**
  String surveyDownloadedToast(String title);

  /// No description provided for @surveyNotOnDevice.
  ///
  /// In fr, this message translates to:
  /// **'Cette enquête n\'est pas téléchargée sur cet appareil'**
  String get surveyNotOnDevice;

  /// No description provided for @responsesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réponses'**
  String get responsesTitle;

  /// No description provided for @responsesLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les réponses'**
  String get responsesLoadFailed;

  /// No description provided for @responsesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réponse pour le moment.\nAppuyez sur « Nouvelle réponse » pour commencer.'**
  String get responsesEmpty;

  /// No description provided for @responseNumber.
  ///
  /// In fr, this message translates to:
  /// **'Réponse n° {id}'**
  String responseNumber(String id);

  /// No description provided for @responseUpdatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Modifiée le {date}'**
  String responseUpdatedAt(String date);

  /// No description provided for @historyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réponse collectée.'**
  String get historyEmpty;

  /// No description provided for @historyLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'historique'**
  String get historyLoadFailed;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileNotSignedIn.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get profileNotSignedIn;

  /// No description provided for @profileMatricule.
  ///
  /// In fr, this message translates to:
  /// **'Matricule'**
  String get profileMatricule;

  /// No description provided for @profileRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get profileRole;

  /// No description provided for @profileRegion.
  ///
  /// In fr, this message translates to:
  /// **'Région'**
  String get profileRegion;

  /// No description provided for @profilePhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get profilePhone;

  /// No description provided for @profileLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profileLanguage;

  /// No description provided for @profileSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get profileSignOut;

  /// No description provided for @questionnaireNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réponse'**
  String get questionnaireNew;

  /// No description provided for @questionnaireEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la réponse'**
  String get questionnaireEdit;

  /// No description provided for @questionnaireLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'enquête'**
  String get questionnaireLoadFailed;

  /// No description provided for @questionnaireSaveDraft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le brouillon'**
  String get questionnaireSaveDraft;

  /// No description provided for @questionnaireDraftSaved.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon enregistré'**
  String get questionnaireDraftSaved;

  /// No description provided for @questionnaireFinalize.
  ///
  /// In fr, this message translates to:
  /// **'Valider et mettre en file d\'envoi'**
  String get questionnaireFinalize;

  /// No description provided for @questionnaireFinalized.
  ///
  /// In fr, this message translates to:
  /// **'Réponse enregistrée et mise en file d\'envoi'**
  String get questionnaireFinalized;

  /// No description provided for @questionnaireMakeCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get questionnaireMakeCorrection;

  /// No description provided for @questionnaireLockedBanner.
  ///
  /// In fr, this message translates to:
  /// **'Cette réponse a déjà été envoyée au serveur, elle est donc en lecture seule. Appuyez sur « Corriger » pour la modifier et la renvoyer.'**
  String get questionnaireLockedBanner;

  /// No description provided for @questionnaireRequired.
  ///
  /// In fr, this message translates to:
  /// **'Cette question est obligatoire'**
  String get questionnaireRequired;

  /// No description provided for @questionnaireMin.
  ///
  /// In fr, this message translates to:
  /// **'Minimum : {min}'**
  String questionnaireMin(String min);

  /// No description provided for @questionnaireMax.
  ///
  /// In fr, this message translates to:
  /// **'Maximum : {max}'**
  String questionnaireMax(String max);

  /// No description provided for @questionnaireUnsupportedType.
  ///
  /// In fr, this message translates to:
  /// **'Type de question non pris en charge : {type}'**
  String questionnaireUnsupportedType(String type);

  /// No description provided for @questionnaireSelectDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get questionnaireSelectDate;

  /// No description provided for @helpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get helpTitle;

  /// No description provided for @helpExplainWithAi.
  ///
  /// In fr, this message translates to:
  /// **'Expliquer avec l\'IA (en ligne)'**
  String get helpExplainWithAi;

  /// No description provided for @helpAiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'explication par IA n\'est pas disponible pour le moment.'**
  String get helpAiUnavailable;

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get syncNow;

  /// No description provided for @syncUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'Tout est à jour'**
  String get syncUpToDate;

  /// No description provided for @syncDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 réponse envoyée} other{{count} réponses envoyées}}'**
  String syncDone(int count);

  /// No description provided for @syncPartial.
  ///
  /// In fr, this message translates to:
  /// **'{synced} envoyée(s), {failed} en échec'**
  String syncPartial(int synced, int failed);

  /// No description provided for @statusDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get statusDraft;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusPending;

  /// No description provided for @statusSyncing.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours'**
  String get statusSyncing;

  /// No description provided for @statusSynced.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée'**
  String get statusSynced;

  /// No description provided for @statusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get statusFailed;

  /// No description provided for @statusConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit'**
  String get statusConflict;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
