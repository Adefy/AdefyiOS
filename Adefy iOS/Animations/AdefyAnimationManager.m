#import "AdefyAnimationManager.h"
#import "AdefyRenderer.h"
#import "AdefyAnimation.h"

@implementation AdefyAnimationManager {

@protected
  AdefyRenderer *mRenderer;
  CADisplayLink *mDisplayLink;

  NSMutableArray *mAnimations;
  NSMutableArray *mAnimationsNeedingRemoval;

  double lastUpdate;
}

- (AdefyAnimationManager *)init:(AdefyRenderer *)renderer {
  self = [super init];

  mRenderer = renderer;
  mAnimations = [[NSMutableArray alloc] init];
  mAnimationsNeedingRemoval = [[NSMutableArray alloc] init];

  // Set us up to be updated on each render
  mDisplayLink = [CADisplayLink displayLinkWithTarget:self
                                             selector:@selector(update)];
  [mDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

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
  double currentTimeMS = [mDisplayLink timestamp] * 1000.0;

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