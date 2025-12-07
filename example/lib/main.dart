import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hcaptcha_flutter/hcaptcha_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Ready';
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupHCaptchaHandler();
  }

  void _setupHCaptchaHandler() {
    HCaptchaFlutter.setMethodCallHandler((MethodCall call) async {
      if (kDebugMode) {
        print('method: ${call.method}, arguments: ${call.arguments}');
      }

      setState(() {
        _isLoading = false;
      });

      switch (call.method) {
        case 'success':
          if (call.arguments != null) {
            final res = call.arguments as Map<dynamic, dynamic>;
            final token = res['token'] as String?;
            setState(() {
              _status = 'Success!';
              _token = token;
            });
            log('token: $token');
          }
          break;
        case 'error':
          if (call.arguments != null) {
            final res = call.arguments as Map<dynamic, dynamic>;
            final error = res['msg'] ?? res['error'] ?? 'Unknown error';
            setState(() {
              _status = 'Error: $error';
              _token = null;
            });
            log('error: $error');
          }
          break;
        case 'open':
          setState(() {
            _status = 'Challenge opened';
          });
          break;
        default:
          break;
      }
    });
  }

  Future<void> _showCaptcha() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading...';
      _token = null;
    });

    try {
      await HCaptchaFlutter.show({
        'siteKey': 'a5f74b19-9e45-40e0-b45d-47ff91b7a6c2',
        'language': 'en',
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
      log('Error showing captcha: $e');
    }
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'Android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'iOS';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HCaptcha Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('HCaptcha Plugin Example'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'HCaptcha Flutter Plugin',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform: ${_getPlatformName()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _status,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (_token != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Token',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SelectableText(
                              _token!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showCaptcha,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user),
                  label: Text(_isLoading ? 'Loading...' : 'Show Captcha'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
