import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Appointments',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppointmentScreen(),
    );
  }
}

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime? selectedDate;
  String? outputText;
  bool isLoading = false;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _prettyJson(dynamic value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  Future<void> _fetchAppointments() async {
    if (selectedDate == null) return;

    setState(() {
      isLoading = true;
      outputText = null;
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final url = kIsWeb
        ? 'https://test-appointments.meamore.workers.dev/?dueDate=$formattedDate'
        : 'https://us-central1-digi-tor.cloudfunctions.net/getBusinessAppointments?dueDate=$formattedDate';


    try {
      final headers = <String, String>{};
      if (!kIsWeb) {
        headers['x-api-key'] =
        'api_3f9c8a1e-7c4a-4c3f-a2c1-91b5a6d0f2c9_bK7QpZxR92Lm';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          outputText = _prettyJson(decoded);
        });
      } else {
        setState(() {
          outputText =
          'HTTP Error: ${response.statusCode}\n\nResponse body:\n${response.body}';
        });
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        outputText = 'Exception: $e\n\nStackTrace:\n$st';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _copyOutput() async {
    if (outputText == null || outputText!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputText!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
  }

  Widget _outputBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Appointments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _pickDate,
              child: const Text('Pick Date'),
            ),
            if (selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Selected: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _fetchAppointments,
              child: const Text('Fetch Appointments'),
            ),
            const SizedBox(height: 16),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (outputText != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Output (${outputText!.length} chars)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _copyOutput,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: _outputBox(outputText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
