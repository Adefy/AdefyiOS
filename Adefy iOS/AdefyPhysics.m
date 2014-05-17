#import "AdefyPhysics.h"
#import "chipmunk.h"
#import "ChipmunkObject.h"
#import "ChipmunkShape.h"
#import "ChipmunkSpace.h"
#import "ChipmunkBody.h"
#import "ChipmunkExtras.h"

static AdefyPhysics *GLOBAL_INSTANCE;

@implementation AdefyPhysics {

@protected
  ChipmunkSpace *mSpace;

  dispatch_queue_t mPhysicsQueue;
  dispatch_source_t mUpdateTimer;

  float mDt;
  BOOL mRunning;
}

- (AdefyPhysics *)init {
  self = [super init];

  mSpace = [[ChipmunkSpace alloc] init];
  mSpace.gravity = cpv(0.0f, -4.4f);

  mRunning = NO;
  mDt = 1.0f / 120.0f; // 120 FPS

  // Setup queue and timer source
  mUpdateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, mPhysicsQueue);
  mPhysicsQueue = dispatch_queue_create("com.sit.adefy.physicsqueue", nil);

  [self startUpdateLoop];

  return self;
}

+ (void)setGlobalInstance:(AdefyPhysics *)instance {
  GLOBAL_INSTANCE = instance;
}

+ (AdefyPhysics *)getGlobalInstance {
  return GLOBAL_INSTANCE;
}

- (void) startUpdateLoop {

  if(mRunning) {
    return;
  }

  // Setup timer
  dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 0);
  uint64_t intervalTime = (uint64_t)(mDt * NSEC_PER_SEC);
  dispatch_source_set_timer(mUpdateTimer, startTime, intervalTime, 0);

  // Register block
  dispatch_source_set_event_handler(mUpdateTimer, ^{
    dispatch_async(mPhysicsQueue, ^{
      [mSpace step:mDt];
    });
  });

  // GOGO!
  dispatch_resume(mUpdateTimer);
  mRunning = YES;
}

- (void) stopUpdateLoop {
  if(!mRunning) {
    return;
  }

  dispatch_suspend(mUpdateTimer);
  mRunning = NO;
}

- (ChipmunkBody *)getStaticBody {
  return mSpace.staticBody;
}

- (void)registerShape:(ChipmunkShape *)shape {
  dispatch_async(mPhysicsQueue, ^{
    [mSpace addShape:shape];
  });
}

- (void)registerBody:(ChipmunkBody *)body {
  dispatch_async(mPhysicsQueue, ^{
    [mSpace addBody:body];
  });
}

- (void)removeShape:(ChipmunkShape *)shape {
  dispatch_async(mPhysicsQueue, ^{
    [mSpace removeShape:shape];
  });
}

- (void)removeBody:(ChipmunkBody *)body {
  dispatch_async(mPhysicsQueue, ^{
    [mSpace removeBody:body];
  });
}

@end