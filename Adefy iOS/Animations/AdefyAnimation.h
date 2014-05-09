#import <Foundation/Foundation.h>

@interface AdefyAnimation : NSObject
+ (BOOL)canAnimate:(NSString *)property;
- (double)update:(double)time;
@end