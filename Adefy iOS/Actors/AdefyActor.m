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
#import "AdefyRectangleActor.h"

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

  float mRotation;             // Stored in radians
  float mRenderOffsetRotation; //

  int mLayer;
  cpLayers mPhysicsLayer;
  int mRawPhysicsLayer;

  cpVect mPosition;
  cpVect mRenderOffset;

  ChipmunkBody *mPhysicsBody;
  ChipmunkShape *mPhysicsShape;

  GLKMatrix4 mModelViewMatrix;

  AdefyRenderer *mRenderer;
  AdefyPhysics *mPhysics;

  AdefyMaterial *mActiveMaterial;
  AdefySingleColorMaterial *mColorMaterial;
  AdefyTexturedMaterial *mTextureMaterial;
  NSString* mTextureName;

  AdefyActor* mAttachment;
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
  mRenderOffset = cpv(0.0f, 0.0f);

  mLayer = 0;
  mPhysicsLayer = ~0;
  mRawPhysicsLayer = 0;

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
  mAttachment = nil;

  [self setVertices:vertices count:vCount];
  [self setTexCoords:texCoords count:tCount];

  [self addToRenderer:mRenderer];

  return self;
}

//
// Getters and setters
//

- (int)    getLayer      { return mLayer; }
- (int)    getPhysicsLayer { return mRawPhysicsLayer; }
- (BOOL)   getVisible    { return mVisible; }
- (int)    getId         { return mId; }
- (cpVect) getPosition   { return mPosition;}
- (float)  getRotation   { return mRotation; }
- (float)  getRenderOffsetRotation { return mRenderOffsetRotation; }
- (GLuint) getRenderMode { return mRenderMode; }
- (BOOL)   hasAttachment { return mAttachment == nil; }

- (AdefyActor *)  getAttachment { return mAttachment; }
- (AdefyColor3 *) getColor { return [mColorMaterial getColor]; }

- (GLfloat *) getVertices { return mPosVertexArray; }
- (GLfloat *) getTexCoords { return mTexVertexArray; }
- (GLuint) getTexCoordCount { return mTexVertexCount; }
- (GLuint) getVertexCount { return mPosVertexCount; }
- (cpVect) getRenderOffset { return mRenderOffset; }
- (NSString *) getTextureName { return mTextureName; }

- (void) setLayer:(int)layer {
  mLayer = layer;

  if(mAttachment) {
    [mAttachment setLayer:mLayer];
  }

  [mRenderer resortActorsByLayer];
}

- (void) setPhysicsLayer:(unsigned int)layer {
  if(layer < 0) {
    NSLog(@"Warning, physics layer must be >0 [got %i]", layer);
    layer = 0;
  } else if(layer > 16) {
    NSLog(@"Warning, physics layer must be <16 [got %i]", layer);
    layer = 15;
  }

  mPhysicsLayer = 1 << layer;
  mRawPhysicsLayer = layer;

  if(mPhysicsShape) {
    [mPhysicsShape setLayers:mPhysicsLayer];
  }
}

- (void) setRenderOffset:(cpVect)offset {
  mRenderOffset.x = offset.x;
  mRenderOffset.y = offset.y;
}

- (void) setRenderOffsetRotation:(float)angle {
  mRenderOffsetRotation = angle;
}

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
  mTextureName = name;

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

  if(mPhysicsShape) {

    // Dynamic has a body
    if(mPhysicsBody) {
      [mPhysicsBody setPos:[AdefyRenderer screenToWorld:mPosition]];
    } else {

      // Static bodies can't be rotated, they must be recreated
      [self destroyPhysicsBody];
      [self createPhysicsBody];
    }
  }
}

- (void)setPosition:(float)x y:(float)y {
  [self setPosition:cpv(x, y)];
}

- (void)setRenderMode:(GLenum)mode {
  mRenderMode = mode;
}

// Assumes radians!
- (void)setRotation:(float)angle {
  [self setRotation:angle inDegrees:NO];
}

- (void)setRotation:(float)angle inDegrees:(BOOL)degrees {
  if(degrees) {
    mRotation = angle / 57.2957795f;
  } else {
    mRotation = angle;
  }

  if(mPhysicsShape) {

    // Dynamic has a body
    if(mPhysicsBody) {
      [mPhysicsBody setAngle:mRotation];
    } else {

      // Static bodies can't be rotated, they must be recreated
      [self destroyPhysicsBody];
      [self createPhysicsBody];
    }
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

- (BOOL) removeAttachment {
  if(mAttachment == nil) { return NO; }

  [mAttachment destroyPhysicsBody];
  [mRenderer removeActor:mAttachment];

  mAttachment = nil;
  return YES;
}

- (void) setAttachmentVisiblity:(BOOL)visible {
  if(mAttachment != nil) {
    [mAttachment setVisible:visible];
  }
}

- (AdefyActor *) attachTexture:(NSString *)name
                         width:(float)w
                        height:(float)h
                       offsetX:(float)offx
                       offsetY:(float)offy
                         angle:(float)angle {

  if(mAttachment) {
    [self removeAttachment];
  }

  int attachmentId = [AdefyRenderer getNextActorID];

  mAttachment = [[AdefyRectangleActor alloc] init:attachmentId
                                            width:w
                                           height:h];

  [mAttachment setTexture:name];
  [mAttachment setRenderOffsetRotation:angle];
  [mAttachment setRenderOffset:cpv(offx, offy)];
  [mAttachment setLayer:mLayer];

  return mAttachment;
}

- (void) draw:(GLKMatrix4)projection {
  if(!mVisible) { return; }

  // If we have an attachment, render that and return prematurely
  if(mAttachment != nil) {

    [mAttachment setPosition:mPosition];
    [mAttachment setRotation:mRotation];

    [mAttachment draw:projection];
    return;
  }

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
  return mPhysicsBody != nil || mPhysicsShape != nil;
}

- (void)destroyPhysicsBody {
  if(![self hasPhysicsBody]) { return; }

  if(mPhysicsShape) {
    [mPhysics removeShape:mPhysicsShape];
    mPhysicsShape = nil;
  }

  if(mPhysicsBody) {
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

    // Static body. We can't rotate static bodies, so rotate the physics verts manually
    for(unsigned int i = 0; i < mPosVertexCount; i++) {

      float x = physicsVerts[i].x;
      float y = physicsVerts[i].y;

      physicsVerts[i].x = (x * (float)cos(mRotation)) - (y * (float)sin(mRotation));
      physicsVerts[i].y = (x * (float)sin(mRotation)) + (y * (float)cos(mRotation));
    }

    mPhysicsBody = nil;
    mPhysicsShape = [ChipmunkPolyShape polyWithBody:[mPhysics getStaticBody]
                                              count:mPosVertexCount
                                              verts:physicsVerts
                                             offset:[AdefyRenderer screenToWorld:mPosition]];

  } else {

    // Dynamic body
    float moment = cpMomentForPoly(mass, mPosVertexCount, physicsVerts, cpv(0, 0));
    mPhysicsBody = [ChipmunkBody bodyWithMass:mass andMoment:moment];

    [mPhysicsBody setPos:[AdefyRenderer screenToWorld:mPosition]];
    [mPhysicsBody setAngle:mRotation];

    mPhysicsShape = [ChipmunkPolyShape polyWithBody:mPhysicsBody
                                              count:mPosVertexCount
                                              verts:physicsVerts
                                             offset:cpv(0, 0)];
  }

  [mPhysicsShape setFriction:friction];
  [mPhysicsShape setElasticity:elasticity];
  [mPhysicsShape setLayers:mPhysicsLayer];

  [mPhysics registerShape:mPhysicsShape];

  if(mPhysicsBody != nil) {
    [mPhysics registerBody:mPhysicsBody];
  }
}

- (void) setupRenderMatrix {

  float finalX = mPosition.x - [mRenderer getCameraPosition].x + mRenderOffset.x;
  float finalY = mPosition.y - [mRenderer getCameraPosition].y + mRenderOffset.y;

  mModelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, finalX, finalY, 0.0f);
  mModelViewMatrix = GLKMatrix4Rotate(mModelViewMatrix, mRotation + mRenderOffsetRotation, 0.0f, 0.0f, 1.0f);
}

- (NSString *)getMaterialName {
  return [mActiveMaterial getName];
}

- (AdefyMaterial *)getMaterial {
  return mActiveMaterial;
}

@end
