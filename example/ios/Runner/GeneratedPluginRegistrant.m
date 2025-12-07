//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<hcaptcha_flutter/HCaptchaFlutterPlugin.h>)
#import <hcaptcha_flutter/HCaptchaFlutterPlugin.h>
#else
@import hcaptcha_flutter;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [HCaptchaFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@"HCaptchaFlutterPlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
}

@end
