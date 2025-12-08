import 'hcaptcha_flutter_platform_interface.dart';
import 'hcaptcha_flutter_web.dart';

/// Factory function for web platform.
/// This file is used when building for web platform.
HCaptchaFlutterPlatform createPlatformInstance() {
  return HCaptchaFlutterWeb();
}
