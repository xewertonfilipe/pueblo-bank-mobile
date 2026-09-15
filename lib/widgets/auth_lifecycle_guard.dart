import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';

class AuthLifecycleGuard extends StatefulWidget {
  const AuthLifecycleGuard({
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AuthLifecycleGuard> createState() => _AuthLifecycleGuardState();
}

class _AuthLifecycleGuardState extends State<AuthLifecycleGuard>
    with WidgetsBindingObserver {
  late final AuthProvider _auth;
  bool _wasInBackground = false;
  bool _redirectedToLogin = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_handleAuthChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (!_auth.hasUnlockableSession) {
      _redirectedToLogin = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _wasInBackground = true;
        unawaited(_auth.lock());
      case AppLifecycleState.resumed:
        if (_wasInBackground) {
          _wasInBackground = false;
          unawaited(_redirectToLoginIfNeeded());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _redirectToLoginIfNeeded() async {
    if (!mounted || _redirectedToLogin) return;
    if (!_auth.hasUnlockableSession) return;

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_redirectToLoginIfNeeded());
      });
      return;
    }

    _redirectedToLogin = true;
    navigator.pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
