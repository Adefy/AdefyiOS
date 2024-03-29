#import "AdefyJSActorInterface.h"
#import "AdefyRectangleActor.h"
#import "AdefyColor3.h"
#import "AdefyPolygonActor.h"

@implementation AdefyJSActorInterface {

@protected
  AdefyRenderer *mRenderer;
}
- (AdefyJSActorInterface *)init:(AdefyRenderer *)renderer {
  self = [super init];

  mRenderer = renderer;

  return self;
}

// Implemented
- (BOOL)destroyActor:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor removeAttachment];
  [actor destroyPhysicsBody];
  [mRenderer removeActor:actor];

  return YES;
}

// Implemented
- (int)createPolygonActor:(float)radius
                 segments:(unsigned int)segments {
  int id = [AdefyRenderer getNextActorID];

  AdefyActor* actor = [[AdefyPolygonActor alloc] init:id
                                           withRadius:radius
                                         withSegments:segments];

  return [actor getId];
}

// Implemented
- (int)createRectangleActor:(float)width
                     height:(float)height {
  int id = [AdefyRenderer getNextActorID];

  AdefyActor* actor =   [[AdefyRectangleActor alloc] init:id
                                                    width:width
                                                   height:height];

  return [actor getId];
}

// Implemented
- (int)createCircleActor:(float)radius {
  int id = [AdefyRenderer getNextActorID];

  // We use a static segment count of 32 for circles
  AdefyActor* actor =   [[AdefyPolygonActor alloc] init:id
                                             withRadius:radius
                                          withSegments:32];

  return [actor getId];
}

// STUB
- (int)createTextActor:(NSString *)text
                  size:(int)size
                     r:(int)r
                     g:(int)g
                     b:(int)b {
  return 0;
}

// Implemented
- (BOOL)attachTexture:(NSString *)texture
                width:(float)width
               height:(float)height
                    x:(float)x
                    y:(float)y
                angle:(float)angle
                   id:(int)id {
  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor attachTexture:texture
                 width:width
                height:height
               offsetX:x
               offsetY:y
                 angle:angle];

  return YES;
}

// Implemented
- (BOOL)removeAttachment:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor removeAttachment];

  return YES;
}

// Implemented
- (BOOL)setAttachmentVisibility:(BOOL)visible
                             id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  AdefyActor *attachment = [actor getAttachment];
  if(attachment == nil) { return NO; }

  [attachment setVisible:visible];

  return YES;
}

// Implemented
- (BOOL)setActorLayer:(int)layer
                   id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setLayer:layer];

  return YES;
}

// Implemented
- (BOOL)setActorPhysicsLayer:(int)layer
                          id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setLayer:layer];

  return YES;
}

// Implemented
- (BOOL)setPhysicsVertices:(NSString *)verts
                        id:(int)id {
  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  NSError *error = nil;
  NSData *JSONData = [verts dataUsingEncoding:NSUTF8StringEncoding];
  NSArray *rawVerts = [NSJSONSerialization JSONObjectWithData:JSONData
                                                      options:0
                                                        error:&error];

  if(error) {
    NSLog(@"Invalid JSON vertex array passed to interface");
    return NO;
  }

  GLuint vertCount = [rawVerts count] / 2;
  cpVect *physicsVerts = malloc(sizeof(cpVect) * vertCount);

  for(unsigned int i = 0; i < vertCount; i++) {

    NSNumber *x = [rawVerts objectAtIndex:(i * 2)];
    NSNumber *y = [rawVerts objectAtIndex:(i * 2) + 1];

    physicsVerts[i] = cpv([x floatValue], [y floatValue]);
    physicsVerts[i] = [AdefyRenderer screenToWorld:physicsVerts[i]];
  }

  [actor setPhysicsVerts:physicsVerts count:vertCount];

  return YES;
}

// Implemented
- (BOOL)setRenderMode:(unsigned int)mode
                   id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setRenderMode:mode];

  return YES;
}

// Implemented
- (BOOL)updateVertices:(NSString *)verts
                    id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  NSError *error = nil;
  NSData *JSONData = [verts dataUsingEncoding:NSUTF8StringEncoding];
  NSArray *vertices = [NSJSONSerialization JSONObjectWithData:JSONData
                                                      options:0
                                                        error:&error];

  if(error) {
    NSLog(@"Invalid JSON vertex array passed to interface");
    return NO;
  }

  // Verts are stored in a flat array, but JSON is an array of vert objects
  // So multiply by two for each component (2D verts)
  GLuint vertCount = [vertices count] / 2;
  Vertex2D *data = malloc(sizeof(VertexData2D) * vertCount);

  for(unsigned int i = 0; i < vertCount; i++) {
    NSNumber *x = [vertices objectAtIndex:(i * 2)];
    NSNumber *y = [vertices objectAtIndex:(i * 2) + 1];

    data[i].x = [x shortValue];
    data[i].y = [y shortValue];
  }

  [actor updateVerticesWith:data];

  return YES;
}

// Implemented
- (BOOL)setActorPosition:(float)x
                       y:(float)y
                      id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setPosition:x y:y];

  return YES;
}

// Implemented
- (BOOL)setActorRotation:(float)angle
                      id:(int)id
                 radians:(BOOL)radians {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setRotation:angle inDegrees:!radians];

  return YES;
}

// Implemented
- (BOOL)setActorColor:(GLubyte)r
                    g:(GLubyte)g
                    b:(GLubyte)b
                   id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  AdefyColor3 *color = [[AdefyColor3 alloc] init:r withG:g withB:b];
  [actor setColor:color];

  return YES;
}

// Implemented
- (BOOL)setActorTexture:(NSString *)name
                     id:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor setTexture:name];

  return YES;
}

// Implemented
- (NSString *)getVertices:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return nil; }

  NSMutableString *JSON = [[NSMutableString alloc] initWithString:@"["];
  VertexData2D *data = [actor getVertexData];
  GLuint vertexCount = [actor getVertexCount];

  for(unsigned int i = 0; i < vertexCount; i++) {

    [JSON appendFormat:@"\"%i\"", data[i].vertex.x];
    [JSON appendString:@","];
    [JSON appendFormat:@"\"%i\"", data[i].vertex.y];

    if(i < vertexCount - 1) {
      [JSON appendString:@","];
    }
  }

  [JSON appendString:@"]"];

  return JSON;
}

// Implemented
- (NSString *)getActorPosition:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return nil; }

  cpVect position = [actor getPosition];

  return [[NSString alloc]
      initWithFormat:@"{ x:\"%f\", y:\"%f\" }", position.x, position.y];
}

// Implemented
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

// Implemented
- (float)getActorRotation:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return -1; }

  return [actor getRotation];
}

// Implemented
- (BOOL)destroyPhysicsBody:(int)id {

  AdefyActor *actor = [mRenderer getActorById:id];
  if(actor == nil) { return NO; }

  [actor destroyPhysicsBody];

  return YES;
}

// Implemented
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