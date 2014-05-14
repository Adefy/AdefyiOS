#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyMaterial;
@class AdefyRenderer;
@class AdefyColor3;

@interface AdefyActor : NSObject

- (AdefyActor *)init:(int)id
            vertices:(GLfloat *)vertices
           vertCount:(unsigned int)vCount
           texCoords:(GLfloat *)coords
            texCount:(unsigned int)tCount;

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

- (cpVect *)generatePhysicsVerts:(GLfloat *)verts count:(unsigned int)count;

- (void) createPhysicsBody:(float)mass
                  friction:(float)friction
                elasticity:(float)elasticity;

////
//// Getters
////
- (NSString *)      getMaterialName;
- (AdefyMaterial *) getMaterial;

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
- (GLfloat *) getVertices;
- (GLuint) getVertexCount;
- (GLfloat *)getTexCoords;
- (GLuint)getTexCoordCount;
- (AdefyActor *) getAttachment;
- (BOOL) hasAttachment;
- (NSString *) getTextureName;

- (void)setLayer:(int)layer;

- (void)setPhysicsLayer:(unsigned int)layer;

////
//// Setters
////
- (void) setVertices:(GLfloat *)vertices
              count:(unsigned int)count;
- (void) setTexCoords:(GLfloat *)coords
                count:(unsigned int)count;

- (void) setTexture:(NSString *)name;

- (void) setVisible:(BOOL)isVisible;
- (void) setPosition:(cpVect)position;
- (void) setRenderOffset:(cpVect)offset;
- (void) setPosition:(float)x y:(float)y;
- (void) setRenderMode:(GLenum)mode;
- (void) setRotation:(float)angle;
- (void) setRotation:(float)angle inDegrees:(BOOL)degrees;
- (void) setRenderOffsetRotation:(float)angle;
- (void) setColor:(AdefyColor3 *)color;
- (void) setAttachmentVisiblity:(BOOL)visible;

@property(nonatomic) float mMass;
@property(nonatomic) float mFriction;
@property(nonatomic) float mElasticity;

@end
