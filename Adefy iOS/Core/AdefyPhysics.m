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

#if MULTI_THREADED_PHYSICS
  dispatch_queue_t mPhysicsQueue;
  dispatch_source_t mUpdateTimer;

  float mDt;
  BOOL mRunning;
#endif
}

- (AdefyPhysics *)init {
  self = [super init];

  mSpace = [[ChipmunkSpace alloc] init];
  mSpace.gravity = cpv(0.0f, -4.4f);

#if MULTI_THREADED_PHYSICS
  mRunning = NO;
  mDt = 1.0f / 120.0f; // 120 FPS

  // Setup queue and timer source
  mUpdateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, mPhysicsQueue);
  mPhysicsQueue = dispatch_queue_create("com.sit.adefy.physicsqueue", nil);

  [self startUpdateLoop];
#endif

  return self;
}

+ (void)setGlobalInstance:(AdefyPhysics *)instance {
  GLOBAL_INSTANCE = instance;
}

+ (AdefyPhysics *)getGlobalInstance {
  return GLOBAL_INSTANCE;
}

#if MULTI_THREADED_PHYSICS
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
#endif

- (ChipmunkBody *)getStaticBody {
  return mSpace.staticBody;
}

- (void)registerShape:(ChipmunkShape *)shape {
#if MULTI_THREADED_PHYSICS
  dispatch_async(mPhysicsQueue, ^{
#endif

    [mSpace addShape:shape];

#if MULTI_THREADED_PHYSICS
  });
#endif
}

- (void)registerBody:(ChipmunkBody *)body {
#if MULTI_THREADED_PHYSICS
  dispatch_async(mPhysicsQueue, ^{
#endif

    [mSpace addBody:body];

#if MULTI_THREADED_PHYSICS
  });
#endif
}

- (void)removeShape:(ChipmunkShape *)shape {
#if MULTI_THREADED_PHYSICS
  dispatch_async(mPhysicsQueue, ^{
#endif

    [mSpace removeShape:shape];

#if MULTI_THREADED_PHYSICS
  });
#endif
}

- (void)removeBody:(ChipmunkBody *)body {
#if MULTI_THREADED_PHYSICS
  dispatch_async(mPhysicsQueue, ^{
#endif

    [mSpace removeBody:body];

#if MULTI_THREADED_PHYSICS
  });
#endif
}

#if !MULTI_THREADED_PHYSICS
- (void)update:(float)dt {
  [mSpace step:dt];
}
#endif

@end