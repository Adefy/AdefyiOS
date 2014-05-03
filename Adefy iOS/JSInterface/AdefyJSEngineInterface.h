#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol AdefyJSEngineInterfaceExports <JSExport>

JSExportAs(initialize,
- (void) initialize:(NSString *)ad
              width:(int)width
             height:(int)height
           logLevel:(int)logLevel
                 id:(NSString *)id);

- (NSString *) getClearColor;
JSExportAs(setClearColor,
- (void) setClearColor:(float)r
                     g:(float)g
                     b:(float)b);

JSExportAs(setRemindMeButton,
- (void) setRemindMeButton:(float)x
                         y:(float)y
                     width:(float)width
                    height:(float)height);

JSExportAs(setLogLevel, - (void) setLogLevel:(int)level);
- (NSString *) getCameraPosition;
JSExportAs(setCameraPosition, - (void) setCameraPosition:(float)x y:(float)y);

- (void) triggerEnd;
JSExportAs(setOrientation, - (void) setOrientation:(NSString *)orientation);

JSExportAs(log, - (void) log:(NSString *)string);

@end

@interface AdefyJSEngineInterface : NSObject <AdefyJSEngineInterfaceExports>
@end