#import "AdefyPhysics.h"
#import "ChipmunkSpace.h"
#import "chipmunk.h"
#import "ChipmunkObject.h"
#import "ChipmunkShape.h"
#import "ChipmunkBody.h"
#import "ChipmunkExtras.h"

AdefyPhysics *GLOBAL_INSTANCE;

@implementation AdefyPhysics {

@protected
  ChipmunkSpace *space;
}

- (AdefyPhysics *)init {
  self = [super init];

  space = [[ChipmunkSpace alloc] init];
  space.gravity = cpv(0, -10.0f);

  return self;
}

+ (void)setGlobalInstance:(AdefyPhysics *)instance {
  GLOBAL_INSTANCE = instance;
}

+ (AdefyPhysics *)getGlobalInstance {
  return GLOBAL_INSTANCE;
}

- (ChipmunkBody *)getStaticBody {
  return space.staticBody;
}

- (void)registerShape:(ChipmunkShape *)shape {
  [space addShape:shape];
}

- (void)registerBody:(ChipmunkBody *)body {
  [space addBody:body];
}

- (void)removeShape:(ChipmunkShape *)shape {
  [space removeShape:shape];
}

- (void)removeBody:(ChipmunkBody *)body {
  [space removeBody:body];
}

- (void)update:(float)dt {
  [space step:dt];
}

@end