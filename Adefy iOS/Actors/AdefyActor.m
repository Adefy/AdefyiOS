#import <GLKit/GLKit.h>
#import "AdefyActor.h"
#import "AdefyRenderer.h"
#import "AdefyMaterial.h"
#import "AdefySingleColorMaterial.h"
#import "ChipmunkObject.h"
#import "ChipmunkBody.h"
#import "ChipmunkShape.h"
#import "AdefyPhysics.h"
#import "AdefyColor3.h"
#import "AdefyTexturedMaterial.h"
#import "AdefyTexture.h"

// Private methods
@interface AdefyActor ()

- (void) addToRenderer:(AdefyRenderer *)renderer;
- (void) setupRenderMatrix;

@end

@implementation AdefyActor {

@protected
  int mId;
  BOOL mVisible;

  GLuint mPosVertexCount;
  GLuint mPosVertexBuffer;
  GLfloat *mPosVertexArray;

  GLuint mTexVertexCount;
  GLuint mTexVertexBuffer;
  GLfloat *mTexVertexArray;

  GLenum mRenderMode;

  float mRotation;    // Stored in radians
  cpVect mPosition;

  ChipmunkBody *mPhysicsBody;
  ChipmunkShape *mPhysicsShape;

  GLKMatrix4 mModelViewMatrix;

  AdefyRenderer *mRenderer;
  AdefyPhysics *mPhysics;

  AdefyMaterial *mActiveMaterial;
  AdefySingleColorMaterial *mColorMaterial;
  AdefyTexturedMaterial *mTextureMaterial;
}

- (AdefyActor *)init:(int)id
           vertices:(GLfloat *)vertices
          vertCount:(unsigned int)vCount
    texCoords:(GLfloat *)texCoords
           texCount:(unsigned int)tCount {

  self = [super init];

  mId = id;
  mRenderer = [AdefyRenderer getGlobalInstance];
  mPhysics = [AdefyPhysics getGlobalInstance];
  mRotation = 0.0f;
  mPosition = cpv(0.0f, 0.0f);

  mTextureMaterial = [[AdefyTexturedMaterial alloc] init];
  mColorMaterial = [[AdefySingleColorMaterial alloc] init];

  // Default is single color material
  mActiveMaterial = mColorMaterial;

  mPosVertexBuffer = 0;
  mPosVertexArray = nil;

  mTexVertexBuffer = 0;
  mTexVertexArray = nil;

  mVisible = YES;
  mRenderMode = GL_TRIANGLE_FAN;
  mPhysicsBody = nil;
  mPhysicsShape = nil;

  [self setVertices:vertices count:vCount];
  [self setTexCoords:texCoords count:tCount];

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

- (AdefyColor3 *)getColor {
  return [mColorMaterial getColor];
}

- (GLfloat *)getVertices { return mPosVertexArray; }
- (GLfloat *)getTexCoords { return mTexVertexArray; }
- (GLuint)getTexCoordCount { return mTexVertexCount; }
- (GLuint)getVertexCount { return mPosVertexCount; }

- (void) setVertices:(GLfloat *)vertices
              count:(unsigned int)count {

  mPosVertexCount = count;
  mPosVertexArray = vertices;

  // Add a Z coord to the vertices
  GLfloat *resizedVertices = malloc(sizeof(GLfloat) * count * 3);

  for(unsigned int i = 0; i < count; i++) {
    resizedVertices[(i * 3)] = vertices[(i * 2)];
    resizedVertices[(i * 3) + 1] = vertices[(i * 2) + 1];
    resizedVertices[(i * 3) + 2] = 1.0f;
  }

  glDeleteBuffers(1, &mPosVertexBuffer);

  [AdefyRenderer createVertexBuffer:&mPosVertexBuffer
                           vertices:resizedVertices
                              count:count
                         components:3
                             useage:GL_STATIC_DRAW];

  free(resizedVertices);
}

- (void) setTexCoords:(GLfloat *)coords
                count:(unsigned int)count {

  mTexVertexCount = count;
  mTexVertexArray = coords;

  glDeleteBuffers(1, &mTexVertexBuffer);

  [AdefyRenderer createVertexBuffer:&mTexVertexBuffer
                           vertices:coords
                              count:count
                         components:2
                             useage:GL_STATIC_DRAW];
}

- (void) setTexture:(NSString *)name {

  AdefyTexture* texture = [mRenderer getTexture:name];

  if(!texture) {
    NSLog(@"Texture %@ not found", name);
    return;
  }

  GLuint handle = [texture getHandle];
  float scaleU = [texture getClipScaleU];
  float scaleV = [texture getClipScaleV];

  [mTextureMaterial setTextureHandle:handle];
  [mTextureMaterial setUScale:scaleU];
  [mTextureMaterial setVScale:scaleV];

  mActiveMaterial = mTextureMaterial;
}

- (void) setVisible:(BOOL)isVisible {
  mVisible = isVisible;
}

- (void)setPosition:(cpVect)position {
  mPosition = position;
}

- (void)setPosition:(float)x y:(float)y {
  mPosition = cpv(x, y);
}

- (void)setRenderMode:(GLenum)mode {
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
  [mColorMaterial setColor:color];
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

  if(mActiveMaterial == mColorMaterial) {

    [mColorMaterial draw:projection
               modelView:mModelViewMatrix
                   verts:&mPosVertexBuffer
               vertCount:mPosVertexCount
                    mode:mRenderMode];

  } else if(mActiveMaterial == mTextureMaterial) {

    [mTextureMaterial draw:projection
                withModelV:mModelViewMatrix
                 withVerts:&mPosVertexBuffer
             withVertCount:mPosVertexCount
             withTexCoords:&mTexVertexBuffer
             withTexCCount:mTexVertexCount
                  withMode:mRenderMode];

  }
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

- (cpVect *) generatePhysicsVerts:(GLfloat *)verts
                            count:(unsigned int)count {

  cpVect *physicsVerts = malloc(sizeof(cpVect) * count);

  for(unsigned int i = 0; i < count; i++) {
    physicsVerts[i] = cpv(verts[i * 2], verts[(i * 2) + 1]);
    physicsVerts[i] = [AdefyRenderer screenToWorld:physicsVerts[i]];
  }

  return physicsVerts;
}

- (void)createPhysicsBody:(float)mass
                 friction:(float)friction
               elasticity:(float)elasticity {

  if([self hasPhysicsBody])  {
    [self destroyPhysicsBody];
  }

  // Create physics vertices
  cpVect* physicsVerts = [self generatePhysicsVerts:mPosVertexArray
                                              count:mPosVertexCount];

  if(mass == 0.0f) {

    // Static body
    mPhysicsBody = nil;
    mPhysicsShape = [ChipmunkPolyShape polyWithBody:[mPhysics getStaticBody]
                                              count:mPosVertexCount
                                              verts:physicsVerts
                                             offset:[AdefyRenderer screenToWorld:mPosition]];

  } else {

    unsigned int _psyx_count = mPosVertexCount;

    if(mPosVertexCount == 33) {
      _psyx_count = 32;
    }

    // Dynamic body
    float moment = cpMomentForPoly(mass, _psyx_count, physicsVerts, cpv(0, 0));
    mPhysicsBody = [ChipmunkBody bodyWithMass:mass andMoment:moment];

    [mPhysicsBody setPos:[AdefyRenderer screenToWorld:mPosition]];
    [mPhysicsBody setAngle:mRotation];

    mPhysicsShape = [ChipmunkPolyShape polyWithBody:mPhysicsBody
                                              count:_psyx_count
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
  return [mActiveMaterial getName];
}

- (AdefyMaterial *)getMaterial {
  return mActiveMaterial;
}

@end
