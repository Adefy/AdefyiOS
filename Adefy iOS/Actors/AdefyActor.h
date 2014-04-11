#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyMaterial;
@class AdefyRenderer;
@class AdefyColor3;

@interface AdefyActor : NSObject

- (AdefyActor *)init:(int)id
           vertices:(GLfloat *)vertices
              count:(int)count;

- (void) draw:(GLKMatrix4)projection;
- (void) destroyPhysicsBody;
- (void) createPhysicsBody;
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

////
//// Setters
////
- (void) setVisible:(BOOL)isVisible;
- (void) setVertices:(GLfloat *)vertices
              count:(unsigned int)count;
- (void) setPosition:(cpVect)position;
- (void) setPosition:(float)x y:(float)y;
- (void) setRenderMode:(GLuint)mode;
- (void) setRotation:(float)angle;
- (void) setRotation:(float)angle inDegrees:(BOOL)degrees;
- (void) setColor:(AdefyColor3 *)color;

@property(nonatomic) float mMass;
@property(nonatomic) float mFriction;
@property(nonatomic) float mElasticity;

@end
