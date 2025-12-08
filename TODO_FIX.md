# Fix Android Build Error - HCaptchaFlutterWeb Not Found

## Steps to Complete:
- [x] Create stub file for non-web platforms (`lib/src/hcaptcha_flutter_web_stub.dart`)
- [x] Create factory file for web platform (`lib/src/hcaptcha_flutter_web_factory.dart`)
- [x] Update platform interface to use proper conditional imports (`lib/src/hcaptcha_flutter_platform_interface.dart`)
- [ ] Test Android build
- [ ] Verify web build still works

## Current Status:
Implementation complete. Ready for testing.

## Changes Made:
1. Created `lib/src/hcaptcha_flutter_web_stub.dart` - Returns MethodChannelHCaptchaFlutter for mobile platforms
2. Created `lib/src/hcaptcha_flutter_web_factory.dart` - Returns HCaptchaFlutterWeb for web platform
3. Updated `lib/src/hcaptcha_flutter_platform_interface.dart`:
   - Removed direct import of `hcaptcha_flutter_web.dart` and `hcaptcha_flutter_method_channel.dart`
   - Removed `kIsWeb` runtime check
   - Added conditional import that uses factory pattern
   - Changed initialization to use `createPlatformInstance()` factory function
