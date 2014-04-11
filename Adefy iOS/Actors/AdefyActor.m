#import <GLKit/GLKit.h>
#import "AdefyActor.h"
#import "AdefyRenderer.h"
#import "AdefyMaterial.h"
#import "AdefySingleColorMaterial.h"
#import "ChipmunkObject.h"
#import "ChipmunkBody.h"
#import "ChipmunkShape.h"
#import "AdefyPhysics.h"

// Private methods
@interface AdefyActor ()

- (void) addToRenderer:(AdefyRenderer *)renderer;
- (void) setupRenderMatrix;

@end

@implementation AdefyActor {

@protected
  int mId;
  BOOL mVisible;

  int mPosVertexCount;
  GLuint mPosVertexBuffer;
  GLfloat *mPosVertexArray;

  GLuint mRenderMode;

  float mRotation;    // Stored in radians
  cpVect mPosition;

  ChipmunkBody *mPhysicsBody;
  ChipmunkShape *mPhysicsShape;

  GLKMatrix4 mModelViewMatrix;

  AdefyRenderer *mRenderer;
  AdefyPhysics *mPhysics;
  AdefyMaterial *mMaterial;
}

- (AdefyActor *)init:(int)id
           vertices:(GLfloat *)vertices
              count:(unsigned int)count {

  self = [super init];

  mId = id;
  mRenderer = [AdefyRenderer getGlobalInstance];
  mPhysics = [AdefyPhysics getGlobalInstance];
  mRotation = 0.0f;
  mPosition = cpv(0.0f, 0.0f);
  mMaterial = [[AdefySingleColorMaterial alloc] init];
  mPosVertexBuffer = 0;
  mPosVertexArray = nil;
  mVisible = YES;
  mRenderMode = GL_TRIANGLE_FAN;
  mPhysicsBody = nil;
  mPhysicsShape = nil;

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
  mPosVertexArray = vertices;

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

- (void) update {
  if(mPhysicsBody != nil) {
    mPosition = [AdefyRenderer worldToScreen:mPhysicsBody.pos];
    mRotation = mPhysicsBody.angle;
  }
}

- (BOOL) hasPhysicsBody {
  return mPhysicsBody != nil;
}

- (void)destroyPhysicsBody {
  if(![self hasPhysicsBody]) { return; }

  if(mPhysicsShape != nil) {
    [mPhysics removeShape:mPhysicsShape];
    mPhysicsShape = nil;
  }

  if(mPhysicsBody != nil) {
    [mPhysics removeBody:mPhysicsBody];
    mPhysicsBody = nil;
  }
}

- (void)createPhysicsBody {
  [self createPhysicsBody:_mMass
                 friction:_mFriction
               elasticity:_mElasticity];
}

- (void)createPhysicsBody:(float)mass
                 friction:(float)friction
               elasticity:(float)elasticity {

  if([self hasPhysicsBody])  {
    [self destroyPhysicsBody];
  }

  // Create physics vertices
  cpVect *physicsVerts = malloc(sizeof(cpVect) * mPosVertexCount);

  for(unsigned int i = 0; i < mPosVertexCount; i++) {
    physicsVerts[i] = cpv(mPosVertexArray[i * 2], mPosVertexArray[(i * 2) + 1]);
  }

  if(mass == 0.0f) {

    // Static body
    mPhysicsBody = nil;
    mPhysicsShape = [ChipmunkPolyShape polyWithBody:[mPhysics getStaticBody]
                                              count:mPosVertexCount
                                              verts:physicsVerts
                                             offset:mPosition];

  } else {

    // Dynamic body
    float moment = cpMomentForPoly(mass, mPosVertexCount, physicsVerts, cpv(0, 0));
    mPhysicsBody = [ChipmunkBody bodyWithMass:mass andMoment:moment];

    [mPhysicsBody setPos:mPosition];
    [mPhysicsBody setAngle:mRotation];

    mPhysicsShape = [ChipmunkPolyShape polyWithBody:mPhysicsBody
                                              count:mPosVertexCount
                                              verts:physicsVerts
                                             offset:cpv(0, 0)];
  }

  [mPhysicsShape setFriction:friction];
  [mPhysicsShape setElasticity:elasticity];

  [mPhysics registerShape:mPhysicsShape];

  if(mPhysicsBody != nil) {
    [mPhysics registerBody:mPhysicsBody];
  }
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
