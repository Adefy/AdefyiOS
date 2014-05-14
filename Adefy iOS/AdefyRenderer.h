#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyActor;
@class AdefyTexture;

@interface AdefyRenderer : NSObject

+ (float) getPPM;
+ (float) getMPP;
+ (cpVect) worldToScreen:(cpVect)v;
+ (cpVect) screenToWorld:(cpVect)v;
+ (int) getNextActorID;

- (GLfloat *)getClearColor;

+ (void)setGlobalInstance:(AdefyRenderer *)renderer;
+ (AdefyRenderer *)getGlobalInstance;

+ (void)createVertexBuffer:(GLuint *)buffer
                  vertices:(GLfloat *)vertices
                     count:(int)count
                components:(unsigned int)components
                    useage:(GLenum)useage;

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height;

- (cpVect)getCameraPosition;

- (void)setCameraPosition:(cpVect)v;

- (void) setClearColor:(GLfloat[4])color;
- (void) addActor:(AdefyActor *)actor;
- (void) removeActor:(AdefyActor *)actor;

- (void)resortActorsByLayer;

- (AdefyTexture *)getTexture:(NSString *)name;

- (void)loadTexture:(NSString *)name ofType:(NSString *)type fromPath:(NSString *)path withCompression:(NSString *)compression;

- (AdefyActor *) getActor:(unsigned int)index;
- (AdefyActor *) getActorById:(int)id;

- (void) update;
- (void) drawFrame:(CGRect)rect;

@end
