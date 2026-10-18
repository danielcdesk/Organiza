import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:window_manager/window_manager.dart';

import '../application/organiza_store.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate(
      {super.key, required this.store, required this.child, this.authenticate});
  final OrganizaStore store;
  final Widget child;
  final Future<bool> Function()? authenticate;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver, WindowListener {
  static const _secureChannel =
      MethodChannel('com.danielcdesk.organiza/security');
  final _auth = LocalAuthentication();
  bool _locked = false;
  late bool _wasEnabled;
  bool _authenticating = false;
  DateTime? _backgroundedAt;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_preferencesChanged);
    _wasEnabled = widget.store.appLockEnabled;
    if (mounted) {
      windowManager.addListener(this);
      _syncSecureFlag();
    }
    _locked = widget.store.appLockEnabled;
  }

  void _preferencesChanged() {
    if (!mounted) return;
    final enabled = widget.store.appLockEnabled;
    if (enabled != _wasEnabled) {
      setState(() => _locked = enabled);
      _wasEnabled = enabled;
    }
    _syncSecureFlag();
  }

  Future<void> _syncSecureFlag() async {
    try {
      await _secureChannel.invokeMethod<void>(
          'setSecure', widget.store.appLockEnabled);
    } on MissingPluginException {
      // Desktop and widget tests do not expose the Android window channel.
    } on PlatformException {
      // A platform without a secure-window API can still use the app lock.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed &&
        widget.store.appLockEnabled) {
      final elapsed = _backgroundedAt == null
          ? Duration.zero
          : DateTime.now().difference(_backgroundedAt!);
      if (!_locked &&
          !_authenticating &&
          (widget.store.appLockTimeoutMinutes == 0 ||
              elapsed >=
                  Duration(minutes: widget.store.appLockTimeoutMinutes))) {
        _requireUnlock();
      }
      _backgroundedAt = null;
    }
  }

  @override
  void onWindowMinimize() {
    if (widget.store.appLockEnabled && widget.store.lockOnWindowHide) {
      _requireUnlock();
    }
  }

  @override
  void onWindowBlur() {
    if (widget.store.appLockEnabled && widget.store.lockOnWindowHide) {
      _lockIfWindowIsHidden();
    }
  }

  Future<void> _lockIfWindowIsHidden() async {
    try {
      if (!await windowManager.isVisible()) _requireUnlock();
    } on Object {
      // Minimize events remain covered if visibility cannot be queried.
    }
  }

  void _requireUnlock() {
    if (!mounted) return;
    setState(() {
      _locked = true;
      _message = null;
    });
    _syncSecureFlag();
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _message = null;
    });
    try {
      final authenticated = await (widget.authenticate?.call() ??
          _auth.authenticate(
            localizedReason: 'Desbloqueie o Organiza para continuar.',
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          ));
      if (mounted && authenticated) setState(() => _locked = false);
      if (mounted && !authenticated) {
        setState(
            () => _message = 'Não foi possível desbloquear. Tente novamente.');
      }
    } on Object {
      if (mounted) {
        setState(() => _message =
            'Configure a biometria ou o bloqueio de tela do dispositivo para desbloquear.');
      }
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Offstage(offstage: _locked, child: widget.child),
          if (_locked)
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_outline_rounded, size: 54),
                      const SizedBox(height: 18),
                      Text('Organiza bloqueado',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text(
                          'Confirme sua identidade com o dispositivo para continuar.',
                          textAlign: TextAlign.center),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(_message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _authenticating ? null : _unlock,
                        icon: _authenticating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.fingerprint_rounded),
                        label: const Text('Desbloquear'),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_preferencesChanged);
    windowManager.removeListener(this);
    super.dispose();
  }
}
