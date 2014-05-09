#import <Foundation/Foundation.h>

@class AdefyRenderer;

@interface AdefyAnimationManager : NSObject
- (AdefyAnimationManager *)init:(AdefyRenderer *)renderer;

- (void)update;
@end