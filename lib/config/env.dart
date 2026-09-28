import 'package:flutter/foundation.dart';

/// El emulador de Android no ve `localhost` del equipo anfitrion: lo expone
/// como 10.0.2.2. En web y escritorio se usa localhost tal cual.
class Env {
  static const String _hostDefecto =
      bool.hasEnvironment('API_HOST') ? String.fromEnvironment('API_HOST') : '';

  static String get host {
    if (_hostDefecto.isNotEmpty) return _hostDefecto;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get apiDjango => 'http://$host:8010';
  static String get apiFastapi => 'http://$host:8011';
  static String get wsFastapi => 'ws://$host:8011';
}
