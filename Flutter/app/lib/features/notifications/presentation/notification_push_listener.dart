import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

class NotificationPushListener with WidgetsBindingObserver {
  NotificationPushListener({required Future<void> Function() onReload})
      : _onReload = onReload;

  final Future<void> Function() _onReload;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    try {
      _foregroundSub = FirebaseMessaging.onMessage.listen((_) => _reload());
      _openedSub =
          FirebaseMessaging.onMessageOpenedApp.listen((_) => _reload());
    } catch (_) {
      // Firebase is optional in local development.
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_foregroundSub?.cancel());
    unawaited(_openedSub?.cancel());
    _foregroundSub = null;
    _openedSub = null;
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  void _reload() {
    unawaited(_onReload());
  }
}
