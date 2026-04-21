#import "ShareHandlerMacosPlugin.h"
#if __has_include(<zikzak_share_handler_macos/zikzak_share_handler_macos-Swift.h>)
#import <zikzak_share_handler_macos/zikzak_share_handler_macos-Swift.h>
#else
#import "zikzak_share_handler_macos-Swift.h"
#endif

@implementation ShareHandlerMacosPlatform
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftShareHandlerMacosPlatform registerWithRegistrar:registrar];
}
@end
