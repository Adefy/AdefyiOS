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

  // Initialize AJS
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ajs-prod.min"
                                                       ofType:@"js"];

  if (filePath) {
    NSString *AJS = [[NSString alloc] initWithContentsOfFile:filePath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];

    [context evaluateScript:AJS];
    NSLog(@"Loaded AJS");
  } else {
    NSLog(@"Failed to load AJS!");
  }

  [context evaluateScript:@"var actor = __iface_actors.createRectangleActor(200, 20);"];
  [context evaluateScript:@"__iface_actors.setActorColor(0, 153, 204, actor);"];
  [context evaluateScript:@"__iface_actors.setActorPosition(150, 50, actor);"];

  return self;
}

@end