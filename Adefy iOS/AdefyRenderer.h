#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyActor;

@interface AdefyRenderer : NSObject

+ (float) getPPM;
+ (float) getMPP;
+ (cpVect) worldToScreen:(cpVect)v;
+ (cpVect) screenToWorld:(cpVect)v;

+ (void)setGlobalInstance:(AdefyRenderer *)renderer;
+ (AdefyRenderer *)getGlobalInstance;

+ (void)createVertexBuffer:(GLuint *)buffer
                 vertices:(GLfloat *)vertices
                    count:(int)count
                   useage:(GLenum)useage;

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height;

- (cpVect)getCameraPosition;

- (void) setClearColor:(GLfloat [4])color;
- (void) addActor:(AdefyActor *)actor;
- (AdefyActor *) getActor:(unsigned int)index;

- (void) update;
- (void) drawFrame:(CGRect)rect;

@end
