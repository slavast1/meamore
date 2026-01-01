enum EmployeeStatus {
  idle,
  busy,
  offline,
  unknown;

  static EmployeeStatus fromRaw(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'idle':
        return EmployeeStatus.idle;
      case 'busy':
        return EmployeeStatus.busy;
      case 'offline':
        return EmployeeStatus.offline;
      default:
        return EmployeeStatus.unknown;
    }
  }

  String toRaw() => switch (this) {
        EmployeeStatus.idle => 'idle',
        EmployeeStatus.busy => 'busy',
        EmployeeStatus.offline => 'offline',
        EmployeeStatus.unknown => 'unknown',
      };
}
