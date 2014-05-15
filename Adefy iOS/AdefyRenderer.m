#import "AdefyRenderer.h"
#import "AdefyActor.h"
#import "AdefyMaterial.h"
#import "AdefyTexture.h"

static AdefyRenderer *GLOBAL_INSTANCE;
static int LAST_ACTOR_ID;

// Helper
NSUInteger nearestPowerOfTwo(NSUInteger v) {

  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  v++;

  return v;
}

@interface  AdefyRenderer ()

-(GLKMatrix4) generateProjection:(CGRect)rect;

@end

@implementation AdefyRenderer {

@protected
  cpVect mCameraPosition;
  GLfloat *mClearColor;
  NSMutableString *mActiveMaterial;

  NSMutableArray *mActors;
  NSMutableArray *mTextures;
}

static float PPM;

+ (void) initialize {
  PPM = 128.0f;
  LAST_ACTOR_ID = 0;
}

+ (int) getNextActorID {
  return LAST_ACTOR_ID++;
}

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height {

  self = [super init];

  mActors = [[NSMutableArray alloc] init];
  mTextures = [[NSMutableArray alloc] init];

  mCameraPosition = cpv(0.0f, 0.0f);
  mActiveMaterial = [[NSMutableString alloc] init];

  mClearColor = malloc(sizeof(GLfloat) * 4);

  mClearColor[0] = 0.0f;
  mClearColor[1] = 0.0f;
  mClearColor[2] = 0.0f;
  mClearColor[3] = 1.0f;

  glViewport(0, 0, width, height);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);

  NSLog(@"Initialized renderer %ix%i", width, height);

  return self;
}

+ (float) getPPM { return PPM; }
+ (float) getMPP { return 1.0f / PPM; }

+ (cpVect)worldToScreen:(cpVect)v {
  return cpv(v.x * PPM, v.y * PPM);
}

+ (cpVect)screenToWorld:(cpVect)v {
  return cpv(v.x / PPM, v.y / PPM);
}

- (void) addActor:(AdefyActor *)actor {
  [mActors addObject:actor];
  [self resortActorsByLayer];
}

- (void) removeActor:(AdefyActor *)actor {
  [mActors removeObject:actor];
}

- (void) resortActorsByLayer {

  [mActors sortUsingComparator:^NSComparisonResult(id a, id b) {

    NSNumber *aL = [[NSNumber alloc] initWithInt:[(AdefyActor *)a getLayer]];
    NSNumber *bL = [[NSNumber alloc] initWithInt:[(AdefyActor *)b getLayer]];

    return [aL compare:bL];
  }];
}

- (void) addTexture:(AdefyTexture *)texture {
  [mTextures addObject:texture];
}

- (AdefyTexture *) getTexture:(NSString *)name {

  for(AdefyTexture *texture in mTextures) {
    if([[texture getName] isEqualToString:name]) {
      return texture;
    }
  }

  return nil;
}

- (AdefyTexture *) loadUncompressedTexture:(NSString *)name
                                      path:(NSString *)path {

  CGImageRef image = [[UIImage imageWithContentsOfFile:path] CGImage];
  if(!image) {
    NSLog(@"Failed to load texture from image '%@' at %@", name, path);
    return nil;
  }

  // Get padded dimensions
  GLuint width = CGImageGetWidth(image);
  GLuint height = CGImageGetHeight(image);

  GLuint POTWidth = nearestPowerOfTwo(width);
  GLuint POTHeight = nearestPowerOfTwo(height);

  float clipU = (float)width / POTWidth;
  float clipV = (float)height / POTHeight;

  // Allocate buffer, and prepare image data
  size_t bufferSize = POTWidth * POTHeight * 4;
  GLubyte *textureData = calloc(bufferSize, sizeof(GLubyte));

  if(!textureData) {
    NSLog(@"Insufficient RAM for texture %@ (%i bytes)", name, (int)bufferSize);
  } else {
    NSLog(@"Loaded data for texture %@ (%i bytes)", name, (int)bufferSize);
  }

  CGContextRef imageContext = CGBitmapContextCreate(
      textureData,                    // Render buffer
      POTWidth,                       // Width
      POTHeight,                      // Height
      8,                              // Bits per component
      POTWidth * 4,                   // Bytes-per-row
      CGImageGetColorSpace(image),    // Colorspace
      kCGImageAlphaPremultipliedLast  // Bitmap info (alpha)
  );

  // Draw image on buffer
  CGContextDrawImage(imageContext, CGRectMake(0, POTHeight - height, width, height), image);
  CGContextRelease(imageContext);

  // Load into GL ES
  GLuint texHandle;
  glGenTextures(1, &texHandle);
  glBindTexture(GL_TEXTURE_2D, texHandle);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glTexImage2D(
      GL_TEXTURE_2D,
      0,                // LOD
      GL_RGBA,          // Internal format
      POTWidth,         // Width
      POTHeight,        // Height
      0,                // Border width
      GL_RGBA,          // Texel format (must match internal format)
      GL_UNSIGNED_BYTE, // Type of texel data
      textureData       // Texel data
  );

  free(textureData);

  return [[AdefyTexture alloc] init:name
                         withHandle:texHandle
                          withClipU:clipU
                          withClipV:clipV];
}

- (void) loadTexture:(NSString *)name
              ofType:(NSString *)type
            fromPath:(NSString *)path
     withCompression:(NSString *)compression {

  BOOL canLoad = [self canLoadTexture:name
                               ofType:type
                      withCompression:compression];

  if(!canLoad) { return; }

  AdefyTexture *texture = nil;

  if([compression isEqualToString:@"none"]) {
    texture = [self loadUncompressedTexture:name path:path];
  }

  if(texture != nil) {
    [self addTexture:texture];

    // Go through and reset texture on all actors referencing it
    // Actors can be created and textures set before we have actually loaded them
    for(AdefyActor *actor in mActors) {
      if([[actor getTextureName] isEqualToString:name]) {
        [actor setTexture:name];
      }
    }
  } else {
    NSLog(@"Failed to load texture '%@'", name);
  }
}

- (BOOL) canLoadTexture:(NSString *)name
                 ofType:(NSString *)type
        withCompression:(NSString *)compression {

  // Sadly we don't support texture atlases just yet
  if(![type isEqualToString:@"image"]) {
    NSLog(@"Unsupported texture type for '%@': %@", name, type);
    return NO;
  }

  // Support uncompressed textures only (no ETC1 on iOS, too lazy atm to code loader)
  if(![compression isEqualToString:@"none"]) {
    NSLog(@"Unsupported compression type for '%@': %@", name, compression);
    return NO;
  }

  return YES;
}

- (AdefyActor *) getActor:(unsigned int)index {
  return [mActors objectAtIndex:index];
}

- (cpVect) getCameraPosition {
  return mCameraPosition;
}

- (void) setCameraPosition:(cpVect)v {
  mCameraPosition.x = v.x;
  mCameraPosition.y = v.y;
}

- (void) setClearColor:(GLfloat [4])color {

  mClearColor[0] = color[0];
  mClearColor[1] = color[1];
  mClearColor[2] = color[2];
  mClearColor[3] = color[3];

  glClearColor(color[0], color[1], color[2], color[3]);
}

- (GLfloat *) getClearColor {
  return mClearColor;
}

+ (void)setGlobalInstance:(AdefyRenderer *)renderer {
  GLOBAL_INSTANCE = renderer;
}

+ (AdefyRenderer *)getGlobalInstance {
  return GLOBAL_INSTANCE;
}

+ (void)createVertexBuffer:(GLuint *)buffer
                 vertices:(GLfloat *)vertices
                    count:(int)count
               components:(unsigned int)components
                   useage:(GLenum)useage {

  glGenBuffers(1, buffer);
  glBindBuffer(GL_ARRAY_BUFFER, *buffer);

  glBufferData(GL_ARRAY_BUFFER, count * components * sizeof(GL_FLOAT), vertices, useage);
}

- (GLKMatrix4) generateProjection:(CGRect)rect {
  return GLKMatrix4MakeOrtho(0, rect.size.width, 0, rect.size.height, -10, 10);
}

- (AdefyActor *)getActorById:(int)id {

  for(AdefyActor *actor in mActors) {
    if([actor getId] == id) {
      return actor;
    }
  }

  return nil;
}

- (void)update {
  for(AdefyActor *actor in mActors) {
    [actor update];
  }
}

- (void) drawFrame:(CGRect)rect {

  GLKMatrix4 projection = [self generateProjection:rect];

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  for(AdefyActor *actor in mActors) {

    // Switch material if needed
    if(![mActiveMaterial isEqualToString:[actor getMaterialName]]) {

      glUseProgram([[actor getMaterial] getShader]);
      [mActiveMaterial setString:[actor getMaterialName]];
    }

    [actor draw:projection];
  }
}

@end
