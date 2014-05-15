#import "AdefyAnimationManager.h"
#import "AdefyRenderer.h"
#import "AdefyAnimation.h"

@implementation AdefyAnimationManager {

@protected
  AdefyRenderer *mRenderer;

  NSMutableArray *mAnimations;
  NSMutableArray *mAnimationsNeedingRemoval;

  double lastUpdate;
}

- (AdefyAnimationManager *)init:(AdefyRenderer *)renderer {
  self = [super init];

  mRenderer = renderer;
  mAnimations = [[NSMutableArray alloc] init];
  mAnimationsNeedingRemoval = [[NSMutableArray alloc] init];

  return self;
}

- (void) addAnimation:(AdefyAnimation *)animation {
  [mAnimations addObject:animation];
}

- (void) removeAnimation:(AdefyAnimation *)animation {
  [mAnimations removeObject:animation];
}

// Update each individual animation
- (void) update {
  double currentTimeMS = CACurrentMediaTime() * 1000.0;

  for(AdefyAnimation *animation in mAnimations) {
    [animation update:currentTimeMS];

    if([animation isDone]) {
      [mAnimationsNeedingRemoval addObject:animation];
    }
  }

  for(AdefyAnimation *animation in mAnimationsNeedingRemoval) {
    [mAnimations removeObject:animation];
  }

  [mAnimationsNeedingRemoval removeAllObjects];
}

@end