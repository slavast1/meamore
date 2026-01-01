import 'package:meamore_shared/meamore_shared.dart';

class StatusLocalizer {
  static String toText(String rawStatus, AppLocalizations t) {
    switch (rawStatus.toLowerCase().trim()) {
      case 'idle':
        return t.statusIdle;
      case 'working':
        return t.statusWorking;
      case 'offline':
        return t.statusOffline;
      default:
        return t.statusUnknown;
    }
  }
}
