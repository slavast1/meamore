import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:meamore_shared/meamore_shared.dart';
import 'package:meamore/firebase_options.dart';
import 'package:meamore/pages/employees/add_employee_page.dart';
import 'package:meamore/pages/employees/employees_page.dart';

// ?  authentication
import 'package:meamore/security/app_lock_gate.dart';
import 'package:meamore/security/app_lock_method.dart';
import 'package:meamore/security/app_lock_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.init(); // use the last choosen language
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String shopId = 'meamore'; 

  @override
  Widget build(BuildContext context) {
    final lockService = AppLockService();

    return AppLockGate(
      service: lockService,
      method: kIsWeb ? AppLockMethod.none : AppLockMethod.auto,
      child: ValueListenableBuilder<Locale?>(

        valueListenable: AppLocale.overrideLocale,
        builder: (_, overrideLocale, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Barbershop Admin',

            // ?  localization
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,

            // If overrideLocale is null -> follow device
            locale: overrideLocale,

            localeResolutionCallback: (deviceLocale, supported) {
              // If user forced locale: just use it
              if (overrideLocale != null) return overrideLocale;

              // Follow device, fallback to English
              if (deviceLocale == null) return const Locale('en');
              for (final l in supported) {
                if (l.languageCode == deviceLocale.languageCode) return l;
              }
              return const Locale('en');
            },

            home: const EmployeesPage(shopId: shopId),
            routes: {
              '/addEmployee': (_) => const AddEmployeePage(shopId: shopId),
            },
          );
        },
      ),
    );
  }
}

