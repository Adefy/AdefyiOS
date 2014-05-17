#import "AdefyRectangleActor.h"

/**
* We keep track of generated rectangle actors, so that redundant radius/segment pairs can use
* the same vertex entries in the renderer VBO. (They share indices).
*
* NOTE: Vertex data is still generated for every single actor!
*       This is done in case actor verts/texture coords are ever updated, so our indices can be used.
*/
static NSMutableDictionary *RECT_ACTOR_IDS;

@interface AdefyRectangleActor ()
- (void) refreshVertices;
@end

@implementation AdefyRectangleActor {

@protected
  float mWidth;
  float mHeight;
}

+ (void) initialize {
  RECT_ACTOR_IDS = [[NSMutableDictionary alloc] init];
}

- (AdefyRectangleActor *)init:(int)id
                        width:(float)width
                       height:(float)height {

  mWidth = width;
  mHeight = height;

  // Check if any rect actor has been created with the same parameters
  NSString *rectDefLookup = [[NSString alloc] initWithFormat:@"%f.%f", width, height];
  NSNumber *rectDef = [RECT_ACTOR_IDS objectForKey:rectDefLookup];

  GLuint *indiceBuffer = nil;

  // Rectangle already exists, grab indice buffer
  if(rectDef) {
    int defId = [rectDef intValue];

    AdefyActor *actor = [[AdefyRenderer getGlobalInstance] getActorById:defId];

    if(actor) {
      indiceBuffer = [actor getIndiceBufferPointer];
    }
  } else {

    // Add our def to the dictionary for future actors
    rectDef = [[NSNumber alloc] initWithInt:id];
    [RECT_ACTOR_IDS setObject:rectDef forKey:rectDefLookup];
  }

  VertexData2D *rawVerts = [self generateVertexData];

  // We only add ourselves to the renderer if no indice buffer was found
  self = [super init:id
          vertexData:rawVerts
         vertexCount:4
       addToRenderer:indiceBuffer == nil];

  // If we have a target host actor, set our indices up and register with the renderer
  if(indiceBuffer != nil) {
    [self setHostIndiceBuffer:indiceBuffer];
    [self addToOwnRenderer];
  }

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