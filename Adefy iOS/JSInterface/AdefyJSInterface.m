#import "AdefyJSInterface.h"
#import "AdefyJSActorInterface.h"
#import "AdefyJSAnimationInterface.h"
#import "AdefyJSEngineInterface.h"
#import "AdefyRenderer.h"

@implementation AdefyJSInterface {

@protected
  AdefyJSActorInterface *actorInterface;
  AdefyJSAnimationInterface *animationInterface;
  AdefyJSEngineInterface *engineInterface;
}

- (AdefyJSInterface *)init:(JSContext *)context
              withRenderer:(AdefyRenderer *)renderer{

  self = [super init];

  // Black magic
  actorInterface = [[AdefyJSActorInterface alloc] init:renderer];
  animationInterface = [[AdefyJSAnimationInterface alloc] init];
  engineInterface = [[AdefyJSEngineInterface alloc] init];

  context[@"__iface_actors"] = actorInterface;
  context[@"__iface_animations"] = animationInterface;
  context[@"__iface_engine"] = engineInterface;

  return self;
}

@end