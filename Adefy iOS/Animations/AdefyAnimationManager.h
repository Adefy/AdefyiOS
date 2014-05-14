#import <Foundation/Foundation.h>

@class AdefyRenderer;
@class AdefyAnimation;

@interface AdefyAnimationManager : NSObject
- (AdefyAnimationManager *)init:(AdefyRenderer *)renderer;

- (void)addAnimation:(AdefyAnimation *)animation;

- (void)removeAnimation:(AdefyAnimation *)animation;

- (void)update;
@end