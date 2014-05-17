#import <GLKit/GLKit.h>
#import "AdefyActor.h"
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

  VertexData2D *mVertexData;
  GLuint mVertexIndiceBuffer;
  GLuint mVertexCount;

  BOOL mUsesIndicesFromActor;
  GLuint *mHostIndiceBuffer;

  GLenum mRenderMode;

  float mRotationRadians;
  float mRenderOffsetRotationRadians;

  int mLayer;
  cpLayers mPhysicsLayer;
  int mRawPhysicsLayer;

  cpVect mPosition;
  cpVect mRenderOffset;

  cpVect *mPhysicsVertices;
  GLuint mPhysicsVertCount;

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

/**
* Default constructor, initialises us and registers ourselves with the renderer.
*/
- (AdefyActor *)init:(int)id
          vertexData:(VertexData2D *)vertexData
         vertexCount:(GLuint)vertexCount {

  return [self init:id
         vertexData:vertexData
        vertexCount:vertexCount
      addToRenderer:YES];
}

/**
* Specialised internal constructor, allowing the caller to prevent our registration with the renderer (for the time
* being).
*/
- (AdefyActor *)init:(int)id
          vertexData:(VertexData2D *)vertexData
         vertexCount:(GLuint)vertexCount
       addToRenderer:(BOOL)addToRenderer {

  self = [super init];

  mId = id;
  mRenderer = [AdefyRenderer getGlobalInstance];
  mPhysics = [AdefyPhysics getGlobalInstance];
  mRotationRadians = 0.0f;
  mPosition = cpv(0.0f, 0.0f);
  mRenderOffset = cpv(0.0f, 0.0f);

  mLayer = 0;
  mPhysicsLayer = (cpLayers)~0;
  mRawPhysicsLayer = 0;

  mTextureMaterial = [[AdefyTexturedMaterial alloc] init];
  mColorMaterial = [[AdefySingleColorMaterial alloc] init];

  // Default is single color material
  mActiveMaterial = mColorMaterial;

  // Setup vertex indice buffer
  glGenBuffers(1, &mVertexIndiceBuffer);
  mUsesIndicesFromActor = NO;
  mHostIndiceBuffer = nil;

  mVertexData = vertexData;
  mVertexCount = vertexCount;

  mVisible = YES;
  mRenderMode = GL_TRIANGLE_FAN;
  mPhysicsBody = nil;
  mPhysicsShape = nil;
  mAttachment = nil;

  // Create physics vertices
  mPhysicsVertCount = mVertexCount;
  mPhysicsVertices = [self generatePhysicsVerts];

  if(addToRenderer)
    [self addToRenderer:mRenderer];

  return self;
}

/**
* Useful helper, note that calls to this are not monitored! This should only be called once!
*/
- (void) addToOwnRenderer {
  [self addToRenderer:mRenderer];
}

/**
* Getters
*/
- (int)             getLayer                { return mLayer; }
- (int)             getPhysicsLayer         { return mRawPhysicsLayer; }
- (BOOL)            getVisible              { return mVisible; }
- (int)             getId                   { return mId; }
- (cpVect)          getPosition             { return mPosition;}
- (float)           getRotation             { return mRotationRadians; }
- (float)           getRenderOffsetRotation { return mRenderOffsetRotationRadians; }
- (GLuint)          getRenderMode           { return mRenderMode; }
- (AdefyActor *)    getAttachment           { return mAttachment; }
- (AdefyColor3 *)   getColor                { return [mColorMaterial getColor]; }
- (VertexData2D *)  getVertexData           { return mVertexData; }
- (GLuint)          getVertexCount          { return mVertexCount; }
- (cpVect)          getRenderOffset         { return mRenderOffset; }
- (NSString *)      getTextureName          { return mTextureName; }
- (NSString *)      getMaterialName         { return [mActiveMaterial getName]; }
- (AdefyMaterial *) getMaterial             { return mActiveMaterial; }
- (GLuint)          getIndiceBuffer         { return mVertexIndiceBuffer; }
- (GLuint *)        getIndiceBufferPointer  { return &mVertexIndiceBuffer; }
- (BOOL)            hasAttachment           { return mAttachment == nil; }
- (BOOL)            hasOwnIndices           { return !mUsesIndicesFromActor; }

/**
* Set a pointer to a "host" actor's indice buffer. This allows us to share vertex data, keeping VBO size down.
*/
- (void) setHostIndiceBuffer:(GLuint *)buffer {
  mHostIndiceBuffer = buffer;
  mUsesIndicesFromActor = YES;
}

/**
* Set layer, also sets attachment layer (if we have one).
*/
- (void) setLayer:(int)layer {
  mLayer = layer;

  if(mAttachment) {
    [mAttachment setLayer:mLayer];
  }
}

/**
* Set actor physics layer, valid values are between 0 and 16. Anything outside of that range gets truncated.
*
* Value is applied to a physics shape if we have one, and persists between physics bodies.
*/
- (void) setPhysicsLayer:(GLubyte)layer {
  if(layer > 16) {
    NSLog(@"Warning, physics layer must be <16 [got %i]", layer);
    layer = 15;
  }

  mPhysicsLayer = (cpLayers)1 << layer;
  mRawPhysicsLayer = layer;

  if(mPhysicsShape) {
    [mPhysicsShape setLayers:mPhysicsLayer];
  }
}

/**
* Set render offset, relative to position. Used by attachments (relative to parent).
*/
- (void) setRenderOffset:(cpVect)offset {
  mRenderOffset.x = offset.x;
  mRenderOffset.y = offset.y;
}

/**
* Set render rotation offset, relative to angle. Used by attachments (relative to parent).
*/
- (void) setRenderOffsetRotation:(float)angle {
  mRenderOffsetRotationRadians = angle;
}

/**
* Set vertex data, triggers a renderer VBO re-generation! This should be used sparingly!
*
* Also frees current vertex data (if we have any)
*/
- (void) setVertexData:(VertexData2D *)vertices
                 count:(GLuint)count {

  // Make sure we use our own indices at this point
  if(mUsesIndicesFromActor) {
    mUsesIndicesFromActor = NO;
    mHostIndiceBuffer = nil;
  }

  if(mVertexData)
    free(mVertexData);

  mVertexCount = count;
  mVertexData = vertices;

  // This is EXPENSIVE!
  [mRenderer regenerateVBO];
}

/**
* Update vertex data with an array of new vertex positions. Expects the supplied vertex count to match our own,
* and triggers a renderer VBO regeneration!
*/
- (void) updateVerticesWith:(Vertex2D *)vertices {

  // Make sure we use our own indices at this point
  if(mUsesIndicesFromActor) {
    mUsesIndicesFromActor = NO;
    mHostIndiceBuffer = nil;
  }

  for(GLuint i = 0; i < mVertexCount; i++) {
    mVertexData[i].vertex.x = vertices[i].x;
    mVertexData[i].vertex.y = vertices[i].y;
  }

  [mRenderer regenerateVBO];
}

/**
* Update vertex data with an array of new texture coordinates. Expects the supplied tex coord count to match our own,
* and triggers a renderer VBO regeneration!
*/
- (void) updateTexCoordsWith:(TextureCoord *)coords {

  // Make sure we use our own indices at this point
  if(mUsesIndicesFromActor) {
    mUsesIndicesFromActor = NO;
    mHostIndiceBuffer = nil;
  }

  for(GLuint i = 0; i < mVertexCount; i++) {
    mVertexData[i].texture.u = coords[i].u;
    mVertexData[i].texture.v = coords[i].v;
  }

  [mRenderer regenerateVBO];
}

/**
* Provides us with a new set of vertex indices. Creates a new GL_ELEMENT_ARRAY_BUFFER for us,
* and deletes any existing one. Should only be called by the renderer.
*
* NOTE: This method frees the supplied indice array!
*/
- (void) setVertexIndices:(GLushort *)indices {

  // Setup indice buffer
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mVertexIndiceBuffer);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) * mVertexCount, indices, GL_STATIC_DRAW);

  // We are in charge of freeing the indices!
  free(indices);
}

/**
* Set texture by name; fails with a log message if the texture is not found.
* Also switches our active material to the texture material!
*/
- (void) setTexture:(NSString *)name {

  AdefyTexture* texture = [mRenderer getTexture:name];
  mTextureName = name;

  if(!texture) {
    NSLog(@"Texture %@ not found", name);
    return;
  }

  [mTextureMaterial setTextureHandle:[texture getHandle]];
  [mTextureMaterial setUScale:[texture getClipScaleU]];
  [mTextureMaterial setVScale:[texture getClipScaleV]];

  mActiveMaterial = mTextureMaterial;
}

/**
* Sets our visiblity; invisible actors return at the start of their render method.
* The renderer still iterates over us!
*/
- (void) setVisible:(BOOL)isVisible {
  mVisible = isVisible;
}

/**
* Set actor position. Also updates our physics body if we have one.
* If we have a static body, it is re-created!
*/
- (void) setPosition:(cpVect)position {
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

/**
* setPosition alias, creates an intermediate cpVect
*/
- (void)setPosition:(float)x
                  y:(float)y {
  [self setPosition:cpv(x, y)];
}

/**
* Set render mode, passed to the render on each draw call.
*/
- (void)setRenderMode:(GLenum)mode {
  mRenderMode = mode;
}

/**
* Set angle of rotation in radians. Alias for setRotation:inDegrees:NO
*/
- (void)setRotation:(float)angle {
  [self setRotation:angle inDegrees:NO];
}

/**
* Set rotation in either radians or degrees. Also updates our physics body if we have one.
* If we have a static body, it is re-created!
*/
- (void)setRotation:(float)angle inDegrees:(BOOL)degrees {
  if(degrees) {
    mRotationRadians = angle / 57.2957795f;
  } else {
    mRotationRadians = angle;
  }

  if(mPhysicsShape) {

    // Dynamic has a body
    if(mPhysicsBody) {
      [mPhysicsBody setAngle:mRotationRadians];
    } else {

      // Static bodies can't be rotated, they must be recreated
      [self destroyPhysicsBody];
      [self createPhysicsBody];
    }
  }
}

/**
* Set our color material's color. The pointer to the object is passed through, it is not copied!
*/
- (void)setColor:(AdefyColor3 *)color {
  [mColorMaterial setColor:color];
}

/**
* Add ourselves to a renderer. This triggers a renderer VBO re-generation!
*/
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

/**
* Create a new attached @AdefyRectangleActor with the specified dimensions. The actor is rendered at the specific
* offset, and is given the specified texture. It becomes our "attachment."
*
* Any existing attachment is removed.
*/
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

/**
* Sexy draw method. Our vertex data is in the renderer's VBO, so we pass our indices to our active material,
* after calculating a new projection.
*
* If we have an attachment, its state is updated to match ours and it is drawn instead.
*/
- (void) draw:(GLKMatrix4)projection {

  // Notice that we don't attempt to draw ourselves if we haven't been assigned indices by the renderer!
  // Renderer VBO re-generation is paced, so if we are in the middle of a rapid succession of actor creations,
  // we won't get our indices untill it finishes.
  if(!mVisible || mVertexIndiceBuffer == 0) { return; }

  // If we have an attachment, render that and return prematurely
  if(mAttachment != nil) {

    [mAttachment setPosition:mPosition];
    [mAttachment setRotation:mRotationRadians];

    [mAttachment draw:projection];
    return;
  }

  [self setupRenderMatrix];

  // Copy over indice buffer ID from our host, if we have one
  if(mUsesIndicesFromActor && mHostIndiceBuffer != nil) {
    mVertexIndiceBuffer = *mHostIndiceBuffer;
  }

  if(mActiveMaterial == mColorMaterial) {

    /* TODO: Fix color material to use new VBO system
    [mColorMaterial draw:projection
              withModelV:mModelViewMatrix
                 indices:mVertexIndices
               vertCount:mVertexCount
                    mode:mRenderMode]; */

  } else if(mActiveMaterial == mTextureMaterial) {

    [mTextureMaterial draw:projection
                withModelV:mModelViewMatrix
          withIndiceBuffer:mVertexIndiceBuffer
             withVertCount:mVertexCount
                 withLayer:mLayer
                  withMode:mRenderMode];

  }
}

/**
* If we have a physics body, update our visual with its state.
*/
- (void) update {
  if(mPhysicsBody != nil) {
    mPosition = [AdefyRenderer worldToScreen:mPhysicsBody.pos];
    mRotationRadians = mPhysicsBody.angle;
  }
}

/**
* Check if we have either a dynamic or static body.
*/
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

/**
* Alias for creating a physics body with our saved mass/friction/elasticity.
*/
- (void)createPhysicsBody {
  [self createPhysicsBody:_mMass
                 friction:_mFriction
               elasticity:_mElasticity];
}

/**
* Generates a cpVect array suitable for ChipmunkJS, with coordinates translated into world-space.
*/
- (cpVect *) generatePhysicsVerts {

  cpVect *physicsVerts = malloc(sizeof(cpVect) * mVertexCount);

  for(GLuint i = 0; i < mVertexCount; i++) {
    physicsVerts[i] = [AdefyRenderer screenToWorld:
        cpv(mVertexData[i].vertex.x, mVertexData[i].vertex.y)];
  }

  return physicsVerts;
}

/**
* Set new physics vertices, this re-creates our physics body if we have one.
*/
- (void) setPhysicsVerts:(cpVect *)verts
                   count:(unsigned int)count {

  if(mPhysicsVertices) {
    free(mPhysicsVertices);
  }

  mPhysicsVertices = verts;
  mPhysicsVertCount = count;

  if([self hasPhysicsBody]) {
    [self destroyPhysicsBody];
    [self createPhysicsBody];
  }
}

/**
* Create new physics body, destroying the current one if needed. The mass/friction/elasticity values are saved for
* later use.
*
* Dynamic bodies use our state, whereas we have to manually rotate our physics vertices for static bodies.
*/
- (void)createPhysicsBody:(float)mass
                 friction:(float)friction
               elasticity:(float)elasticity {

  if([self hasPhysicsBody])  {
    [self destroyPhysicsBody];
  }

  // Copy physics verts (free'd after shape creation)
  cpVect *copyPhysicsVerts = malloc(sizeof(cpVect) * mPhysicsVertCount);
  for(unsigned int i = 0; i < mPhysicsVertCount; i++) {
    copyPhysicsVerts[i] = cpv(mPhysicsVertices[i].x, mPhysicsVertices[i].y);
  }

  if(mass == 0.0f) {

    // Static body. We can't rotate static bodies, so rotate the physics verts manually
    for(unsigned int i = 0; i < mPhysicsVertCount; i++) {

      float x = copyPhysicsVerts[i].x;
      float y = copyPhysicsVerts[i].y;

      copyPhysicsVerts[i].x = (x * (float)cos(mRotationRadians)) - (y * (float)sin(mRotationRadians));
      copyPhysicsVerts[i].y = (x * (float)sin(mRotationRadians)) + (y * (float)cos(mRotationRadians));
    }

    mPhysicsBody = nil;
    mPhysicsShape = [ChipmunkPolyShape polyWithBody:[mPhysics getStaticBody]
                                              count:mPhysicsVertCount
                                              verts:copyPhysicsVerts
                                             offset:[AdefyRenderer screenToWorld:mPosition]];

  } else {

    // Dynamic body
    float moment = cpMomentForPoly(mass, mPhysicsVertCount, copyPhysicsVerts, cpv(0, 0));
    mPhysicsBody = [ChipmunkBody bodyWithMass:mass andMoment:moment];

    [mPhysicsBody setPos:[AdefyRenderer screenToWorld:mPosition]];
    [mPhysicsBody setAngle:mRotationRadians];

    mPhysicsShape = [ChipmunkPolyShape polyWithBody:mPhysicsBody
                                              count:mPhysicsVertCount
                                              verts:copyPhysicsVerts
                                             offset:cpv(0, 0)];
  }

  [mPhysicsShape setFriction:friction];
  [mPhysicsShape setElasticity:elasticity];
  [mPhysicsShape setLayers:mPhysicsLayer];

  [mPhysics registerShape:mPhysicsShape];

  if(mPhysicsBody != nil) {
    [mPhysics registerBody:mPhysicsBody];
  }

  free(copyPhysicsVerts);
}

/**
* Update our model view matrix using our current position and rotation.
*/
- (void) setupRenderMatrix {

  float finalX = mPosition.x - [mRenderer getCameraPosition].x + mRenderOffset.x;
  float finalY = mPosition.y - [mRenderer getCameraPosition].y + mRenderOffset.y;

  mModelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, finalX, finalY, 0.0f);
  mModelViewMatrix = GLKMatrix4Rotate(mModelViewMatrix, mRotationRadians + mRenderOffsetRotationRadians, 0.0f, 0.0f, 1.0f);
}

@end
