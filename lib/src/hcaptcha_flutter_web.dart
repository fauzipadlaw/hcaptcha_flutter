import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'hcaptcha_flutter_platform_interface.dart';

/// Web implementation of [HCaptchaFlutterPlatform].
class HCaptchaFlutterWeb extends HCaptchaFlutterPlatform {
  /// Constructs a HCaptchaFlutterWeb
  HCaptchaFlutterWeb();

  static const String _hcaptchaScriptUrl = 'https://js.hcaptcha.com/1/api.js';
  static const String _containerId = 'hcaptcha-container';

  static bool _scriptLoaded = false;
  static Completer<void>? _scriptLoadCompleter;

  html.Element? _container;
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
          html.document.querySelector('script[src*="hcaptcha.com"]');
      if (existingScript != null) {
        _scriptLoaded = true;
        _scriptLoadCompleter!.complete();
        return;
      }

      // Create and inject script
      final script = html.ScriptElement()
        ..src = _hcaptchaScriptUrl
        ..async = true
        ..defer = true;

      final completer = Completer<void>();

      script.onLoad.listen((_) {
        _scriptLoaded = true;
        completer.complete();
        _scriptLoadCompleter!.complete();
      });

      script.onError.listen((_) {
        final error = PlatformException(
          code: 'SCRIPT_LOAD_FAILED',
          message: 'Failed to load hCaptcha script',
        );
        completer.completeError(error);
        _scriptLoadCompleter!.completeError(error);
      });

      html.document.head?.append(script);
      await completer.future;
    } catch (e) {
      _scriptLoadCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Ensures the container element exists
  void _ensureContainer() {
    _container = html.document.getElementById(_containerId);

    if (_container == null) {
      _container = html.DivElement()
        ..id = _containerId
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.zIndex = '999999'
        ..style.display = 'none';

      html.document.body?.append(_container!);
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
    _container!.children.clear();

    // Create widget container
    final widgetContainer = html.DivElement()
      ..style.position = 'absolute'
      ..style.top = '50%'
      ..style.left = '50%'
      ..style.transform = 'translate(-50%, -50%)';

    _container!.append(widgetContainer);

    // Create overlay background
    final overlay = html.DivElement()
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0, 0, 0, 0.5)'
      ..style.zIndex = '-1';

    _container!.append(overlay);

    // Render hCaptcha
    try {
      final hcaptcha = js.context['hcaptcha'];

      final config = js.JsObject.jsify({
        'sitekey': siteKey,
        'size': 'invisible',
        'hl': language,
        'callback': _createJsCallback(_onSuccess),
        'error-callback': _createJsCallback(_onError),
        'expired-callback': _createJsCallback(_onExpired),
        'open-callback': _createJsCallback(_onOpen),
        'close-callback': _createJsCallback(_onClose),
      });

      final hcaptchaObj = js.JsObject.fromBrowserObject(hcaptcha);
      _widgetId = hcaptchaObj
          .callMethod('render', [widgetContainer, config]).toString();
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
      final hcaptcha = js.context['hcaptcha'];
      final hcaptchaObj = js.JsObject.fromBrowserObject(hcaptcha);
      hcaptchaObj.callMethod('execute', [_widgetId]);
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
      final hcaptcha = js.context['hcaptcha'];
      final hcaptchaObj = js.JsObject.fromBrowserObject(hcaptcha);
      hcaptchaObj.callMethod('reset', [_widgetId]);
    } catch (e) {
      // Ignore reset errors
    }
  }

  /// Removes the hCaptcha widget
  void _removeWidget() {
    if (_widgetId == null) return;

    try {
      final hcaptcha = js.context['hcaptcha'];
      final hcaptchaObj = js.JsObject.fromBrowserObject(hcaptcha);
      hcaptchaObj.callMethod('remove', [_widgetId]);
      _widgetId = null;
    } catch (e) {
      // Ignore removal errors
    }
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
  void _onError(dynamic error) {
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

  /// Creates a JavaScript callback function
  js.JsFunction _createJsCallback(Function dartFunction) {
    return js.JsFunction.withThis((thisArg, [arg1, arg2, arg3]) {
      if (arg1 != null) {
        return dartFunction(arg1);
      } else {
        return dartFunction();
      }
    });
  }

  /// Invokes the method call handler
  void _invokeHandler(String method, dynamic arguments) {
    if (_handler != null) {
      final call = MethodCall(method, arguments);
      _handler!(call);
    }
  }
}
