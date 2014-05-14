#import "AdefyJSAnimationInterface.h"
#import "AdefyRenderer.h"
#import "AdefyVertAnimation.h"
#import "AdefyBezAnimation.h"
#import "AdefyAnimationManager.h"

@implementation AdefyJSAnimationInterface {

@protected
  AdefyRenderer *mRenderer;
  AdefyAnimationManager *mManager;
}
- (AdefyJSAnimationInterface *)init:(AdefyRenderer *)renderer
               withAnimationManager:(AdefyAnimationManager *)manager {
  self = [super init];

  mRenderer = renderer;
  mManager = manager;

  return self;
}

// Implemented
- (BOOL)canAnimate:(NSString *)property {

  NSArray *propArray = [[NSArray alloc] initWithObjects:property, nil];

  BOOL vertCanAnimate = [AdefyVertAnimation canAnimate:propArray];
  BOOL bezCanAnimate = [AdefyBezAnimation canAnimate:propArray];

  return vertCanAnimate || bezCanAnimate;
}

// Implemented
- (NSString *)getAnimationName:(NSString *)property {

  NSArray *propArray = [[NSArray alloc] initWithObjects:property, nil];

  BOOL vertCanAnimate = [AdefyVertAnimation canAnimate:propArray];
  BOOL bezCanAnimate = [AdefyBezAnimation canAnimate:propArray];

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

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return; }

  NSData *propertiesData = [properties dataUsingEncoding:NSUTF8StringEncoding];
  NSData *optionsData = [options dataUsingEncoding:NSUTF8StringEncoding];

  NSError *error;
  NSArray *propArray = [NSJSONSerialization JSONObjectWithData:propertiesData
                                                       options:0
                                                         error:&error];

  if(error) {
    NSLog(@"Error parsing anim properties: %@", [error localizedDescription]);
    return;
  }

  NSDictionary *optionsDict = [NSJSONSerialization JSONObjectWithData:optionsData
                                                              options:0
                                                                error:&error];

  if([AdefyBezAnimation canAnimate:propArray]) {

    double start = [[optionsDict valueForKey:@"start"] doubleValue];
    double duration = [[optionsDict valueForKey:@"duration"] doubleValue];

    double endVal = [[optionsDict valueForKey:@"endVal"] doubleValue];
    int fps = [[optionsDict valueForKey:@"fps"] intValue];

    NSString *property = [propArray objectAtIndex:0];
    NSString *component = nil;

    if([propArray count] == 2) {
      component = [propArray objectAtIndex:1];
    }

    cpVect *cp1 = nil;
    cpVect *cp2 = nil;

    NSArray *controlPoints = [optionsDict valueForKey:@"controlPoints"];
    if([controlPoints count] > 0) {

      NSDictionary *cp1Raw = [controlPoints objectAtIndex:0];

      cp1 = malloc(sizeof(cpVect));
      *cp1 = cpv(
          [[cp1Raw valueForKey:@"x"] floatValue],
          [[cp1Raw valueForKey:@"y"] floatValue]
      );

      if([controlPoints count] == 2) {

        NSDictionary *cp2Raw = [controlPoints objectAtIndex:0];

        cp2 = malloc(sizeof(cpVect));
        *cp2 = cpv(
            [[cp2Raw valueForKey:@"x"] floatValue],
            [[cp2Raw valueForKey:@"y"] floatValue]
        );
      }
    }

    int64_t delta = (int)start * NSEC_PER_MSEC;
    dispatch_time_t trueStartTime = dispatch_time(DISPATCH_TIME_NOW, delta);

    dispatch_after(trueStartTime, dispatch_get_main_queue(), ^(void) {

      AdefyBezAnimation *animation = [[AdefyBezAnimation alloc] init:actor
                                                            endValue:endVal
                                                                 cp1:cp1
                                                                 cp2:cp2
                                                            duration:duration
                                                            property:property
                                                           component:component
                                                                 fps:fps
                                                         withManager:mManager ];

      [mManager addAnimation:animation];
    });

  } else if([AdefyVertAnimation canAnimate:propArray]) {
    NSLog(@"Get vert animation");
  } else {
    NSLog(@"No animation supports the properties %@", properties);
    NSLog(@"    - Options: %@", optionsDict);
  }
}

@end