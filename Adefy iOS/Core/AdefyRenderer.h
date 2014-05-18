#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyActor;
@class AdefyTexture;

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define TEX_COORD_F(f) (GLushort)(65535.0f * f)

typedef struct {
  GLshort x;
  GLshort y;
} Vertex2D;

typedef struct {
  GLushort u;
  GLushort v;
} TextureCoord;

typedef struct {
  GLubyte r;
  GLubyte g;
  GLubyte b;
  GLubyte a;
} Color4Data;

typedef struct {
  Vertex2D vertex;
  TextureCoord texture;
  Color4Data color;
} VertexData2D;

@interface AdefyRenderer : NSObject

+ (float) getPPM;
+ (float) getMPP;
+ (cpVect) worldToScreen:(cpVect)v;
+ (cpVect) screenToWorld:(cpVect)v;
+ (int) getNextActorID;

- (GLfloat *)getClearColor;

+ (void)setGlobalInstance:(AdefyRenderer *)renderer;
+ (AdefyRenderer *)getGlobalInstance;

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height;

- (cpVect)getCameraPosition;

- (void)setCameraPosition:(cpVect)v;

- (void) updateClearColorWith:(GLfloat[4])color;
- (void) addActor:(AdefyActor *)actor;

- (void)scheduleLayerSort;

- (void)resortActorsByLayer;

- (void) removeActor:(AdefyActor *)actor;

- (void)regenerateVBO;

- (GLuint)getVBO;

- (AdefyTexture *)getTexture:(NSString *)name;

- (void)loadTexture:(NSString *)name ofType:(NSString *)type fromPath:(NSString *)path withCompression:(NSString *)compression;

- (AdefyActor *) getActor:(unsigned int)index;
- (AdefyActor *) getActorById:(int)id;

- (void) update;
- (void) drawFrame:(CGRect)rect;

@end
