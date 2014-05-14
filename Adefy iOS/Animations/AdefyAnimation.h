#import <Foundation/Foundation.h>

@interface AdefyAnimation : NSObject
+ (BOOL) canAnimate:(NSArray *)property;
- (double) update:(double)time;
- (BOOL) isDone;
@end