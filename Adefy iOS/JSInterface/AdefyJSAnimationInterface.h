#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class AdefyRenderer;
@class AdefyAnimationManager;

@protocol AdefyJSAnimationInterfaceExports <JSExport>

JSExportAs(canAnimate, - (BOOL) canAnimate:(NSString *)property);
JSExportAs(getAnimationName, - (NSString *) getAnimationName:(NSString *)property);
JSExportAs(preCalculateBez, - (NSString *) preCalculateBez:(NSString *)options);
JSExportAs(animate,
- (void) animate:(int)id
properties:(NSString *)properties
options:(NSString *)options);

@end

@interface AdefyJSAnimationInterface : NSObject <AdefyJSAnimationInterfaceExports>

- (AdefyJSAnimationInterface *)init:(AdefyRenderer *)renderer
               withAnimationManager:(AdefyAnimationManager *)manager;

@end