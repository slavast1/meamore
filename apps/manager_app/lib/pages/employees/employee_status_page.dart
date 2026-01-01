import 'package:flutter/material.dart';

import 'package:meamore_shared/meamore_shared.dart';
import 'package:meamore_shared/models/employee.dart';
import 'package:meamore/models/employee_display.dart';
import 'package:meamore/services/employees_repository.dart';
import 'package:meamore/utils/formatters.dart';
import 'package:meamore/widgets/language_menu_button.dart';

class EmployeeStatusPage extends StatelessWidget {
  const EmployeeStatusPage({
    super.key,
    required this.shopId,
    required this.employeeId,
  });

  final String shopId;
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final repo = EmployeesRepository(shopId: shopId);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.employeeStatusTitle),
        actions: const [LanguageMenuButton()],
      ),
      body: StreamBuilder(
        stream: repo.streamOne(employeeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                t.errorWithMessage(snapshot.error.toString()),
                textAlign: TextAlign.start,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          if (!doc.exists) {
            return Center(
              child: Text(
                t.employeeNotFound,
                textAlign: TextAlign.start,
              ),
            );
          }

          final e = Employee.fromDoc(doc);

          final name = EmployeeDisplay.name(e, t);
          final idNumber = EmployeeDisplay.idNumber(e, t);
          final phone = EmployeeDisplay.phone(e, t);
          final statusText = StatusLocalizer.toText(EmployeeStatus.fromRaw(e.status), t);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${t.idNumberLabel}: $idNumber',
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '${t.phoneLabel}: $phone',
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '${t.statusLabel}: $statusText',
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${t.activeSessionLabel}: ${e.activeSessionId ?? t.noneValue}',
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '${t.startedAtLabel}: ${Formatters.formatTimestamp(context, e.activeStartedAt, t)}',
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
