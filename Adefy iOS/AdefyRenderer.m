#import "AdefyRenderer.h"
#import "AdefyActor.h"
#import "AdefyMaterial.h"

AdefyRenderer *GLOBAL_INSTANCE;

@interface  AdefyRenderer ()

-(GLKMatrix4) generateProjection:(CGRect)rect;

@end

@implementation AdefyRenderer {
  cpVect mCameraPosition;
  NSMutableString *mActiveMaterial;
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

  GLfloat clearColor[] = { 0.0f, 0.0f, 0.0f, 1.0f };
  [self setClearColor:clearColor];

  glViewport(0, 0, width, height);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);

  NSLog(@"Initialized renderer %ix%i", width, height);

  return self;
}

+ (float) getPPM { return PPM; }
+ (float) getMPP { return 1.0f / PPM; }

+ (cpVect)worldToScreen:(cpVect)v {
  return cpv(v.x * PPM, v.y * PPM);
}

+ (cpVect)screenToWorld:(cpVect)v {
  return cpv(v.x / PPM, v.y / PPM);
}


- (void) addActor:(AdefyActor *)actor {
  [mActors addObject:actor];
}

- (AdefyActor *) getActor:(unsigned int)index {
  return [mActors objectAtIndex:index];
}

- (cpVect) getCameraPosition {
  return mCameraPosition;
}

- (void) setClearColor:(GLfloat [4])color {
  glClearColor(color[0], color[1], color[2], color[3]);
}

+ (void)setGlobalInstance:(AdefyRenderer *)renderer {
  GLOBAL_INSTANCE = renderer;
}

+ (AdefyRenderer *)getGlobalInstance {
  return GLOBAL_INSTANCE;
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

- (void)update {
  for(AdefyActor *actor in mActors) {
    [actor update];
  }
}

- (void) drawFrame:(CGRect)rect {

  GLKMatrix4 projection = [self generateProjection:rect];

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
