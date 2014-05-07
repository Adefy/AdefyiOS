#import "AdefyJSAnimationInterface.h"
#import "AdefyJSActorInterface.h"
#import "AdefyRenderer.h"

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
  return NO;
}

- (NSString *)getAnimationName:(NSString *)property {
  return nil;
}

- (NSString *)preCalculateBez:(NSString *)options {
  return nil;
}

- (void)animate:(int)id1 properties:(NSString *)properties options:(NSString *)options {

}

@end