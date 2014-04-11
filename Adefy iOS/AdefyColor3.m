#import "AdefyColor3.h"

@implementation AdefyColor3 {

  int mR;
  int mG;
  int mB;

  float mRFloat;
  float mGFloat;
  float mBFloat;
}

- (float *)toFloatArray {

  float *array = (float *)malloc(3 * sizeof(float));

  array[0] = mRFloat;
  array[1] = mGFloat;
  array[2] = mBFloat;

  return array;
}

- (void)copyToFloatArray:(float *)array {
  array[0] = mRFloat;
  array[1] = mRFloat;
  array[2] = mRFloat;
}


- (void)setR:(int)r {
  mR = r;
  mRFloat = (float)r / 255.0f;
}

- (void)setG:(int)g {
  mG = g;
  mGFloat = (float)g / 255.0f;
}

- (void)setB:(int)b {
  mB = b;
  mBFloat = (float)b / 255.0f;
}

-(AdefyColor3 *)init {
  self = [super init];

  mR = 0;
  mG = 0;
  mB = 0;

  return self;
}

-(AdefyColor3 *)init:(int)r withG:(int)g withB:(int)b {
  self = [super init];

  mR = r;
  mG = g;
  mB = b;

  mRFloat = (float)r / 255.0f;
  mGFloat = (float)g / 255.0f;
  mBFloat = (float)b / 255.0f;

  return self;
}

-(AdefyColor3 *)init:(float)r withGF:(float)g withBF:(float)b {
  self = [super init];

  mRFloat = r;
  mGFloat = g;
  mBFloat = b;

  mR = (int)(r * 255.0f);
  mG = (int)(g * 255.0f);
  mB = (int)(b * 255.0f);

  return self;
}

@end
