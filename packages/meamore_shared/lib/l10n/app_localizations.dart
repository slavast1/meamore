import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Barbershop Admin'**
  String get appTitle;

  /// No description provided for @employeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeesTitle;

  /// No description provided for @noEmployeesYet.
  ///
  /// In en, this message translates to:
  /// **'No employees yet.'**
  String get noEmployeesYet;

  /// No description provided for @addEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get addEmployeeTitle;

  /// No description provided for @employeeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee status'**
  String get employeeStatusTitle;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @followDevice.
  ///
  /// In en, this message translates to:
  /// **'Follow device'**
  String get followDevice;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get hebrew;

  /// No description provided for @deleteEmployeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete employees'**
  String get deleteEmployeesTitle;

  /// No description provided for @deleteEmployeesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected employee(s)?'**
  String deleteEmployeesConfirm(int count);

  /// No description provided for @editEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit employee'**
  String get editEmployeeTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @idNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get idNumberLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @activeSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Active session'**
  String get activeSessionLabel;

  /// No description provided for @startedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Started at'**
  String get startedAtLabel;

  /// No description provided for @idNumberDigitsOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'ID number (digits only)'**
  String get idNumberDigitsOnlyLabel;

  /// No description provided for @phoneDigitsOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (digits only)'**
  String get phoneDigitsOnlyLabel;

  /// No description provided for @idCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Cannot be changed'**
  String get idCannotBeChanged;

  /// No description provided for @noneValue.
  ///
  /// In en, this message translates to:
  /// **'(none)'**
  String get noneValue;

  /// No description provided for @notAvailableValue.
  ///
  /// In en, this message translates to:
  /// **'(n/a)'**
  String get notAvailableValue;

  /// No description provided for @noNameValue.
  ///
  /// In en, this message translates to:
  /// **'(no name)'**
  String get noNameValue;

  /// No description provided for @noIdValue.
  ///
  /// In en, this message translates to:
  /// **'(no ID)'**
  String get noIdValue;

  /// No description provided for @noPhoneValue.
  ///
  /// In en, this message translates to:
  /// **'(no phone)'**
  String get noPhoneValue;

  /// No description provided for @inviteCodeText.
  ///
  /// In en, this message translates to:
  /// **'Invite code: {code}'**
  String inviteCodeText(String code);

  /// No description provided for @inviteCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Give this code to the employee.'**
  String get inviteCodeHelp;

  /// No description provided for @employeeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Employee not found.'**
  String get employeeNotFound;

  /// No description provided for @errorFirstLastRequired.
  ///
  /// In en, this message translates to:
  /// **'First and last name are required.'**
  String get errorFirstLastRequired;

  /// No description provided for @errorIdRequired.
  ///
  /// In en, this message translates to:
  /// **'ID number is required.'**
  String get errorIdRequired;

  /// No description provided for @errorIdDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'ID number must contain digits only.'**
  String get errorIdDigitsOnly;

  /// No description provided for @errorPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required.'**
  String get errorPhoneRequired;

  /// No description provided for @errorPhoneDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Phone must contain digits only.'**
  String get errorPhoneDigitsOnly;

  /// No description provided for @errorInviteCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate invite code. Please try again.'**
  String get errorInviteCodeFailed;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @statusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get statusIdle;

  /// No description provided for @statusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get statusWorking;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @employeeAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Meamore Employee'**
  String get employeeAppTitle;

  /// No description provided for @employeeSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee setup'**
  String get employeeSetupTitle;

  /// No description provided for @employeeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeIdLabel;

  /// No description provided for @employeeIdDigitsOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID (digits only)'**
  String get employeeIdDigitsOnlyLabel;

  /// No description provided for @employeeIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your employee ID to continue.'**
  String get employeeIdHelp;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @logoutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutAction;

  /// No description provided for @changeEmployeeAction.
  ///
  /// In en, this message translates to:
  /// **'Change employee'**
  String get changeEmployeeAction;

  /// No description provided for @errorEmployeeIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Employee ID is required.'**
  String get errorEmployeeIdRequired;

  /// No description provided for @errorEmployeeIdDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Employee ID must contain digits only.'**
  String get errorEmployeeIdDigitsOnly;

  /// No description provided for @errorEmployeeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Employee not found. Check your ID and try again.'**
  String get errorEmployeeNotFound;

  /// No description provided for @errorEmployeeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load employee. Please try again.'**
  String get errorEmployeeLoadFailed;

  /// No description provided for @treatmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatmentTitle;

  /// No description provided for @treatmentNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New treatment'**
  String get treatmentNewTitle;

  /// No description provided for @treatmentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Treatment type'**
  String get treatmentTypeLabel;

  /// No description provided for @dogNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Dog name'**
  String get dogNameLabel;

  /// No description provided for @dogBreedLabel.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get dogBreedLabel;

  /// No description provided for @dogOwnerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get dogOwnerNameLabel;

  /// No description provided for @coatConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Coat condition'**
  String get coatConditionLabel;

  /// No description provided for @coatConditionHelp.
  ///
  /// In en, this message translates to:
  /// **'1 = awful, 5 = perfect'**
  String get coatConditionHelp;

  /// No description provided for @startTreatmentAction.
  ///
  /// In en, this message translates to:
  /// **'Start treatment'**
  String get startTreatmentAction;

  /// No description provided for @finishTreatmentAction.
  ///
  /// In en, this message translates to:
  /// **'Finish treatment'**
  String get finishTreatmentAction;

  /// No description provided for @treatmentInProgress.
  ///
  /// In en, this message translates to:
  /// **'Treatment in progress'**
  String get treatmentInProgress;

  /// No description provided for @treatmentSaved.
  ///
  /// In en, this message translates to:
  /// **'Treatment saved.'**
  String get treatmentSaved;

  /// No description provided for @errorTreatmentTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Treatment type is required.'**
  String get errorTreatmentTypeRequired;

  /// No description provided for @errorDogNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Dog name is required.'**
  String get errorDogNameRequired;

  /// No description provided for @errorDogBreedRequired.
  ///
  /// In en, this message translates to:
  /// **'Breed is required.'**
  String get errorDogBreedRequired;

  /// No description provided for @errorOwnerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Owner name is required.'**
  String get errorOwnerNameRequired;

  /// No description provided for @errorCoatConditionRequired.
  ///
  /// In en, this message translates to:
  /// **'Coat condition is required.'**
  String get errorCoatConditionRequired;

  /// No description provided for @errorCoatConditionRange.
  ///
  /// In en, this message translates to:
  /// **'Coat condition must be between 1 and 5.'**
  String get errorCoatConditionRange;

  /// No description provided for @errorStartTreatmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start treatment. Please try again.'**
  String get errorStartTreatmentFailed;

  /// No description provided for @errorFinishTreatmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to finish treatment. Please try again.'**
  String get errorFinishTreatmentFailed;

  /// No description provided for @statusBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get statusBusy;

  /// No description provided for @startedAtValue.
  ///
  /// In en, this message translates to:
  /// **'Started: {time}'**
  String startedAtValue(String time);

  /// No description provided for @endedAtValue.
  ///
  /// In en, this message translates to:
  /// **'Ended: {time}'**
  String endedAtValue(String time);

  /// Page title: reports
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// UI label: report period
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportPeriodLabel;

  /// UI label: report anchor date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportDateLabel;

  /// UI label: report date range
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get reportRangeLabel;

  /// Dropdown option: all employees
  ///
  /// In en, this message translates to:
  /// **'All employees'**
  String get reportAllEmployeesOption;

  /// Button: generate report preview
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get reportGenerateAction;

  /// Button: generate Excel report
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get reportGenerateExcelAction;

  /// Empty state: no treatments found for report range
  ///
  /// In en, this message translates to:
  /// **'No treatments in selected range.'**
  String get reportNoTreatmentsInRange;

  /// Snackbar: report saved
  ///
  /// In en, this message translates to:
  /// **'Report saved.'**
  String get reportSaved;

  /// Report period option: daily
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reportPeriodDaily;

  /// Report period option: weekly
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportPeriodWeekly;

  /// Report period option: monthly
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportPeriodMonthly;

  /// Report period option: quarterly
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get reportPeriodQuarterly;

  /// UI label: treatedTodayTitle
  ///
  /// In en, this message translates to:
  /// **'Finished today'**
  String get treatedTodayTitle;

  /// UI label: doneByMeTitle
  ///
  /// In en, this message translates to:
  /// **'Done by me'**
  String get doneByMeTitle;

  /// UI label: noBusyTreatments
  ///
  /// In en, this message translates to:
  /// **'No busy treatments'**
  String get noBusyTreatments;

  /// UI label: treatmentTimeColumn
  ///
  /// In en, this message translates to:
  /// **'Treatment time'**
  String get treatmentTimeColumn;

  /// UI label: noTreatedToday
  ///
  /// In en, this message translates to:
  /// **'No treated today'**
  String get noTreatedToday;

  /// UI label: noDoneByMeToday
  ///
  /// In en, this message translates to:
  /// **'No done by me today'**
  String get noDoneByMeToday;

  /// UI title: Queue tab
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// Empty state: queue is empty
  ///
  /// In en, this message translates to:
  /// **'No customers in queue.'**
  String get noCustomersInQueue;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'he': return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
