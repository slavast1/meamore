import 'package:flutter/material.dart';

import 'app_lock_method.dart';
import 'app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.service,
    required this.method,
    required this.child,
  });

  final AppLockService service;
  final AppLockMethod method;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _unlocked = false;
  bool _busy = false;

  // ✅ Prevents infinite auto prompting
  bool _autoPromptDone = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoPrompt();
    });
  }

  Future<void> _maybeAutoPrompt() async {
    if (_autoPromptDone) return;
    _autoPromptDone = true;
    await _prompt();
  }

  Future<void> _prompt() async {
    if (!mounted) return;
    if (_busy) return;

    if (widget.method == AppLockMethod.none) {
      setState(() => _unlocked = true);
      return;
    }

    setState(() => _busy = true);

    final supported = await widget.service.isDeviceSupported();
    if (!mounted) return;

    if (!supported) {
      setState(() {
        _busy = false;
        _unlocked = true; // no auth available => allow
      });
      return;
    }

    final ok = await widget.service.authenticate(
      method: widget.method,
      reason: 'Unlock Meamore',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _unlocked = ok; // if false -> stay locked, user must press button
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    // No Scaffold here (this widget is above MaterialApp)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(
          child: _busy
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _prompt,
                  child: const Text('Unlock'),
                ),
        ),
      ),
    );
  }
}
