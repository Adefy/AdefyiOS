#import "AdefyJSInterface.h"
#import "AdefyJSActorInterface.h"
#import "AdefyJSAnimationInterface.h"
#import "AdefyJSEngineInterface.h"
#import "AdefyRenderer.h"
#import "AdefyAnimationManager.h"

@implementation AdefyJSInterface {

@protected
  AdefyJSActorInterface *actorInterface;
  AdefyJSAnimationInterface *animationInterface;
  AdefyJSEngineInterface *engineInterface;
}

- (AdefyJSInterface *)init:(JSContext *)context
              withRenderer:(AdefyRenderer *)renderer
      withAnimationManager:(AdefyAnimationManager *)manager {

  self = [super init];

  // Exception handler
  [context setExceptionHandler:^(JSContext *ctx, JSValue *value) {
    NSLog(@"JS Exception: %@", value);
  }];

  // Black magic
  actorInterface = [[AdefyJSActorInterface alloc] init:renderer];
  animationInterface = [[AdefyJSAnimationInterface alloc] init:renderer
                                          withAnimationManager:manager];
  engineInterface = [[AdefyJSEngineInterface alloc] init:renderer];

  context[@"__iface_actors"] = actorInterface;
  context[@"__iface_animations"] = animationInterface;
  context[@"__iface_engine"] = engineInterface;

  // Logging
  [context evaluateScript:
      @"var console = { "
        "log: function(message) {"
          "__iface_engine.log(message);"
         "}"
       "}"];

  // Set up AJS-visible interface
  [context evaluateScript:
      @"var window = { AdefyGLI: {} };"
      "window.AdefyGLI.Engine = function(){ return __iface_engine; };"
      "window.AdefyGLI.Actors = function(){ return __iface_actors; };"
      "window.AdefyGLI.Animations = function(){ return __iface_animations; };"
  ];

  // Set up timeouts and intervals, since JavascriptCore doesn't support them
  [context evaluateScript:

      // Structure that stores our time function descriptors
      @"var __iface_time_fns = {};"

      // setTimeout() saves a timeout descriptor after registering with our engine
      "var setTimeout = function(cb, ms) {"
          "var id = __iface_get_time_fn_id();"

          "__iface_time_fns[id] = {"
              "type: \"timeout\","
              "cb: cb,"
              "ms: ms"
          "};"

          "__iface_schedule_time_fn(id, ms);"

          "return id;"
      "};"

      // setInterval() saves an interval descriptor after registering with our engine
      "var setInterval = function(cb, ms) {"
         "var id = __iface_get_time_fn_id();"

         "__iface_time_fns[id] = {"
              "type: \"interval\","
             "cb: cb,"
             "ms: ms"
         "};"

          "__iface_schedule_time_fn(id, ms);"

         "return id;"
      "};"

      // clearInterval() looks up the descriptor by ID, and deletes it if of type "interval"
      "var clearInterval = function(id) {"
          "if(__iface_time_fns[id] && __iface_time_fns[id].type == \"interval\") {"
              "delete __iface_time_fns[id];"
              "return true;"
          "} else {"
              "return false;"
          "}"
      "};"

      // The engine uses __iface_run_time_fn() to execute a time function by id
      "var __iface_run_time_fn = function(id) {"
          "var __fn = __iface_time_fns[id];"

          "if(__fn) {"

              // Timeouts run once, and are deleted right afterwards
              "if(__fn.type == \"timeout\") {"

                  "__fn.cb();"
                  "delete __iface_time_fns[id];"

              // Intervals run, and are immediately re-registered for execution
              "} else if(__fn.type == \"interval\") {"

                  "__fn.cb();"
                  "__iface_schedule_time_fn(id, __fn.ms);"

              "} else {"
                  "console.log(\"Unknown time function type: \" + __fn.type);"
                  "return false;"
              "}"

              "return true;"

          "} else {"
              "return false;"
          "}"
      "};"
  ];

  JSValue *__iface_run_time_fn = context[@"__iface_run_time_fn"];

  context[@"__iface_get_time_fn_id"] = ^() {
    return [self getRandomString:16];
  };

  context[@"__iface_schedule_time_fn"] = ^(NSString *id, int ms) {

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, ms * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
      [__iface_run_time_fn callWithArguments:@[id]];
    });
  };

  return self;
}

static const char* RANDOM_STRING_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\0";

- (NSString *) getRandomString:(unsigned int)length {

  unsigned int alphabetLength = strlen(RANDOM_STRING_ALPHABET);
  NSMutableString *random = [NSMutableString stringWithCapacity:length];

  for(unsigned int i = 0; i < length; i++) {
    [random appendFormat:@"%c", RANDOM_STRING_ALPHABET[rand() % alphabetLength]];
  }

  return random;
}

@end