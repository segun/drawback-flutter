//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_secure_storage_darwin/FlutterSecureStorageDarwinPlugin.h>)
#import <flutter_secure_storage_darwin/FlutterSecureStorageDarwinPlugin.h>
#else
@import flutter_secure_storage_darwin;
#endif

#if __has_include(<in_app_purchase_storekit/InAppPurchasePlugin.h>)
#import <in_app_purchase_storekit/InAppPurchasePlugin.h>
#else
@import in_app_purchase_storekit;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterSecureStorageDarwinPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterSecureStorageDarwinPlugin"]];
  [InAppPurchasePlugin registerWithRegistrar:[registry registrarForPlugin:@"InAppPurchasePlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
}

@end
