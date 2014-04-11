#import "AdefyRenderer.h"
#import "AdefyActor.h"
#import "AdefyMaterial.h"

@interface  AdefyRenderer ()

-(GLKMatrix4) generateProjection:(CGRect)rect;

@end

@implementation AdefyRenderer {
  cpVect mCameraPosition;
  NSMutableString *mActiveMaterial;

  int mTargetFPS;
  int mTargetFrameTime;

  NSMutableArray* mActors;
}

static float PPM;

+ (void) initialize {
  PPM = 128.0f;
}

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height {

  self = [super init];

  mActors = [[NSMutableArray alloc] init];
  mCameraPosition = cpv(0.0f, 0.0f);
  [mActiveMaterial setString:@""];

  [self setFPS:60];

  glViewport(0, 0, width, height);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);

  return self;
}

+ (float) getPPM { return PPM; }
+ (float) getMPP { return 1.0f / PPM; }

- (void) addActor:(AdefyActor *)actor {
  [mActors addObject:actor];
}

- (AdefyActor *) getActor:(int)index {
  return [mActors objectAtIndex:index];
}

- (cpVect) getCameraPosition {
  return mCameraPosition;
}

- (void) setFPS:(int)fps {
  mTargetFPS = fps;
  mTargetFrameTime = 1000 / fps;
}

+ (void)createVertexBuffer:(GLuint *)buffer
                 vertices:(GLfloat *)vertices
                    count:(int)count
                   useage:(GLenum)useage {

  GLuint __buffer;

  glGenVertexArraysOES(1, buffer);
  glBindVertexArrayOES(*buffer);

  glGenBuffers(1, &__buffer);
  glBindBuffer(GL_ARRAY_BUFFER, __buffer);

  // Vertices doesn't mean components, so multiply by 3
  glBufferData(GL_ARRAY_BUFFER, count * 3 * sizeof(GL_FLOAT), vertices, useage);

  glBindVertexArrayOES(0);
}

- (GLKMatrix4) generateProjection:(CGRect)rect {
  return GLKMatrix4MakeOrtho(0, rect.size.width, 0, rect.size.height, -10, 10);
}

- (void) drawFrame:(CGRect)rect {

  GLKMatrix4 projection = [self generateProjection:rect];

  glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  for(AdefyActor *actor in mActors) {

    // Switch material if needed
    if(mActiveMaterial != [actor getMaterialName]) {
      glUseProgram([[actor getMaterial] getShader]);
      [mActiveMaterial setString:[actor getMaterialName]];
    }

    [actor draw:projection];
  }
}

@end
