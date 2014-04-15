#import <Foundation/Foundation.h>

@interface AdefyJSEngineInterface : NSObject

+ (void) initialize:(NSString *)ad
              width:(int)width
             height:(int)height
           logLevel:(int)logLevel
                 id:(NSString *)id;

+ (NSString *) getClearColor;
+ (void) setClearColor:(float)r
                     g:(float)g
                     b:(float)b;

+ (void) setRemindMeButton:(float)x
                         y:(float)y
                     width:(float)width
                    height:(float)height;

+ (void) setLogLevel:(int)level;
+ (NSString *) getCameraPosition;
+ (void) setCameraPosition:(float)x
                         y:(float)y;

+ (void) triggerEnd;
+ (void) setOrientation:(NSString *)orientation;

@end