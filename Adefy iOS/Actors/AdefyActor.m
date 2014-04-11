#import <GLKit/GLKit.h>
#import "AdefyActor.h"
#import "AdefyRenderer.h"
#import "AdefyMaterial.h"
#import "AdefySingleColorMaterial.h"

// Private methods
@interface AdefyActor ()

- (void) addToRenderer:(AdefyRenderer *)renderer;
- (void) setupRenderMatrix;

@end

@implementation AdefyActor {

  // Instance vars
  @private
  int mId;
  BOOL mVisible;

  int mPosVertexCount;
  GLuint mPosVertexBuffer;
  GLuint mPosVertexArray;

  GLuint mRenderMode;

  float mRotation;    // Stored in radians
  cpVect mPosition;

  GLKMatrix4 mModelViewMatrix;

  AdefyRenderer *mRenderer;
  AdefyMaterial *mMaterial;
}

- (AdefyActor *)init:(int)id
           renderer:(AdefyRenderer *)renderer
           vertices:(GLfloat *)vertices
              count:(int)count {

  self = [super init];

  mId = id;
  mRenderer = renderer;
  mRotation = 0.0f;
  mPosition = cpv(100.0f, 100.0f);
  mMaterial = [[AdefySingleColorMaterial alloc] init];
  mPosVertexBuffer = 0;
  mPosVertexArray = 0;
  mVisible = YES;
  mRenderMode = GL_TRIANGLE_FAN;

  [self setVertices:vertices count:count];
  [self addToRenderer:mRenderer];

  return self;
}

//
// Getters and setters
//

- (BOOL)   getVisible    { return mVisible; }
- (int)    getId         { return mId; }
- (cpVect) getPosition   { return mPosition;}
- (float)  getRotation   { return mRotation; }
- (GLuint) getRenderMode { return mRenderMode; }

- (void) setVertices:(GLfloat *)vertices
              count:(unsigned int)count {

  mPosVertexCount = count;

  // Add a Z coord to the vertices
  GLfloat *resizedVertices = malloc(sizeof(GLfloat) * count * 3);

  for(unsigned int i = 0; i < count; i++) {
    resizedVertices[(i * 3)] = vertices[(i * 2)];
    resizedVertices[(i * 3) + 1] = vertices[(i * 2) + 1];
    resizedVertices[(i * 3) + 2] = 0.0f;
  }

  glDeleteBuffers(1, &mPosVertexBuffer);

  [AdefyRenderer createVertexBuffer:&mPosVertexBuffer
                           vertices:resizedVertices
                              count:count
                             useage:GL_STATIC_DRAW];

  free(resizedVertices);
}

- (void) setVisible:(BOOL)isVisible {
  mVisible = isVisible;
}

- (void) setPosition:(cpVect)position {
  mPosition = position;
}

- (void)setPosition:(float)x y:(float)y {
  mPosition = cpv(x, y);
}

- (void)setRenderMode:(GLuint)mode {
  mRenderMode = mode;
}

- (void)setRotation:(float)angle {
  mRotation = angle;
}

- (void)setRotation:(float)angle inDegrees:(BOOL)degrees {
  if(degrees) {
    mRotation = angle * 57.2957795f;
  } else {
    mRotation = angle;
  }
}


- (void)setColor:(AdefyColor3 *)color {
  if([mMaterial getName] == [AdefySingleColorMaterial getName]) {
    [(AdefySingleColorMaterial *)mMaterial setColor:color];
  }
}

//
// Fancy stuff
//

- (void) addToRenderer:(AdefyRenderer *)renderer {
  [renderer addActor:self];
}

- (void) draw:(GLKMatrix4)projection {
  if(!mVisible) { return; }

  [self setupRenderMatrix];

  // This all has to be moved into a single color material
  [mMaterial
           draw:projection
      modelView:mModelViewMatrix
          verts:&mPosVertexBuffer
      vertCount:mPosVertexCount
           mode:mRenderMode];
}

- (void) setupRenderMatrix {

  float finalX = mPosition.x - [mRenderer getCameraPosition].x;
  float finalY = mPosition.y - [mRenderer getCameraPosition].y;

  mModelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, finalX, finalY, 0.0f);
  mModelViewMatrix = GLKMatrix4Rotate(mModelViewMatrix, mRotation, 0.0f, 0.0f, 1.0f);
}

- (NSString *)getMaterialName {
  return [mMaterial getName];
}

- (AdefyMaterial *)getMaterial {
  return mMaterial;
}

@end
