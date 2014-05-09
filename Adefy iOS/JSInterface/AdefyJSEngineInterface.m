#import "AdefyJSEngineInterface.h"
#import "AdefyRenderer.h"

@implementation AdefyJSEngineInterface {

@protected
  AdefyRenderer *mRenderer;
}
- (AdefyJSEngineInterface *)init:(AdefyRenderer *)renderer {
  self = [super init];

  mRenderer = renderer;

  return self;
}

- (void)initialize:(NSString *)ad
             width:(int)width
            height:(int)height
          logLevel:(int)logLevel
                id:(NSString *)id {

}

- (NSString *)getClearColor {

  GLfloat *clearColor = [mRenderer getClearColor];

  int r = (int)(clearColor[0] * 255.0f);
  int g = (int)(clearColor[1] * 255.0f);
  int b = (int)(clearColor[2] * 255.0f);

  return [[NSString alloc] initWithFormat:@"{ r: %i, g: %i, b: %i }", r, g, b];
}

- (void)setClearColor:(float)r g:(float)g b:(float)b {

  GLfloat *clearColor = malloc(4 * sizeof(GLfloat));

  clearColor[0] = r / 255.0f;
  clearColor[1] = g / 255.0f;
  clearColor[2] = b / 255.0f;
  clearColor[3] = 1.0f;

  [mRenderer setClearColor:clearColor];
}

- (void)setRemindMeButton:(float)x y:(float)y width:(float)width height:(float)height {
 // Not sure if we even need this anymore, GLAd format is undergoing strategy changes...
}

- (void)setLogLevel:(int)level {
  // Doesn't do anything on iOS
}

- (NSString *)getCameraPosition {
  cpVect pos = [mRenderer getCameraPosition];

  return [[NSString alloc] initWithFormat:@"{ x: %f, y: %f }", pos.x, pos.y];
}

- (void)setCameraPosition:(float)x y:(float)y {
  cpVect pos = cpv(x, y);

  [mRenderer setCameraPosition:pos];
}

- (void)triggerEnd {
  // HAH. No idea what to do on iOS here.
}

- (void)setOrientation:(NSString *)orientation {
  // Also not sure.
}

- (void)log:(NSString *)string {
  NSLog(@"<Console Log> %@", string);
}


@end