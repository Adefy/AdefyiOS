#import "AdefyPolygonActor.h"

@implementation AdefyPolygonActor {

}

+ (GLfloat *) generateVertices:(float)radius
                  withSegments:(unsigned int)segments {

  int count = [AdefyPolygonActor getVertCount:segments];
  GLfloat *verts = malloc(sizeof(GLfloat) * count * 3);

  // Generate verts, uses algo from:
  // http://slabode.exofire.net/circle_draw.shtml
  double x = radius;
  double y = 0;
  double theta = (2.0f * 3.1415926f) / segments;
  double tanFactor = tan(theta);
  double radFactor = cos(theta);

  for(int i = 0; i < segments; i++) {

    // NOTE! We cast floats to doubles.
    verts[i * 3] = (float)x;
    verts[(i * 3) + 1] = (float)y;
    verts[(i * 3) + 2] = 1.0f;

    double tx = -y;
    double ty = x;

    x += tx * tanFactor;
    y += ty * tanFactor;

    x *= radFactor;
    y *= radFactor;
  }

  // Cap shape
  verts[(segments * 3)] = 0;
  verts[(segments * 3) + 1] = 1;
  verts[(segments * 3) + 2] = 1;

  return verts;
}

+ (unsigned int)getVertCount:(unsigned int)segments {
  return segments + 1;
}

- (AdefyPolygonActor *)init:(int)id
                withRadius:(float)radius
              withSegments:(unsigned int)segments {

  unsigned int vertCount = [AdefyPolygonActor getVertCount:segments];
  GLfloat *verts = [AdefyPolygonActor generateVertices:radius
                                          withSegments:segments];

  self = [super init:id
     vertices:verts
        count:vertCount];

  [self setRenderMode:GL_TRIANGLE_FAN];

  return self;
}

@end