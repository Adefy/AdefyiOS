#import "AdefyPolygonActor.h"

/**
* We keep track of generated polygon actors, so that redundant radius/segment pairs can use
* the same vertex entries in the renderer VBO. (They share indices).
*
* NOTE: Vertex data is still generated for every single actor!
*       This is done in case actor verts/texture coords are ever updated, so our indices can be used.
*/
static NSMutableDictionary *POLY_ACTOR_IDS;

/**
* We also re-use raw vertices, since they are copied into vertex data anyways. This dictionary holds
* pointers to raw vertices!
*/
static NSMutableDictionary *POLY_ACTOR_RAW_VERTS;

@implementation AdefyPolygonActor {

@protected
  float mRadius;
  unsigned int mSegments;
}

+ (void) initialize {
  POLY_ACTOR_IDS = [[NSMutableDictionary alloc] init];
  POLY_ACTOR_RAW_VERTS = [[NSMutableDictionary alloc] init];
}

- (cpVect *) generatePhysicsVerts {

  unsigned int count = [AdefyPolygonActor getVertCount:mSegments];
  GLfloat *raw = [self generateRawVertices];
  cpVect *physicsVerts = malloc(sizeof(cpVect) * count);

  for(unsigned int i = 0; i < count; i++) {
    physicsVerts[i] = [AdefyRenderer screenToWorld:cpv(raw[i * 2], raw[(i * 2) + 1])];
  }

  return physicsVerts;
}

/**
* Generate high-precision float vertices, to be either used for physics, or converted to GLshorts for rendering
* NOTE: The results of this method are cached! They should NOT be freed!
*/
- (GLfloat *) generateRawVertices {

  // Check if we've already performed this generation
  NSString *genDefLookup = [[NSString alloc] initWithFormat:@"%f.%i", mRadius, mSegments];
  NSValue *genDef = [POLY_ACTOR_RAW_VERTS valueForKey:genDefLookup];

  // If so, return the cached pointer
  if(genDef) {
    return (GLfloat *)[genDef pointerValue];
  }

  // Else , continue onwards!
  unsigned int count = [self getVertexCount];
  GLfloat *verts = calloc(count * 2, sizeof(GLfloat));
  GLfloat *tempVerts = calloc(count * 2, sizeof(GLfloat));

  // Generate verts, uses algo from:
  // http://slabode.exofire.net/circle_draw.shtml
  float x = mRadius;
  float y = 0;
  double theta = (2.0f * 3.1415926f) / mSegments;
  float tanFactor = (float)tan(theta);
  float radFactor = (float)cos(theta);

  for(unsigned int i = 0; i < count; i++) {

    // NOTE! We cast floats to doubles.
    tempVerts[i * 2] = x;
    tempVerts[(i * 2) + 1] = y;

    float tx = -y;
    float ty = x;

    x += tx * tanFactor;
    y += ty * tanFactor;

    x *= radFactor;
    y *= radFactor;
  }

  // Reverse winding
  for(unsigned int i = 1; i <= count; i++) {
    verts[(i - 1) * 2] = tempVerts[(count - i) * 2];
    verts[((i - 1) * 2) + 1] = tempVerts[((count - i) * 2) + 1];
  }

  free(tempVerts);

  // Cache verts
  [POLY_ACTOR_RAW_VERTS setValue:[NSValue valueWithPointer:verts] forKey:genDefLookup];

  return verts;
}

- (VertexData2D *) generateVertexData {

  unsigned int count = [AdefyPolygonActor getVertCount:mSegments];
  VertexData2D *data = malloc(sizeof(VertexData2D) * count);
  GLfloat *raw = [self generateRawVertices];

  // Cast floats to GLshorts and setup UVs
  for(unsigned int i = 0; i < count; i++) {

    data[i].vertex.x = (GLshort)round(raw[i * 2]);
    data[i].vertex.y = (GLshort)round(raw[(i * 2) + 1]);

    float u = ((data[i].vertex.x / mRadius) / 2.0f) + 0.5f;
    float v = ((data[i].vertex.y / mRadius) / 2.0f) + 0.5f;

    data[i].texture.u = TEX_COORD_F(u);
    data[i].texture.v = TEX_COORD_F(v);
  }

  return data;
}

// Get
+ (GLuint)getVertCount:(GLuint)segments {
  return segments;
}

- (GLuint) getVertexCount {
  return [AdefyPolygonActor getVertCount:mSegments];
}

- (AdefyPolygonActor *)init:(int)id
                 withRadius:(float)radius
               withSegments:(unsigned int)segments {

  mSegments = segments;
  mRadius = radius;

  // Check if any poly actor has been created with the same parameters
  NSString *polyDefLookup = [[NSString alloc] initWithFormat:@"%f.%i", radius, segments];
  NSNumber *polyDef = [POLY_ACTOR_IDS objectForKey:polyDefLookup];

  GLuint *indiceBuffer = nil;

  // Poly already exists, grab indice buffer
  if(polyDef) {
    int defId = [polyDef intValue];

    AdefyActor *actor = [[AdefyRenderer getGlobalInstance] getActorById:defId];

    if(actor) {
      indiceBuffer = [actor getIndiceBufferPointer];
    }
  } else {

    // Add our def to the dictionary for future actors
    polyDef = [[NSNumber alloc] initWithInt:id];
    [POLY_ACTOR_IDS setObject:polyDef forKey:polyDefLookup];
  }

  GLuint vertCount = [self getVertexCount];
  VertexData2D *data = [self generateVertexData];

  // We only add ourselves to the renderer if no indice buffer was found
  self = [super init:id
          vertexData:data
         vertexCount:vertCount
       addToRenderer:indiceBuffer == nil];

  // If we have a target host actor, set our indices up and register with the renderer
  if(indiceBuffer != nil) {
    [self setHostIndiceBuffer:indiceBuffer];
    [self addToOwnRenderer];
  }

  [self setRenderMode:GL_TRIANGLE_FAN];

  return self;
}

@end