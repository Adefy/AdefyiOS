#import "AdefyBezAnimation.h"
#import "AdefyActor.h"
#import "AdefyColor3.h"
#import "AdefyAnimationManager.h"

@implementation AdefyBezAnimation {

@protected
  AdefyActor* mActor;
  AdefyAnimationManager* mManager;

  NSString* mProperty;
  NSString* mPropComponent;

  cpVect* mCp1;
  cpVect* mCp2;

  double mStartTime;
  double mEndVal;
  double mStartVal;
  double mDuration;

  int mFPS;
  BOOL mDone;
}

- (AdefyBezAnimation *)init:(AdefyActor *)_actor
                   endValue:(double)_end
                        cp1:(cpVect *)_cp1
                        cp2:(cpVect *)_cp2
                   duration:(double)_duration
                   property:(NSString *)_prop
                  component:(NSString *)_comp
                        fps:(int)_fps
                withManager:(AdefyAnimationManager *)manager {
  self = [super init];

  mManager = manager;
  mActor = _actor;
  mStartTime = -1;
  mEndVal = _end;
  mCp1 = _cp1;
  mCp2 = _cp2;
  mDuration = _duration;
  mProperty = _prop;
  mPropComponent = _comp;
  mFPS = _fps;
  mDone = NO;

  return self;
}

+ (BOOL) canAnimate:(NSArray *)properties {

  NSString *prop1 = [properties objectAtIndex:0];

  return
      [prop1 isEqualToString:@"position"] ||
      [prop1 isEqualToString:@"color"] ||
      [prop1 isEqualToString:@"rotation"];
}

- (BOOL) isDone { return mDone; }

- (double)update:(double)timeMS { return [self update:timeMS apply:YES]; }
- (double)update:(double)timeMS apply:(BOOL)_apply {

  // Set up start time and value
  if(mStartTime == -1) {
    mStartTime = timeMS;
    [self getStartValue];
  }

  // t represents our position along the bezier func
  double t = (timeMS - mStartTime) / mDuration;
  double value = 0;

  // Cap t
  if(t >= 1.0) {
    t = 1.0;
  }

  // Linear interpolation
  if(!mCp1 && !mCp2) {
    value = mStartVal + ((mEndVal - mStartVal) * t);
  } else if(mCp1 && !mCp2) {

    // 1st order Bezier
    double _Mt = 1 - t;
    double _Mt2 = _Mt * _Mt;
    double _t2 = t * t;

    // [x, y] = [(1 - t)^2]P0 + 2(1 - t)tP1 + (t^2)P2
    value = (_Mt2 * mStartVal) + (2 * _Mt * t * mCp1->y) + _t2 + mEndVal;
  } else {

    // 2nd order Bezier
    double _Mt = 1 - t;
    double _Mt2 = _Mt * _Mt;
    double _Mt3 = _Mt2 * _Mt;
    double _t2 = t * t;
    double _t3 = _t2 * t;

    // [x, y] = [(1 - t)^3]P0 + 3[(1 - t)^2]P1 + 3(1 - t)(t^2)P2 + (t^3)P3
    value = (_Mt3 * mStartVal) + (3 * _Mt2 * t * mCp1->y);
    value += (3 * _Mt * _t2 * mCp2->y) + (_t3 * mEndVal);
  }

  if(_apply) {
    [self applyValue:value];
  }

  // Setting done to YES tells the animation manager to remove us.
  if(t >= 1.0) {
    mDone = YES;
  }

  return value;
}

- (void) getStartValue {

  if([mProperty isEqualToString:@"rotation"]) {
    mStartVal = [mActor getRotation] * 57.2957795f;
  } else if([mProperty isEqualToString:@"position"]) {

    if(!mPropComponent) {
      NSLog(@"Expected component for animation prop 'position");
      return;
    }

    cpVect pos = [mActor getPosition];

    if([mPropComponent isEqualToString:@"x"]) {
      mStartVal = pos.x;
    } else if([mPropComponent isEqualToString:@"y"]) {
      mStartVal = pos.y;
    } else {
      NSLog(@"Component of position needs to be 'x' or 'y'! Got %@", mPropComponent);
      return;
    }

  } else if([mProperty isEqualToString:@"color"]) {

    if(!mPropComponent) {
      NSLog(@"Expected component for animation prop 'color");
      return;
    }

    AdefyColor3 *color = [mActor getColor];

    if([mPropComponent isEqualToString:@"r"]) {
      mStartVal = [color getR];
    } else if([mPropComponent isEqualToString:@"g"]) {
      mStartVal = [color getG];
    } else if([mPropComponent isEqualToString:@"b"]) {
      mStartVal = [color getB];
    } else {
      NSLog(@"Component of color needs to be 'r','g', or 'b'! Got %@", mPropComponent);
      return;
    }
  }

}

- (void) applyValue:(double)value {

  if([mProperty isEqualToString:@"rotation"]) {
    [mActor setRotation:(float)value inDegrees:YES];
  } else if([mProperty isEqualToString:@"position"]) {

    if(!mPropComponent) {
      NSLog(@"Expected component for animation prop 'position");
      return;
    }

    cpVect pos = [mActor getPosition];

    if([mPropComponent isEqualToString:@"x"]) {
      pos.x = (float)value;
    } else if([mPropComponent isEqualToString:@"y"]) {
      pos.y = (float)value;
    } else {
      NSLog(@"Component of position needs to be 'x' or 'y'! Got %@", mPropComponent);
      return;
    }

    [mActor setPosition:pos];

  } else if([mProperty isEqualToString:@"color"]) {

    if(!mPropComponent) {
      NSLog(@"Expected component for animation prop 'color");
      return;
    }

    AdefyColor3 *color = [mActor getColor];

    if([mPropComponent isEqualToString:@"r"]) {
      [color setR:(GLubyte)value];
    } else if([mPropComponent isEqualToString:@"g"]) {
      [color setG:(GLubyte)value];
    } else if([mPropComponent isEqualToString:@"b"]) {
      [color setB:(GLubyte)value];
    } else {
      NSLog(@"Component of color needs to be 'r','g', or 'b'! Got %@", mPropComponent);
      return;
    }

    [mActor setColor:color];
  }
}

- (NSString *) preCalculateJSON { return [self preCalculateJSON:mStartVal]; }
- (NSString *) preCalculateJSON:(double)_start {

  [self getStartValue];

  double oldStart = mStartVal;
  mStartVal = _start;

  int frames = (int)((mDuration / 1000.0) * (double)mFPS);
  float stepTime = (float)(mDuration / (double)frames);

  NSMutableString *ret = [[NSMutableString alloc]
      initWithFormat:@"{ \"stepTime:\" %f, \"values\": [", stepTime];

  for(int i = 0; i < frames; i++) {
    double value = [self update:(mStartTime + (i * stepTime)) apply:NO];

    if(i < frames - 1) {
      [ret appendFormat:@"%f, ", (float)value];
    } else {
      [ret appendFormat:@"%f", (float)value];
    }
  }

  [ret appendString:@"]}"];

  mStartVal = oldStart;
  return ret;
}

@end