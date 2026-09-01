// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Enquêtes HCP';

  @override
  String get loginTitle => 'Connexion enquêteur';

  @override
  String get loginMatricule => 'Matricule';

  @override
  String get loginMatriculeRequired => 'Le matricule est obligatoire';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginPasswordRequired => 'Le mot de passe est obligatoire';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get loginInvalidCredentials => 'Matricule ou mot de passe incorrect.';

  @override
  String get loginNeedsInternetFirstTime =>
      'La première connexion nécessite Internet.';

  @override
  String get sessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get surveysTitle => 'Enquêtes';

  @override
  String get surveysEmpty => 'Aucune enquête disponible.';

  @override
  String get surveysNoneDownloaded => 'Aucune enquête téléchargée.';

  @override
  String get surveysOfflineBanner =>
      'Hors ligne — enquêtes téléchargées uniquement.';

  @override
  String get surveysServerUnreachable => 'Serveur injoignable';

  @override
  String surveyVersion(int version) {
    return 'Version $version';
  }

  @override
  String surveyVersionTapToOpen(int version) {
    return 'Version $version · Appuyez pour ouvrir';
  }

  @override
  String get surveyDownloaded => 'Téléchargée';

  @override
  String get surveyDownload => 'Télécharger';

  @override
  String surveyDownloadedToast(String title) {
    return '« $title » téléchargée';
  }

  @override
  String get surveyNotOnDevice =>
      'Cette enquête n\'est pas téléchargée sur cet appareil';

  @override
  String get responsesTitle => 'Réponses';

  @override
  String get responsesLoadFailed => 'Impossible de charger les réponses';

  @override
  String get responsesEmpty =>
      'Aucune réponse pour le moment.\nAppuyez sur « Nouvelle réponse » pour commencer.';

  @override
  String responseNumber(String id) {
    return 'Réponse n° $id';
  }

  @override
  String responseUpdatedAt(String date) {
    return 'Modifiée le $date';
  }

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyEmpty => 'Aucune réponse collectée.';

  @override
  String get historyLoadFailed => 'Impossible de charger l\'historique';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileNotSignedIn => 'Non connecté';

  @override
  String get profileMatricule => 'Matricule';

  @override
  String get profileRole => 'Rôle';

  @override
  String get profileRegion => 'Région';

  @override
  String get profilePhone => 'Téléphone';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get profileSignOut => 'Déconnexion';

  @override
  String get questionnaireNew => 'Nouvelle réponse';

  @override
  String get questionnaireEdit => 'Modifier la réponse';

  @override
  String get questionnaireLoadFailed => 'Impossible de charger l\'enquête';

  @override
  String get questionnaireSaveDraft => 'Enregistrer le brouillon';

  @override
  String get questionnaireDraftSaved => 'Brouillon enregistré';

  @override
  String get questionnaireFinalize => 'Valider et mettre en file d\'envoi';

  @override
  String get questionnaireFinalized =>
      'Réponse enregistrée et mise en file d\'envoi';

  @override
  String get questionnaireMakeCorrection => 'Corriger';

  @override
  String get questionnaireLockedBanner =>
      'Cette réponse a déjà été envoyée au serveur, elle est donc en lecture seule. Appuyez sur « Corriger » pour la modifier et la renvoyer.';

  @override
  String get questionnaireRequired => 'Cette question est obligatoire';

  @override
  String questionnaireMin(String min) {
    return 'Minimum : $min';
  }

  @override
  String questionnaireMax(String max) {
    return 'Maximum : $max';
  }

  @override
  String questionnaireUnsupportedType(String type) {
    return 'Type de question non pris en charge : $type';
  }

  @override
  String get questionnaireSelectDate => 'Choisir une date';

  @override
  String get helpTitle => 'Aide';

  @override
  String get helpExplainWithAi => 'Expliquer avec l\'IA (en ligne)';

  @override
  String get helpAiUnavailable =>
      'L\'explication par IA n\'est pas disponible pour le moment.';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncUpToDate => 'Tout est à jour';

  @override
  String syncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses envoyées',
      one: '1 réponse envoyée',
    );
    return '$_temp0';
  }

  @override
  String syncPartial(int synced, int failed) {
    return '$synced envoyée(s), $failed en échec';
  }

  @override
  String get statusDraft => 'Brouillon';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusSyncing => 'Envoi en cours';

  @override
  String get statusSynced => 'Envoyée';

  @override
  String get statusFailed => 'Échec';

  @override
  String get statusConflict => 'Conflit';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';
}
