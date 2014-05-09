#import "AdefyRectangleActor.h"
#import "AdefyRenderer.h"

@interface AdefyRectangleActor ()

- (GLfloat *) generateVertices;
- (void) refreshVertices;

@end

@implementation AdefyRectangleActor {

@protected
  float mWidth;
  float mHeight;
}

- (AdefyRectangleActor *)init:(int)id
                        width:(float)width
                       height:(float)height {

  mWidth = width;
  mHeight = height;

  GLfloat *vertices = [self generateVertices];
  GLfloat *texCoords = [self generateUVCoords];

  self = [super init:id
            vertices:vertices
           vertCount:4
           texCoords:texCoords
            texCount:4];

  return self;
}

- (void)setWidth:(float)width {

  mWidth = width;
  [self refreshVertices];
}

- (void)setHeight:(float)height {

  mHeight = height;
  [self refreshVertices];
}

- (void) refreshVertices {

  GLfloat *vertices = [self generateVertices];
  [self setVertices:vertices count:4];
  free(vertices);
}

- (GLfloat *) generateVertices {

  float hW = mWidth / 2.0f;
  float hH = mHeight / 2.0f;

  GLfloat *vertices = malloc(sizeof(GLfloat) * 8);

  vertices[0] = -hW;
  vertices[1] = -hH;
  vertices[2] = -hW;
  vertices[3] =  hH;
  vertices[4] =  hW;
  vertices[5] =  hH;
  vertices[6] =  hW;
  vertices[7] = -hH;

  return vertices;
}

- (GLfloat *) generateUVCoords {

  GLfloat *coords = malloc(sizeof(GLfloat) * 8);

  coords[0] = 0.0f;
  coords[1] = 1.0f;
  coords[2] = 0.0f;
  coords[3] = 0.0f;
  coords[4] = 1.0f;
  coords[5] = 0.0f;
  coords[6] = 1.0f;
  coords[7] = 1.0f;

  return coords;
}

- (float)getWidth  { return mWidth; }
- (float)getHeight { return mHeight; }

@end