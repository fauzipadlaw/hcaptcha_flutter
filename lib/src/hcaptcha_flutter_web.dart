import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'hcaptcha_flutter_platform_interface.dart';

/// Web implementation of [HCaptchaFlutterPlatform].
class HCaptchaFlutterWeb extends HCaptchaFlutterPlatform {
  /// Constructs a HCaptchaFlutterWeb
  HCaptchaFlutterWeb();

  static const String _hcaptchaScriptUrl = 'https://js.hcaptcha.com/1/api.js';
  static const String _containerId = 'hcaptcha-container';

  static bool _scriptLoaded = false;
  static Completer<void>? _scriptLoadCompleter;

  web.HTMLElement? _container;
  String? _widgetId;
  FlutterPluginHandler? _handler;

  /// Registers this class as the default instance of [HCaptchaFlutterPlatform].
  static void registerWith(Registrar registrar) {
    HCaptchaFlutterPlatform.instance = HCaptchaFlutterWeb();
  }

  @override
  void setMethodCallHandler(FlutterPluginHandler handler) {
    _handler = handler;
  }

  @override
  Future<void> show(Map<String, dynamic> config) async {
    final siteKey = config['siteKey'] as String?;
    final language = config['language'] as String? ?? 'en';

    if (siteKey == null || siteKey.isEmpty) {
      throw PlatformException(
        code: 'INVALID_CONFIG',
        message: 'siteKey is required',
      );
    }

    // Ensure hCaptcha script is loaded
    await _ensureScriptLoaded();

    // Create or get container
    _ensureContainer();

    // Render hCaptcha widget
    await _renderWidget(siteKey, language);

    // Execute the challenge
    _executeChallenge();
  }

  /// Ensures the hCaptcha JavaScript SDK is loaded
  Future<void> _ensureScriptLoaded() async {
    if (_scriptLoaded) {
      return;
    }

    if (_scriptLoadCompleter != null) {
      return _scriptLoadCompleter!.future;
    }

    _scriptLoadCompleter = Completer<void>();

    try {
      // Check if script already exists
      final existingScript =
          web.document.querySelector('script[src*="hcaptcha.com"]');
      if (existingScript != null) {
        _scriptLoaded = true;
        _scriptLoadCompleter!.complete();
        return;
      }

      // Create and inject script
      final script =
          web.document.createElement('script') as web.HTMLScriptElement
            ..src = _hcaptchaScriptUrl
            ..async = true
            ..defer = true;

      final completer = Completer<void>();

      script.onload = (web.Event event) {
        _scriptLoaded = true;
        completer.complete();
        _scriptLoadCompleter!.complete();
      }.toJS;

      script.onerror = (web.Event event) {
        final error = PlatformException(
          code: 'SCRIPT_LOAD_FAILED',
          message: 'Failed to load hCaptcha script',
        );
        completer.completeError(error);
        _scriptLoadCompleter!.completeError(error);
      }.toJS;

      web.document.head?.appendChild(script);
      await completer.future;
    } catch (e) {
      _scriptLoadCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Ensures the container element exists
  void _ensureContainer() {
    _container = web.document.getElementById(_containerId) as web.HTMLElement?;

    if (_container == null) {
      _container = web.document.createElement('div') as web.HTMLDivElement
        ..id = _containerId
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.zIndex = '999999'
        ..style.display = 'none';

      web.document.body?.appendChild(_container!);
    }
  }

  /// Renders the hCaptcha widget
  Future<void> _renderWidget(String siteKey, String language) async {
    if (_container == null) return;

    // Clear previous widget if exists
    if (_widgetId != null) {
      try {
        _resetWidget();
      } catch (e) {
        // Ignore reset errors
      }
    }

    // Clear container
    while (_container!.firstChild != null) {
      _container!.removeChild(_container!.firstChild!);
    }

    // Create widget container
    final widgetContainer =
        web.document.createElement('div') as web.HTMLDivElement
          ..style.position = 'absolute'
          ..style.top = '50%'
          ..style.left = '50%'
          ..style.transform = 'translate(-50%, -50%)';

    _container!.appendChild(widgetContainer);

    // Create overlay background
    final overlay = web.document.createElement('div') as web.HTMLDivElement
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0, 0, 0, 0.5)'
      ..style.zIndex = '-1';

    _container!.appendChild(overlay);

    // Render hCaptcha
    try {
      final hcaptcha = _getHCaptcha();

      final config = HCaptchaConfig(
        sitekey: siteKey,
        size: 'invisible',
        hl: language,
        callback: _onSuccess.toJS,
        errorCallback: _onError.toJS,
        expiredCallback: _onExpired.toJS,
        openCallback: _onOpen.toJS,
        closeCallback: _onClose.toJS,
      );

      _widgetId = hcaptcha.render(widgetContainer, config).toString();
    } catch (e) {
      throw PlatformException(
        code: 'RENDER_FAILED',
        message: 'Failed to render hCaptcha widget: $e',
      );
    }
  }

  /// Executes the hCaptcha challenge
  void _executeChallenge() {
    if (_widgetId == null) return;

    try {
      final hcaptcha = _getHCaptcha();
      hcaptcha.execute(_widgetId!);
    } catch (e) {
      _invokeHandler('error', {
        'code': 'EXECUTE_FAILED',
        'msg': 'Failed to execute hCaptcha: $e',
      });
      _hideContainer();
    }
  }

  /// Resets the hCaptcha widget
  void _resetWidget() {
    if (_widgetId == null) return;

    try {
      final hcaptcha = _getHCaptcha();
      hcaptcha.reset(_widgetId!);
    } catch (e) {
      // Ignore reset errors
    }
  }

  /// Removes the hCaptcha widget
  void _removeWidget() {
    if (_widgetId == null) return;

    try {
      final hcaptcha = _getHCaptcha();
      hcaptcha.remove(_widgetId!);
      _widgetId = null;
    } catch (e) {
      // Ignore removal errors
    }
  }

  /// Gets the hCaptcha JavaScript object
  HCaptchaJS _getHCaptcha() {
    return hcaptchaGlobal;
  }

  /// Shows the container
  void _showContainer() {
    _container?.style.display = 'block';
  }

  /// Hides the container
  void _hideContainer() {
    _container?.style.display = 'none';
  }

  /// Callback when hCaptcha is successfully solved
  void _onSuccess(String token) {
    _invokeHandler('success', {'token': token});
    _hideContainer();
    _removeWidget();
  }

  /// Callback when hCaptcha encounters an error
  void _onError([JSAny? error]) {
    _invokeHandler('error', {
      'code': 'HCAPTCHA_ERROR',
      'msg': error?.toString() ?? 'Unknown error',
    });
    _hideContainer();
    _removeWidget();
  }

  /// Callback when hCaptcha token expires
  void _onExpired() {
    _invokeHandler('error', {
      'code': 'TOKEN_EXPIRED',
      'msg': 'hCaptcha token expired',
    });
    _hideContainer();
    _removeWidget();
  }

  /// Callback when hCaptcha challenge opens
  void _onOpen() {
    _showContainer();
    _invokeHandler('open', null);
  }

  /// Callback when hCaptcha challenge closes
  void _onClose() {
    _hideContainer();
  }

  /// Invokes the method call handler
  void _invokeHandler(String method, dynamic arguments) {
    if (_handler != null) {
      final call = MethodCall(method, arguments);
      _handler!(call);
    }
  }
}

// JavaScript interop definitions for hCaptcha API
@JS('hcaptcha')
external HCaptchaJS get hcaptchaGlobal;

@JS()
@staticInterop
class HCaptchaJS {}

extension HCaptchaJSExtension on HCaptchaJS {
  external JSAny render(web.HTMLElement container, HCaptchaConfig config);
  external void execute(String widgetId);
  external void reset(String widgetId);
  external void remove(String widgetId);
}

@JS()
@anonymous
@staticInterop
class HCaptchaConfig {
  external factory HCaptchaConfig({
    required String sitekey,
    required String size,
    required String hl,
    required JSFunction callback,
    required JSFunction errorCallback,
    required JSFunction expiredCallback,
    required JSFunction openCallback,
    required JSFunction closeCallback,
  });
}

extension HCaptchaConfigExtension on HCaptchaConfig {
  external String get sitekey;
  external String get size;
  external String get hl;
  external JSFunction get callback;
  @JS('error-callback')
  external JSFunction get errorCallback;
  @JS('expired-callback')
  external JSFunction get expiredCallback;
  @JS('open-callback')
  external JSFunction get openCallback;
  @JS('close-callback')
  external JSFunction get closeCallback;
}
