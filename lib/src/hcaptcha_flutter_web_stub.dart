import 'hcaptcha_flutter_platform_interface.dart';
import 'hcaptcha_flutter_method_channel.dart';

/// Stub implementation for non-web platforms.
/// This file is used when building for mobile platforms (Android/iOS).
/// The actual web implementation is in hcaptcha_flutter_web.dart.
HCaptchaFlutterPlatform createPlatformInstance() {
  return MethodChannelHCaptchaFlutter();
}
