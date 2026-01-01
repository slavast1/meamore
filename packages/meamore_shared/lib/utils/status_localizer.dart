import '../l10n/app_localizations.dart';
import '../models/employee_status.dart';

class StatusLocalizer {
  static String toText(EmployeeStatus status, AppLocalizations t) {
    return switch (status) {
      EmployeeStatus.idle => t.statusIdle,
      EmployeeStatus.busy => t.statusBusy,
      EmployeeStatus.offline => t.statusOffline,
      EmployeeStatus.unknown => t.statusUnknown,
    };
  }
}
