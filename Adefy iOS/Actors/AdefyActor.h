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

- (cpVect *)generatePhysicsVerts:(GLfloat *)verts count:(unsigned int)count;

- (void) createPhysicsBody:(float)mass
                  friction:(float)friction
                elasticity:(float)elasticity;

////
//// Getters
////
- (NSString *)      getMaterialName;
- (AdefyMaterial *) getMaterial;
- (BOOL)   getVisible;
- (int)    getId;
- (cpVect) getPosition;
- (float)  getRotation;
- (GLuint) getRenderMode;
- (AdefyColor3 *) getColor;
- (GLfloat *) getVertices;
- (GLuint) getVertexCount;
- (GLfloat *)getTexCoords;
- (GLuint)getTexCoordCount;

////
//// Setters
////
- (void) setVertices:(GLfloat *)vertices
              count:(unsigned int)count;
- (void) setTexCoords:(GLfloat *)coords
                count:(unsigned int)count;

- (void)setTexture:(NSString *)name;

- (void) setVisible:(BOOL)isVisible;
- (void) setPosition:(cpVect)position;
- (void) setPosition:(float)x y:(float)y;
- (void) setRenderMode:(GLenum)mode;
- (void) setRotation:(float)angle;
- (void) setRotation:(float)angle inDegrees:(BOOL)degrees;
- (void) setColor:(AdefyColor3 *)color;

@property(nonatomic) float mMass;
@property(nonatomic) float mFriction;
@property(nonatomic) float mElasticity;

@end
