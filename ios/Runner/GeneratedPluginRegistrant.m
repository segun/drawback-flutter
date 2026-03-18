//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<device_info_plus/FPPDeviceInfoPlusPlugin.h>)
#import <device_info_plus/FPPDeviceInfoPlusPlugin.h>
#else
@import device_info_plus;
#endif

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

#if __has_include(<package_info_plus/FPPPackageInfoPlusPlugin.h>)
#import <package_info_plus/FPPPackageInfoPlusPlugin.h>
#else
@import package_info_plus;
#endif

#if __has_include(<passkeys_darwin/PasskeysPlugin.h>)
#import <passkeys_darwin/PasskeysPlugin.h>
#else
@import passkeys_darwin;
#endif

#if __has_include(<ua_client_hints/UAClientHintsPlugin.h>)
#import <ua_client_hints/UAClientHintsPlugin.h>
#else
@import ua_client_hints;
#endif

#if __has_include(<yandex_mobileads/YandexMobileAdsPlugin.h>)
#import <yandex_mobileads/YandexMobileAdsPlugin.h>
#else
@import yandex_mobileads;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FPPDeviceInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPDeviceInfoPlusPlugin"]];
  [FlutterSecureStorageDarwinPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterSecureStorageDarwinPlugin"]];
  [InAppPurchasePlugin registerWithRegistrar:[registry registrarForPlugin:@"InAppPurchasePlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [FPPPackageInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPPackageInfoPlusPlugin"]];
  [PasskeysPlugin registerWithRegistrar:[registry registrarForPlugin:@"PasskeysPlugin"]];
  [UAClientHintsPlugin registerWithRegistrar:[registry registrarForPlugin:@"UAClientHintsPlugin"]];
  [YandexMobileAdsPlugin registerWithRegistrar:[registry registrarForPlugin:@"YandexMobileAdsPlugin"]];
}

@end
