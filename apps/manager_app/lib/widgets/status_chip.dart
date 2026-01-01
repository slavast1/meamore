import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(text));
  }
}
