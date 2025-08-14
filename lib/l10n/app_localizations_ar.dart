// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get incomeVsExpense => 'الدخل مقابل المصروفات';

  @override
  String get comparePeriod => 'قارن الفترة';

  @override
  String get hideComparison => 'إخفاء المقارنة';

  @override
  String get changePeriodAggregation => 'تغيير تجميع الفترات';

  @override
  String get security => 'الأمان';

  @override
  String get appLock => 'قفل التطبيق';

  @override
  String get appLockSubtitle => 'طلب المصادقة عند التشغيل/الاستئناف';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get disabledInDemoMode => 'معطل في وضع التجربة';

  @override
  String get featureComingSoon => 'الميزة قادمة قريباً';

  @override
  String get expense => 'مصروف';

  @override
  String get income => 'دخل';

  @override
  String get description => 'الوصف';

  @override
  String get amount => 'المبلغ';

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get frequency => 'التكرار';

  @override
  String get selectTime => 'اختر الوقت';

  @override
  String get dayOfWeek => 'اليوم من الأسبوع';

  @override
  String get addRecurringRule => 'إضافة قاعدة متكررة';

  @override
  String get editRecurringRule => 'تعديل قاعدة متكررة';

  @override
  String get anErrorOccurred => 'حدث خطأ ما.';

  @override
  String get spendingByCategory => 'الإنفاق حسب الفئة';

  @override
  String get showPieChart => 'إظهار مخطط دائري';

  @override
  String get showBarChart => 'إظهار مخطط شريطي';

  @override
  String get budgetPerformance => 'أداء الميزانية';

  @override
  String get compareToPreviousPeriod => 'قارن بالفترة السابقة';

  @override
  String get noBudgetsFoundForPeriod => 'لا توجد ميزانيات لهذه الفترة.';

  @override
  String get spendingOverTime => 'الإنفاق مع مرور الوقت';

  @override
  String get changeGranularity => 'تغيير الدقة';

  @override
  String get reportDataNotLoadedYet => 'لم يتم تحميل بيانات التقرير بعد.';

  @override
  String get dayOfMonth => 'يوم من الشهر';

  @override
  String get ends => 'ينتهي';

  @override
  String get selectEndDate => 'اختر تاريخ الانتهاء';

  @override
  String get numberOfOccurrences => 'عدد التكرارات';

  @override
  String get save => 'حفظ';

  @override
  String get contributionDate => 'تاريخ المساهمة';

  @override
  String get accounts => 'الحسابات';

  @override
  String get noAccountsYet => 'لا توجد حسابات بعد!';

  @override
  String get addAccountEmptyDescription =>
      'اضغط على زر \"+\" أدناه لإضافة أول حساب بنكي أو محفظة نقدية أو أصول أخرى.';

  @override
  String get addFirstAccount => 'أضف الحساب الأول';

  @override
  String get confirmDeletion => 'تأكيد الحذف';

  @override
  String deleteAccountConfirmation(Object accountName) {
    return 'هل أنت متأكد أنك تريد حذف الحساب \"$accountName\"؟\\n\\nقد يفشل هذا الإجراء إذا كانت هناك معاملات مرتبطة بهذا الحساب.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get errorLoadingAccounts => 'حدث خطأ أثناء تحميل الحسابات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get addAccount => 'إضافة حساب';
}
