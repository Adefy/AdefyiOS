#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyActor;

@interface AdefyRenderer : NSObject

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

- (void) drawFrame:(CGRect)rect;

@end
