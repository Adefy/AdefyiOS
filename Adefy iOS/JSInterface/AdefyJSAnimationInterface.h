#import <Foundation/Foundation.h>

@interface AdefyJSAnimationInterface : NSObject

+ (BOOL) canAnimate:(NSString *)property;
+ (NSString *) getAnimationName:(NSString *)property;
+ (NSString *) preCalculateBez:(NSString *)options;
+ (void) animate:(int)id
      properties:(NSString *)properties
         options:(NSString *)options;

@end