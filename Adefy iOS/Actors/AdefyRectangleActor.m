#import "AdefyRectangleActor.h"

@interface AdefyRectangleActor ()
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

  VertexData2D *rawVerts = [self generateVertexData];

  self = [super init:id
          vertexData:rawVerts
         vertexCount:4];

  return self;
}

- (VertexData2D *) generateVertexData {

  GLshort hW = (GLshort)(mWidth / 2.0f);
  GLshort hH = (GLshort)(mHeight / 2.0f);

  VertexData2D *data = malloc(sizeof(VertexData2D) * 4);

  data[0].vertex.x = -hW;
  data[0].vertex.y = -hH;
  data[0].texture.u = TEX_COORD_F(0.0f);
  data[0].texture.v = TEX_COORD_F(1.0f);

  data[1].vertex.x = -hW;
  data[1].vertex.y =  hH;
  data[1].texture.u = TEX_COORD_F(0.0f);
  data[1].texture.v = TEX_COORD_F(0.0f);

  data[2].vertex.x =  hW;
  data[2].vertex.y =  hH;
  data[2].texture.u = TEX_COORD_F(1.0f);
  data[2].texture.v = TEX_COORD_F(0.0f);

  data[3].vertex.x =  hW;
  data[3].vertex.y = -hH;
  data[3].texture.u = TEX_COORD_F(1.0f);
  data[3].texture.v = TEX_COORD_F(1.0f);

  return data;
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

  VertexData2D *data = [self generateVertexData];
  [self setVertexData:data
                count:4];
}

- (float)getWidth  { return mWidth; }
- (float)getHeight { return mHeight; }

@end