import 'app_localizations.dart';

extension AppLocalizationsExt on AppLocalizations {
  /// Temporary compatibility getter if your generated localizations don't have it yet.
  /// Prefer adding it to your ARB and regenerating.
  String get statusBusy {
    // fallback: if you don't have a key yet, show 'Busy'
    return 'Busy';
  }
}
