import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meamore_shared/meamore_shared.dart';

class Formatters {
  static String formatTimestamp(BuildContext context, dynamic value, AppLocalizations t) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    if (value is Timestamp) {
      final dt = value.toDate();
      return DateFormat.yMd(localeTag).add_Hm().format(dt);
    }

    if (value is DateTime) {
      return DateFormat.yMd(localeTag).add_Hm().format(value);
    }

    if (value == null) return t.notAvailableValue;
    return value.toString();
  }
}
