import 'package:meamore_shared/models/employee.dart';

class EmployeeSort {
  static int byLastThenFirst(Employee a, Employee b) {
    final c1 = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
    if (c1 != 0) return c1;
    return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
  }
}
