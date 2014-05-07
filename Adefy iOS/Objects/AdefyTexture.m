#import "AdefyTexture.h"

@implementation AdefyTexture {

@protected
  NSString *name;
  GLuint handle;

  float clipScaleU;
  float clipScaleV;
}

- (AdefyTexture *) init:(NSString *)_name
             withHandle:(GLuint)_handle
              withClipU:(float)_u
              withClipV:(float)_v {
  self = [super init];

  name = _name;
  handle = _handle;
  clipScaleU = _u;
  clipScaleV = _v;

  return self;
}

- (NSString *) getName { return name; }
- (GLuint) getHandle { return handle; }
- (float) getClipScaleU { return clipScaleU; }
- (float) getClipScaleV { return clipScaleV; }

@end