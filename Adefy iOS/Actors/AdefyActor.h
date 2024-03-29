#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"
#import "AdefyRenderer.h"

@class AdefyMaterial;
@class AdefyRenderer;
@class AdefyColor3;

@interface AdefyActor : NSObject

- (AdefyActor *)init:(int)id
          vertexData:(VertexData2D *)vertexData
         vertexCount:(GLuint)vertexCount;

- (AdefyActor *)init:(int)id1 vertexData:(VertexData2D *)vertexData vertexCount:(GLuint)vertexCount addToRenderer:(BOOL)addToRenderer;

- (void) draw:(GLKMatrix4)projection;
- (void) update;
- (BOOL) hasPhysicsBody;
- (void) destroyPhysicsBody;
- (void) createPhysicsBody;
- (BOOL) removeAttachment;
- (AdefyActor *) attachTexture:(NSString *)name
                         width:(float)w
                        height:(float)h
                       offsetX:(float)offx
                       offsetY:(float)offy
                         angle:(float)angle;

- (cpVect *)generatePhysicsVerts;

- (void)setPhysicsVerts:(cpVect *)verts
                  count:(unsigned int)count;

- (void) createPhysicsBody:(float)mass
                  friction:(float)friction
                elasticity:(float)elasticity;

////
//// Getters
////
- (NSString *)      getMaterialName;
- (AdefyMaterial *) getMaterial;

- (GLuint)getIndiceBuffer;

- (GLuint *)getIndiceBufferPointer;

- (void)addToOwnRenderer;

- (int)getLayer;

- (int)getPhysicsLayer;

- (BOOL)   getVisible;
- (int)    getId;
- (cpVect) getPosition;
- (cpVect) getRenderOffset;
- (float)  getRotation;
- (float)  getRenderOffsetRotation;
- (GLuint) getRenderMode;
- (AdefyColor3 *) getColor;

- (VertexData2D *)getVertexData;
- (GLuint) getVertexCount;

- (AdefyActor *) getAttachment;
- (BOOL) hasAttachment;

- (BOOL)hasOwnIndices;

- (void)setHostIndiceBuffer:(GLuint *)buffer;

- (NSString *) getTextureName;

- (void)setLayer:(int)layer;

- (void)setPhysicsLayer:(GLubyte)layer;

////
//// Setters
////
- (void) updateVerticesWith:(Vertex2D *)vertices;
- (void) updateTexCoordsWith:(TextureCoord *)coords;

- (void) setVertexIndices:(GLushort *)indices;

- (void) setTexture:(NSString *)name;
- (void) setVisible:(BOOL)isVisible;
- (void) setPosition:(cpVect)position;
- (void) setRenderOffset:(cpVect)offset;
- (void) setPosition:(float)x y:(float)y;
- (void) setRenderMode:(GLenum)mode;
- (void) setRotation:(float)angle;
- (void) setRotation:(float)angle inDegrees:(BOOL)degrees;
- (void) setRenderOffsetRotation:(float)angle;

- (void) setVertexData:(VertexData2D *)vertices count:(GLuint)count;

- (void) setColor:(AdefyColor3 *)color;
- (void) setAttachmentVisiblity:(BOOL)visible;

@property(nonatomic) float mMass;
@property(nonatomic) float mFriction;
@property(nonatomic) float mElasticity;

@end
