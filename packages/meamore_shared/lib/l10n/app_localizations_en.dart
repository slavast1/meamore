// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Barbershop Admin';

  @override
  String get employeesTitle => 'Employees';

  @override
  String get noEmployeesYet => 'No employees yet.';

  @override
  String get addEmployeeTitle => 'Add employee';

  @override
  String get employeeStatusTitle => 'Employee status';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get clear => 'Clear';

  @override
  String get followDevice => 'Follow device';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'Hebrew';

  @override
  String get deleteEmployeesTitle => 'Delete employees';

  @override
  String deleteEmployeesConfirm(int count) {
    return 'Delete $count selected employee(s)?';
  }

  @override
  String get editEmployeeTitle => 'Edit employee';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get idNumberLabel => 'ID number';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get statusLabel => 'Status';

  @override
  String get activeSessionLabel => 'Active session';

  @override
  String get startedAtLabel => 'Started at';

  @override
  String get idNumberDigitsOnlyLabel => 'ID number (digits only)';

  @override
  String get phoneDigitsOnlyLabel => 'Phone (digits only)';

  @override
  String get idCannotBeChanged => 'Cannot be changed';

  @override
  String get noneValue => '(none)';

  @override
  String get notAvailableValue => '(n/a)';

  @override
  String get noNameValue => '(no name)';

  @override
  String get noIdValue => '(no ID)';

  @override
  String get noPhoneValue => '(no phone)';

  @override
  String inviteCodeText(String code) {
    return 'Invite code: $code';
  }

  @override
  String get inviteCodeHelp => 'Give this code to the employee.';

  @override
  String get employeeNotFound => 'Employee not found.';

  @override
  String get errorFirstLastRequired => 'First and last name are required.';

  @override
  String get errorIdRequired => 'ID number is required.';

  @override
  String get errorIdDigitsOnly => 'ID number must contain digits only.';

  @override
  String get errorPhoneRequired => 'Phone is required.';

  @override
  String get errorPhoneDigitsOnly => 'Phone must contain digits only.';

  @override
  String get errorInviteCodeFailed => 'Failed to generate invite code. Please try again.';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get statusIdle => 'Idle';

  @override
  String get statusWorking => 'Working';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get employeeAppTitle => 'Meamore Employee';

  @override
  String get employeeSetupTitle => 'Employee setup';

  @override
  String get employeeIdLabel => 'Employee ID';

  @override
  String get employeeIdDigitsOnlyLabel => 'Employee ID (digits only)';

  @override
  String get employeeIdHelp => 'Enter your employee ID to continue.';

  @override
  String get continueAction => 'Continue';

  @override
  String get logoutAction => 'Sign out';

  @override
  String get changeEmployeeAction => 'Change employee';

  @override
  String get errorEmployeeIdRequired => 'Employee ID is required.';

  @override
  String get errorEmployeeIdDigitsOnly => 'Employee ID must contain digits only.';

  @override
  String get errorEmployeeNotFound => 'Employee not found. Check your ID and try again.';

  @override
  String get errorEmployeeLoadFailed => 'Failed to load employee. Please try again.';

  @override
  String get treatmentTitle => 'Treatment';

  @override
  String get treatmentNewTitle => 'New treatment';

  @override
  String get treatmentTypeLabel => 'Treatment type';

  @override
  String get dogNameLabel => 'Dog name';

  @override
  String get dogBreedLabel => 'Breed';

  @override
  String get dogOwnerNameLabel => 'Owner name';

  @override
  String get coatConditionLabel => 'Coat condition';

  @override
  String get coatConditionHelp => '1 = awful, 5 = perfect';

  @override
  String get startTreatmentAction => 'Start treatment';

  @override
  String get finishTreatmentAction => 'Finish treatment';

  @override
  String get treatmentInProgress => 'Treatment in progress';

  @override
  String get treatmentSaved => 'Treatment saved.';

  @override
  String get errorTreatmentTypeRequired => 'Treatment type is required.';

  @override
  String get errorDogNameRequired => 'Dog name is required.';

  @override
  String get errorDogBreedRequired => 'Breed is required.';

  @override
  String get errorOwnerNameRequired => 'Owner name is required.';

  @override
  String get errorCoatConditionRequired => 'Coat condition is required.';

  @override
  String get errorCoatConditionRange => 'Coat condition must be between 1 and 5.';

  @override
  String get errorStartTreatmentFailed => 'Failed to start treatment. Please try again.';

  @override
  String get errorFinishTreatmentFailed => 'Failed to finish treatment. Please try again.';

  @override
  String get statusBusy => 'Busy';

  @override
  String startedAtValue(String time) {
    return 'Started: $time';
  }

  @override
  String endedAtValue(String time) {
    return 'Ended: $time';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportPeriodLabel => 'Period';

  @override
  String get reportDateLabel => 'Date';

  @override
  String get reportRangeLabel => 'Range';

  @override
  String get reportAllEmployeesOption => 'All employees';

  @override
  String get reportGenerateAction => 'Generate report';

  @override
  String get reportGenerateExcelAction => 'Export to Excel';

  @override
  String get reportNoTreatmentsInRange => 'No treatments in selected range.';

  @override
  String get reportSaved => 'Report saved.';

  @override
  String get reportPeriodDaily => 'Daily';

  @override
  String get reportPeriodWeekly => 'Weekly';

  @override
  String get reportPeriodMonthly => 'Monthly';

  @override
  String get reportPeriodQuarterly => 'Quarterly';

  @override
  String get treatedTodayTitle => 'Finished today';

  @override
  String get doneByMeTitle => 'Done by me';

  @override
  String get noBusyTreatments => 'No busy treatments';

  @override
  String get treatmentTimeColumn => 'Treatment time';

  @override
  String get noTreatedToday => 'No treated today';

  @override
  String get noDoneByMeToday => 'No done by me today';

  @override
  String get queueTitle => 'Queue';

  @override
  String get noCustomersInQueue => 'No customers in queue.';
}
