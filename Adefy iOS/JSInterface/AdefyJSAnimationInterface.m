#import "AdefyJSAnimationInterface.h"
#import "AdefyJSActorInterface.h"
#import "AdefyRenderer.h"
#import "AdefyVertAnimation.h"
#import "AdefyBezAnimation.h"

@implementation AdefyJSAnimationInterface {

@protected
  AdefyRenderer *mRenderer;
}
- (AdefyJSAnimationInterface *)init:(AdefyRenderer *)renderer {
  self = [super init];

  mRenderer = renderer;

  return self;
}

- (BOOL)canAnimate:(NSString *)property {

  BOOL vertCanAnimate = [AdefyVertAnimation canAnimate:property];
  BOOL bezCanAnimate = [AdefyBezAnimation canAnimate:property];

  return vertCanAnimate || bezCanAnimate;
}

- (NSString *)getAnimationName:(NSString *)property {

  BOOL vertCanAnimate = [AdefyVertAnimation canAnimate:property];
  BOOL bezCanAnimate = [AdefyBezAnimation canAnimate:property];

  if(vertCanAnimate) {
    return @"vert";
  } else if(bezCanAnimate) {
    return @"bezier";
  }

  return @"";
}

- (NSString *)preCalculateBez:(NSString *)options {
  return @"[]";
}

- (void)animate:(int)id
     properties:(NSString *)properties
        options:(NSString *)options {

}

@end