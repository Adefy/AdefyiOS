#import "AdefyPolygonActor.h"
#import "AdefyRenderer.h"

@implementation AdefyPolygonActor {
}

+ (GLfloat *) generateVertices:(float)radius
                  withSegments:(unsigned int)segments {

  unsigned int count = [AdefyPolygonActor getVertCount:segments];
  GLfloat *verts = calloc(count * 2, sizeof(GLfloat));
  GLfloat *tempVerts = calloc(count * 2, sizeof(GLfloat));

  // Generate verts, uses algo from:
  // http://slabode.exofire.net/circle_draw.shtml
  float x = radius;
  float y = 0;
  double theta = (2.0f * 3.1415926f) / segments;
  float tanFactor = (float)tan(theta);
  float radFactor = (float)cos(theta);

  for(unsigned int i = 0; i < segments; i++) {

    // NOTE! We cast floats to doubles.
    tempVerts[i * 2] = x;
    tempVerts[(i * 2) + 1] = y;

    double tx = -y;
    double ty = x;

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

- (cpVect *) generatePhysicsVerts:(GLfloat *)verts
                            count:(unsigned int)count {

  cpVect *physicsVerts = malloc(sizeof(cpVect) * (count));

  for(unsigned int i = 0; i < count; i++) {
    physicsVerts[i] = cpv(verts[i * 2], verts[(i * 2) + 1]);
    physicsVerts[i] = [AdefyRenderer screenToWorld:physicsVerts[i]];
  }

  return physicsVerts;
}

+ (GLfloat *) generateUVCoords:(GLfloat* )vertices
                         count:(unsigned int)count
                        radius:(float)radius {

  GLfloat *coords = malloc(sizeof(GLfloat) * count * 2);

  for(unsigned int i = 0; i < count * 2; i++) {
    coords[i] = ((vertices[i] / radius) / 2.0f) + 0.5f;
  }

  return coords;
}

+ (unsigned int)getVertCount:(unsigned int)segments {
  return segments;
}

- (AdefyPolygonActor *)init:(int)id
                withRadius:(float)radius
              withSegments:(unsigned int)segments {

  unsigned int vertCount = [AdefyPolygonActor getVertCount:segments];

  GLfloat *verts = [AdefyPolygonActor generateVertices:radius
                                          withSegments:segments];

  GLfloat *texCoords = [AdefyPolygonActor generateUVCoords:verts
                                                     count:vertCount
                                                    radius:radius];

  self = [super init:id
            vertices:verts
           vertCount:vertCount
           texCoords:texCoords
            texCount:vertCount];

  [self setRenderMode:GL_TRIANGLE_FAN];

  return self;
}

@end