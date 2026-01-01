import 'package:flutter/material.dart';

import 'package:meamore_shared/meamore_shared.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: (value) {
        switch (value) {
          case 'en':
            AppLocale.setEnglish();
            break;
          case 'he':
            AppLocale.setHebrew();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'en', child: Text(t.english)),
        PopupMenuItem(value: 'he', child: Text(t.hebrew)),
      ],
    );
  }
}
