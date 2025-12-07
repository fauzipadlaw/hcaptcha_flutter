# HCaptcha for Flutter

[![Pub Version](https://img.shields.io/pub/v/hcaptcha_flutter)](https://pub.dev/packages/hcaptcha_flutter)

A Flutter plugin for integrating hCaptcha verification into your Flutter applications. Supports Android, iOS, and Web platforms.

## Features

- ✅ Android support
- ✅ iOS support
- ✅ Web support
- ✅ Invisible captcha mode
- ✅ Multiple language support
- ✅ Event callbacks (success, error, open, close)

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅        |
| iOS      | ✅        |
| Web      | ✅        |
| macOS    | ❌        |
| Windows  | ❌        |
| Linux    | ❌        |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  hcaptcha_flutter: ^0.0.2
```

Then run:

```bash
flutter pub get
```

## Platform-Specific Setup

### Android

No additional setup required. The plugin uses the hCaptcha Android SDK.

### iOS

No additional setup required. The plugin uses the hCaptcha iOS SDK.

### Web

No additional setup required. The plugin automatically loads the hCaptcha JavaScript SDK from the CDN.

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hcaptcha_flutter/hcaptcha_flutter.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _setupHCaptchaHandler();
  }

  void _setupHCaptchaHandler() {
    HCaptchaFlutter.setMethodCallHandler((MethodCall call) async {
      print('method: ${call.method}, arguments: ${call.arguments}');

      switch (call.method) {
        case 'success':
          if (call.arguments != null) {
            final res = call.arguments as Map<dynamic, dynamic>;
            final token = res['token'] as String?;
            setState(() {
              _token = token;
            });
            print('hCaptcha token: $token');
          }
          break;
        case 'error':
          if (call.arguments != null) {
            final res = call.arguments as Map<dynamic, dynamic>;
            final error = res['msg'] ?? res['error'] ?? 'Unknown error';
            print('hCaptcha error: $error');
          }
          break;
        case 'open':
          print('hCaptcha challenge opened');
          break;
        default:
          break;
      }
    });
  }

  Future<void> _showCaptcha() async {
    try {
      await HCaptchaFlutter.show({
        'siteKey': 'your-site-key-here',
        'language': 'en',
      });
    } catch (e) {
      print('Error showing captcha: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('HCaptcha Example'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: _showCaptcha,
            child: Text('Show Captcha'),
          ),
        ),
      ),
    );
  }
}
```

## Configuration Options

The `show()` method accepts a configuration map with the following options:

| Parameter | Type   | Required | Description                                    |
|-----------|--------|----------|------------------------------------------------|
| siteKey   | String | Yes      | Your hCaptcha site key                         |
| language  | String | No       | Language code (default: 'en')                  |

## Event Callbacks

The plugin provides several event callbacks through the method call handler:

### success
Triggered when the user successfully completes the captcha challenge.

**Arguments:**
- `token` (String): The verification token to send to your backend

### error
Triggered when an error occurs during the captcha process.

**Arguments:**
- `code` (String): Error code
- `msg` or `error` (String): Error message

### open
Triggered when the captcha challenge dialog opens (iOS and Web only).

**Arguments:** None

### close
Triggered when the captcha challenge dialog closes (Web only).

**Arguments:** None

## Getting Your Site Key

1. Sign up for a free account at [hCaptcha.com](https://www.hcaptcha.com/)
2. Add your site domain
3. Copy your site key from the dashboard

## Example

Check out the [example](example/) directory for a complete working example that demonstrates:
- Setting up the method call handler
- Showing the captcha
- Handling success and error callbacks
- Displaying the verification token
- Platform detection

## Web-Specific Notes

- The web implementation uses the hCaptcha JavaScript SDK
- The captcha is displayed in an invisible mode by default
- The SDK is automatically loaded from the hCaptcha CDN
- No additional HTML modifications are required

## Troubleshooting

### Android

If you encounter build issues, ensure your `minSdkVersion` is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS

If you encounter issues, ensure your iOS deployment target is at least 12.0:

```ruby
platform :ios, '12.0'
```

### Web

If the captcha doesn't appear:
1. Check browser console for errors
2. Verify your site key is correct
3. Ensure your domain is registered in the hCaptcha dashboard

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- [hCaptcha Documentation](https://docs.hcaptcha.com/)
- [hCaptcha Dashboard](https://dashboard.hcaptcha.com/)
- [Package on pub.dev](https://pub.dev/packages/hcaptcha_flutter)
- [GitHub Repository](https://github.com/FlutterFleet/FlutterFleet/tree/main/packages/hcaptcha_flutter)
