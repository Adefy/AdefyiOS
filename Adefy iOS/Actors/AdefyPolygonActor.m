#import "AdefyPolygonActor.h"
#import "AdefyRenderer.h"

@implementation AdefyPolygonActor {

@protected
  float mRadius;
  unsigned int mSegments;
}

- (cpVect *) generatePhysicsVerts {

  unsigned int count = [AdefyPolygonActor getVertCount:mSegments];
  GLfloat *raw = [self generateRawVertices];
  cpVect *physicsVerts = malloc(sizeof(cpVect) * count);

  for(unsigned int i = 0; i < count; i++) {
    physicsVerts[i] = [AdefyRenderer screenToWorld:cpv(raw[i * 2], raw[(i * 2) + 1])];
  }

  free(raw);

  return physicsVerts;
}

/**
* Generate high-precision float vertices, to be either used for physics, or converted to GLshorts for rendering
*/
- (GLfloat *) generateRawVertices {

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

  free(raw);

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

  GLuint vertCount = [self getVertexCount];
  VertexData2D *data = [self generateVertexData];

  self = [super init:id
          vertexData:data
         vertexCount:vertCount];

  [self setRenderMode:GL_TRIANGLE_FAN];

  return self;
}

@end