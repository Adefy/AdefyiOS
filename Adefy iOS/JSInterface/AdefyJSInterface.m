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

  [context setExceptionHandler:^(JSContext *ctx, JSValue *value) {
    NSLog(@"JS Exception: %@", value);
  }];

  context[@"__iface_actors"] = actorInterface;
  context[@"__iface_animations"] = animationInterface;
  context[@"__iface_engine"] = engineInterface;

  // Set up AJS-visible interface
  [context evaluateScript:
      @"var window = { AdefyGLI: {} };"
      "window.AdefyGLI.Engine = function(){ return __iface_engine; };"
      "window.AdefyGLI.Actors = function(){ return __iface_actors; };"
      "window.AdefyGLI.Animations = function(){ return __iface_animations; };"
  ];

  return self;
}

@end