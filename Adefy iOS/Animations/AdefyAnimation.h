#import <Foundation/Foundation.h>

@interface AdefyAnimation : NSObject
- (void)update:(double)time1;

- (BOOL)canAnimate:(NSString *)property;
@end