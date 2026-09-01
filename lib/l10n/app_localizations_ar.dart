// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'استمارات المندوبية السامية للتخطيط';

  @override
  String get loginTitle => 'دخول الباحث';

  @override
  String get loginMatricule => 'رقم التأجير';

  @override
  String get loginMatriculeRequired => 'رقم التأجير إلزامي';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginPasswordRequired => 'كلمة المرور إلزامية';

  @override
  String get loginSubmit => 'تسجيل الدخول';

  @override
  String get loginInvalidCredentials => 'رقم التأجير أو كلمة المرور غير صحيحة.';

  @override
  String get loginNeedsInternetFirstTime =>
      'يتطلب الدخول لأول مرة اتصالاً بالإنترنت.';

  @override
  String get sessionExpired =>
      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول من جديد.';

  @override
  String get surveysTitle => 'الأبحاث';

  @override
  String get surveysEmpty => 'لا يوجد أي بحث متاح.';

  @override
  String get surveysNoneDownloaded => 'لم يتم تحميل أي بحث.';

  @override
  String get surveysOfflineBanner => 'غير متصل — تظهر الأبحاث المحمّلة فقط.';

  @override
  String get surveysServerUnreachable => 'تعذّر الوصول إلى الخادم';

  @override
  String surveyVersion(int version) {
    return 'النسخة $version';
  }

  @override
  String surveyVersionTapToOpen(int version) {
    return 'النسخة $version · اضغط للفتح';
  }

  @override
  String get surveyDownloaded => 'محمّل';

  @override
  String get surveyDownload => 'تحميل';

  @override
  String surveyDownloadedToast(String title) {
    return 'تم تحميل «$title»';
  }

  @override
  String get surveyNotOnDevice => 'هذا البحث غير محمّل على هذا الجهاز';

  @override
  String get responsesTitle => 'الأجوبة';

  @override
  String get responsesLoadFailed => 'تعذّر تحميل الأجوبة';

  @override
  String get responsesEmpty =>
      'لا توجد أجوبة بعد.\nاضغط على «جواب جديد» للبدء.';

  @override
  String responseNumber(String id) {
    return 'الجواب رقم $id';
  }

  @override
  String responseUpdatedAt(String date) {
    return 'عُدّل في $date';
  }

  @override
  String get historyTitle => 'السجل';

  @override
  String get historyEmpty => 'لم يتم جمع أي جواب.';

  @override
  String get historyLoadFailed => 'تعذّر تحميل السجل';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileNotSignedIn => 'غير مسجّل الدخول';

  @override
  String get profileMatricule => 'رقم التأجير';

  @override
  String get profileRole => 'الصفة';

  @override
  String get profileRegion => 'الجهة';

  @override
  String get profilePhone => 'الهاتف';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileSignOut => 'تسجيل الخروج';

  @override
  String get questionnaireNew => 'جواب جديد';

  @override
  String get questionnaireEdit => 'تعديل الجواب';

  @override
  String get questionnaireLoadFailed => 'تعذّر تحميل البحث';

  @override
  String get questionnaireSaveDraft => 'حفظ كمسودة';

  @override
  String get questionnaireDraftSaved => 'تم حفظ المسودة';

  @override
  String get questionnaireFinalize => 'تأكيد وإضافة إلى قائمة الإرسال';

  @override
  String get questionnaireFinalized =>
      'تم حفظ الجواب وإضافته إلى قائمة الإرسال';

  @override
  String get questionnaireMakeCorrection => 'تصحيح';

  @override
  String get questionnaireLockedBanner =>
      'تم إرسال هذا الجواب إلى الخادم، لذا فهو للقراءة فقط. اضغط على «تصحيح» لتعديله وإعادة إرساله.';

  @override
  String get questionnaireRequired => 'هذا السؤال إلزامي';

  @override
  String questionnaireMin(String min) {
    return 'الحد الأدنى: $min';
  }

  @override
  String questionnaireMax(String max) {
    return 'الحد الأقصى: $max';
  }

  @override
  String questionnaireUnsupportedType(String type) {
    return 'نوع سؤال غير مدعوم: $type';
  }

  @override
  String get questionnaireSelectDate => 'اختر تاريخاً';

  @override
  String get helpTitle => 'مساعدة';

  @override
  String get helpExplainWithAi => 'شرح بالذكاء الاصطناعي (يتطلب اتصالاً)';

  @override
  String get helpAiUnavailable => 'الشرح بالذكاء الاصطناعي غير متاح حالياً.';

  @override
  String get syncNow => 'المزامنة الآن';

  @override
  String get syncUpToDate => 'كل شيء محدّث';

  @override
  String syncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إرسال $count جواباً',
      few: 'تم إرسال $count أجوبة',
      two: 'تم إرسال جوابين',
      one: 'تم إرسال جواب واحد',
    );
    return '$_temp0';
  }

  @override
  String syncPartial(int synced, int failed) {
    return '$synced مُرسَل، $failed فشل';
  }

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusPending => 'في الانتظار';

  @override
  String get statusSyncing => 'جارٍ الإرسال';

  @override
  String get statusSynced => 'مُرسَل';

  @override
  String get statusFailed => 'فشل';

  @override
  String get statusConflict => 'تعارض';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';
}
