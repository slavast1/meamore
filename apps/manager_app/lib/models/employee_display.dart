import 'package:meamore_shared/meamore_shared.dart';
import 'package:meamore_shared/models/employee.dart';

class EmployeeDisplay {
  static String name(Employee e, AppLocalizations t) => e.displayName(t.noNameValue);

  static String idNumber(Employee e, AppLocalizations t) {
    final v = e.idNumberOrLogical.trim();
    return v.isEmpty ? t.noIdValue : v;
  }

  static String phone(Employee e, AppLocalizations t) {
    final v = e.phone.trim();
    return v.isEmpty ? t.noPhoneValue : v;
  }
}
