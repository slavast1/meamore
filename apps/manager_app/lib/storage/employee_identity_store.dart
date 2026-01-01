import 'package:shared_preferences/shared_preferences.dart';

class EmployeeIdentityStore {
  static const _key = 'employee_id';

  Future<void> setEmployeeId(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, id);
  }

  Future<String?> getEmployeeId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key);
  }

  Future<void> clearEmployeeId() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }

  Future<String?> loadEmployeeId() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_key);
    if (v == null) return null;
    final trimmed = v.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> saveEmployeeId(String employeeId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, employeeId.trim());
  }

}
