#import "AdefyAnimationManager.h"
#import "AdefyRenderer.h"
#import "AdefyAnimation.h"

@implementation AdefyAnimationManager {

@protected
  AdefyRenderer *mRenderer;
  CADisplayLink *mDisplayLink;

  NSMutableArray* mAnimations;

  double lastUpdate;
}

- (AdefyAnimationManager *)init:(AdefyRenderer *)renderer {
  self = [super init];

  mRenderer = renderer;

  // Set us up to be updated on each render
  mDisplayLink = [CADisplayLink displayLinkWithTarget:self
                                             selector:@selector(update)];
  [mDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

  return self;
}

- (void) addAnimation:(AdefyAnimation*)animation {
  [mAnimations addObject:animation];
}

// Update each individual animation
- (void) update {
  double currentTime = [mDisplayLink timestamp];

  for(AdefyAnimation *animation in mAnimations) {
    [animation update:currentTime];
  }
}

@end