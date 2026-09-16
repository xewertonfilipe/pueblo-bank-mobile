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
  bool _redirectScheduled = false;
  bool _contentObscured = false;

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

  void _setContentObscured(bool obscured) {
    if (!mounted || _contentObscured == obscured) return;
    setState(() => _contentObscured = obscured);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_auth.isPickingFile && state != AppLifecycleState.resumed) {
      return;
    }
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _setContentObscured(true);
        _wasInBackground = true;
        unawaited(_auth.lock());
      case AppLifecycleState.resumed:
        _setContentObscured(false);
        if (_wasInBackground) {
          _wasInBackground = false;
          unawaited(_redirectToLoginIfNeeded());
        }
      case AppLifecycleState.inactive:
        _setContentObscured(true);
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _redirectToLoginIfNeeded() async {
    if (!mounted || _redirectedToLogin || _redirectScheduled) return;
    if (!_auth.hasUnlockableSession) return;

    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectScheduled = false;
      if (!mounted || _redirectedToLogin || !_auth.hasUnlockableSession) return;

      final navigator = widget.navigatorKey.currentState;
      if (navigator == null) {
        unawaited(_redirectToLoginIfNeeded());
        return;
      }

      _redirectedToLogin = true;
      navigator.pushNamed(Routes.login, arguments: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topLeft,
      children: [
        widget.child,
        if (_contentObscured)
          const Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ColoredBox(
                color: Colors.white,
                child: Center(child: Icon(Icons.lock_outline, size: 48)),
              ),
            ),
          ),
      ],
    );
  }
}
