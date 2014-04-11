#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyActor;

@interface AdefyRenderer : NSObject

+ (void)createVertexBuffer:(GLuint *)buffer
                 vertices:(GLfloat *)vertices
                    count:(int)count
                   useage:(GLenum)useage;

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height;

- (cpVect)getCameraPosition;

- (void) setClearColor:(GLfloat [4])color;
- (void) setFPS:(int)fps;
- (void) addActor:(AdefyActor *)actor;
- (AdefyActor *) getActor:(unsigned int)index;

- (void) drawFrame:(CGRect)rect;

@end
