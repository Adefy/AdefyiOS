#import "AdefyJSActorInterface.h"
#import "AdefyRectangleActor.h"
#import "AdefyRenderer.h"
#import "AdefyColor3.h"

int nextID = 0;
int getNextID() { return nextID++; }

@implementation AdefyJSActorInterface {

@protected
  AdefyRenderer *mRenderer;
}
- (AdefyJSActorInterface *)init:(AdefyRenderer *)renderer {

  self = [super init];

  mRenderer = renderer;

  return self;
}

- (BOOL)destroyActor:(int)id1 {
  return NO;
}

- (int)createPolygonActor:(NSString *)verts {
  return 0;
}

- (int)createRectangleActor:(float)width
                     height:(float)height {
  int id = getNextID();

  [[AdefyRectangleActor alloc] init:id
                              width:width
                             height:height];

  return id;
}

- (int)createCircleActor:(float)radius
                   verts:(NSString *)verts {
  return 0;
}

- (int)createTextActor:(NSString *)text
                  size:(int)size
                     r:(int)r
                     g:(int)g
                     b:(int)b {
  return 0;
}

- (BOOL)attachTexture:(NSString *)texture
                width:(float)width
               height:(float)height
                    x:(float)x
                    y:(float)y
                angle:(float)angle
                   id:(int)id {
  return NO;
}

- (BOOL)removeAttachment:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  return YES;
}

- (BOOL)setAttachmentVisibility:(BOOL)visible
                             id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  return YES;
}

- (BOOL)setActorLayer:(int)layer
                   id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  return YES;
}

- (BOOL)setActorPhysicsLayer:(int)layer
                          id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  return YES;
}

- (BOOL)setPhysicsVertices:(NSString *)verts
                        id:(int)id {
  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  return YES;
}

- (BOOL)setRenderMode:(unsigned int)mode
                   id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setRenderMode:mode];

  return YES;
}

- (BOOL)updateVertices:(NSString *)verts
                    id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  NSError *error = nil;
  NSArray *vertices = [NSJSONSerialization JSONObjectWithData:verts
                                                      options:0
                                                        error:&error];

  if(error) {
    NSLog(@"Invalid JSON vertex array passed to interface");
    return NO;
  }

  // Verts are stored in a flat array, but JSON is an array of vert objects
  // So multiply by two for each component (2D verts)
  GLfloat *finalVerts = malloc(sizeof(GLfloat) * [vertices count] * 2);

  int index = 0;
  for(NSDictionary *vert in vertices) {
    id xValue = [vert valueForKey:@"x"];
    id yValue = [vert valueForKey:@"y"];

    if(!xValue || !yValue) {
      NSLog(@"Invalid vertex format in JSON vert array");
      return NO;
    }

    finalVerts[index * 2] = [xValue floatValue];
    finalVerts[(index * 2) + 1] = [yValue floatValue];

    index++;
  }

  [actor setVertices:finalVerts
               count:[vertices count]];

  return YES;
}

- (BOOL)setActorPosition:(float)x
                       y:(float)y
                      id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setPosition:x y:y];

  return YES;
}

- (BOOL)setActorRotation:(float)angle
                      id:(int)id
                 radians:(BOOL)radians {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setRotation:angle inDegrees:!radians];

  return YES;
}

- (BOOL)setActorColor:(int)r
                    g:(int)g
                    b:(int)b
                   id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  AdefyColor3 *color = [[AdefyColor3 alloc] init:r withG:g withB:b];
  [actor setColor:color];

  return YES;
}

- (BOOL)setActorTexture:(NSString *)name
                     id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  return YES;
}

- (NSString *)getVertices:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return nil; }

  NSMutableString *JSON = [[NSMutableString alloc] initWithString:@"["];
  GLfloat *vertices = [actor getVertices];
  GLuint vertexCount = [actor getVertexCount];

  for(unsigned int i = 0; i < vertexCount; i++) {
    [JSON appendFormat:@"\"%f\"", vertices[i]];

    if(i < vertexCount - 1) {
      [JSON appendString:@","];
    }
  }

  [JSON appendString:@"]"];

  return JSON;
}

- (NSString *)getActorPosition:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return nil; }

  cpVect position = [actor getPosition];

  return [[NSString alloc]
      initWithFormat:@"{ x:\"%f\", y:\"%f\" }", position.x, position.y];
}

- (NSString *)getActorColor:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return nil; }

  AdefyColor3 *color = [actor getColor];

  if(color == nil) {
    return @"";
  } else {
    return [[NSString alloc]
        initWithFormat:@"{ r:\"%i\", g:\"%i\", b:\"%i\" }",
            [color getR], [color getG], [color getB]];
  }
}

- (float)getActorRotation:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return -1; }

  return [actor getRotation];
}

- (BOOL)destroyPhysicsBody:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor destroyPhysicsBody];

  return YES;
}

- (BOOL)enableActorPhysics:(float)mass
                  friction:(float)friction
                elasticity:(float)elasticity
                        id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor createPhysicsBody:mass friction:friction elasticity:elasticity];

  return YES;
}


@end