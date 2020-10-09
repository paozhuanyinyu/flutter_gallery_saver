#import "FlutterGallerySaverPlugin.h"
#if __has_include(<flutter_gallery_saver/flutter_gallery_saver-Swift.h>)
#import <flutter_gallery_saver/flutter_gallery_saver-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_gallery_saver-Swift.h"
#endif

@implementation FlutterGallerySaverPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterGallerySaverPlugin registerWithRegistrar:registrar];
}
@end
