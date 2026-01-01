// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'ניהול מספרה';

  @override
  String get employeesTitle => 'עובדים';

  @override
  String get noEmployeesYet => 'אין עובדים עדיין.';

  @override
  String get addEmployeeTitle => 'הוסף עובד';

  @override
  String get employeeStatusTitle => 'סטטוס עובד';

  @override
  String get edit => 'עריכה';

  @override
  String get delete => 'מחיקה';

  @override
  String get save => 'שמירה';

  @override
  String get cancel => 'ביטול';

  @override
  String get create => 'צור';

  @override
  String get clear => 'נקה';

  @override
  String get followDevice => 'לפי המכשיר';

  @override
  String get english => 'אנגלית';

  @override
  String get hebrew => 'עברית';

  @override
  String get deleteEmployeesTitle => 'מחיקת עובדים';

  @override
  String deleteEmployeesConfirm(int count) {
    return 'למחוק $count עובד(ים) שנבחרו?';
  }

  @override
  String get editEmployeeTitle => 'עריכת עובד';

  @override
  String get firstNameLabel => 'שם פרטי';

  @override
  String get lastNameLabel => 'שם משפחה';

  @override
  String get idNumberLabel => 'מספר מזהה';

  @override
  String get phoneLabel => 'טלפון';

  @override
  String get statusLabel => 'סטטוס';

  @override
  String get activeSessionLabel => 'סשן פעיל';

  @override
  String get startedAtLabel => 'התחיל ב';

  @override
  String get idNumberDigitsOnlyLabel => 'מספר מזהה (ספרות בלבד)';

  @override
  String get phoneDigitsOnlyLabel => 'טלפון (ספרות בלבד)';

  @override
  String get idCannotBeChanged => 'לא ניתן לשינוי';

  @override
  String get noneValue => '(אין)';

  @override
  String get notAvailableValue => '(לא זמין)';

  @override
  String get noNameValue => '(ללא שם)';

  @override
  String get noIdValue => '(אין מזהה)';

  @override
  String get noPhoneValue => '(אין טלפון)';

  @override
  String inviteCodeText(String code) {
    return 'קוד הזמנה: $code';
  }

  @override
  String get inviteCodeHelp => 'תן את הקוד לעובד.';

  @override
  String get employeeNotFound => 'העובד לא נמצא.';

  @override
  String get errorFirstLastRequired => 'חובה להזין שם פרטי ושם משפחה.';

  @override
  String get errorIdRequired => 'חובה להזין מספר מזהה.';

  @override
  String get errorIdDigitsOnly => 'מספר מזהה חייב להכיל ספרות בלבד.';

  @override
  String get errorPhoneRequired => 'חובה להזין טלפון.';

  @override
  String get errorPhoneDigitsOnly => 'טלפון חייב להכיל ספרות בלבד.';

  @override
  String get errorInviteCodeFailed => 'יצירת קוד ההזמנה נכשלה. נסה שוב.';

  @override
  String errorWithMessage(String message) {
    return 'שגיאה: $message';
  }

  @override
  String get statusIdle => 'פנוי';

  @override
  String get statusWorking => 'בעבודה';

  @override
  String get statusOffline => 'לא מחובר';

  @override
  String get statusUnknown => 'לא ידוע';

  @override
  String get employeeAppTitle => 'Meamore עובד';

  @override
  String get employeeSetupTitle => 'הגדרת עובד';

  @override
  String get employeeIdLabel => 'מזהה עובד';

  @override
  String get employeeIdDigitsOnlyLabel => 'מזהה עובד (ספרות בלבד)';

  @override
  String get employeeIdHelp => 'הזן את מזהה העובד כדי להמשיך.';

  @override
  String get continueAction => 'המשך';

  @override
  String get logoutAction => 'התנתק';

  @override
  String get changeEmployeeAction => 'החלף עובד';

  @override
  String get errorEmployeeIdRequired => 'חובה להזין מזהה עובד.';

  @override
  String get errorEmployeeIdDigitsOnly => 'מזהה עובד חייב להכיל ספרות בלבד.';

  @override
  String get errorEmployeeNotFound => 'העובד לא נמצא. בדוק את המזהה ונסה שוב.';

  @override
  String get errorEmployeeLoadFailed => 'טעינת פרטי העובד נכשלה. נסה שוב.';

  @override
  String get treatmentTitle => 'טיפול';

  @override
  String get treatmentNewTitle => 'טיפול חדש';

  @override
  String get treatmentTypeLabel => 'סוג טיפול';

  @override
  String get dogNameLabel => 'שם הכלב';

  @override
  String get dogBreedLabel => 'גזע';

  @override
  String get dogOwnerNameLabel => 'שם הבעלים';

  @override
  String get coatConditionLabel => 'מצב הפרווה';

  @override
  String get coatConditionHelp => '1 = גרוע מאוד, 5 = מושלם';

  @override
  String get startTreatmentAction => 'התחל טיפול';

  @override
  String get finishTreatmentAction => 'סיים טיפול';

  @override
  String get treatmentInProgress => 'טיפול מתבצע';

  @override
  String get treatmentSaved => 'הטיפול נשמר.';

  @override
  String get errorTreatmentTypeRequired => 'חובה להזין סוג טיפול.';

  @override
  String get errorDogNameRequired => 'חובה להזין שם כלב.';

  @override
  String get errorDogBreedRequired => 'חובה להזין גזע.';

  @override
  String get errorOwnerNameRequired => 'חובה להזין שם בעלים.';

  @override
  String get errorCoatConditionRequired => 'חובה לבחור מצב פרווה.';

  @override
  String get errorCoatConditionRange => 'מצב הפרווה חייב להיות בין 1 ל-5.';

  @override
  String get errorStartTreatmentFailed => 'התחלת הטיפול נכשלה. נסה שוב.';

  @override
  String get errorFinishTreatmentFailed => 'סיום הטיפול נכשל. נסה שוב.';

  @override
  String get statusBusy => 'עסוק';

  @override
  String startedAtValue(String time) {
    return 'התחיל: $time';
  }

  @override
  String endedAtValue(String time) {
    return 'הסתיים: $time';
  }

  @override
  String get reportsTitle => 'דוחות';

  @override
  String get reportPeriodLabel => 'תקופה';

  @override
  String get reportDateLabel => 'תאריך';

  @override
  String get reportRangeLabel => 'טווח';

  @override
  String get reportAllEmployeesOption => 'כל העובדים';

  @override
  String get reportGenerateAction => 'הצג דוח';

  @override
  String get reportGenerateExcelAction => 'ייצוא לאקסל';

  @override
  String get reportNoTreatmentsInRange => 'אין טיפולים בטווח שנבחר.';

  @override
  String get reportSaved => 'הדוח נשמר.';

  @override
  String get reportPeriodDaily => 'יומי';

  @override
  String get reportPeriodWeekly => 'שבועי';

  @override
  String get reportPeriodMonthly => 'חודשי';

  @override
  String get reportPeriodQuarterly => 'רבעוני';

  @override
  String get treatedTodayTitle => 'הסתיימו היום';

  @override
  String get doneByMeTitle => 'בוצע על ידי';

  @override
  String get noBusyTreatments => 'אין טיפולים פעילים';

  @override
  String get treatmentTimeColumn => 'זמן טיפול';

  @override
  String get noTreatedToday => 'אין טיפולים שהסתיימו היום';

  @override
  String get noDoneByMeToday => 'אין טיפולים שבוצעו על ידי היום';

  @override
  String get queueTitle => 'תור';

  @override
  String get noCustomersInQueue => 'אין לקוחות בתור.';
}
