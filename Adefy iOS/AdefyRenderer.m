#import "AdefyRenderer.h"
#import "AdefyActor.h"
#import "AdefyMaterial.h"
#import "AdefyTexture.h"
#import "AdefyAnimationManager.h"

static static AdefyRenderer *GLOBAL_INSTANCE;

// Helper
size_t nearestPowerOfTwo(size_t v) {

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

  AdefyAnimationManager *mAnimations;
}

static float PPM;

+ (void) initialize {
  PPM = 128.0f;
}

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height {

  self = [super init];

  mActors = [[NSMutableArray alloc] init];
  mTextures = [[NSMutableArray alloc] init];
  mAnimations = [[AdefyAnimationManager alloc] init:self];

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
}

- (void) addTexture:(AdefyTexture *)texture {
  [mTextures addObject:texture];
}

- (AdefyTexture *) getTexture:(NSString *)name {
  unsigned int index = [mTextures indexOfObjectPassingTest:
      ^(id obj, NSUInteger idx, BOOL *stop) {
        return [[(AdefyTexture *)obj getName] isEqualToString:name];
      }
  ];

  if(index) {
    return [mTextures objectAtIndex:index];
  } else {
    return nil;
  }
}

- (void) loadTexture:(NSString *)name
              ofType:(NSString *)type
            fromPath:(NSString *)path
     withCompression:(NSString *)compression {

  BOOL canLoad = [self canLoadTexture:name
                               ofType:type
                      withCompression:compression];

  if(!canLoad) { return; }

  CGImageRef image = [[UIImage imageWithContentsOfFile:path] CGImage];
  if(!image) {
    NSLog(@"Failed to load texture from image '%@' at %@", name, path);
    return;
  }

  // Get padded dimensions
  size_t width = CGImageGetWidth(image);
  size_t height = CGImageGetHeight(image);

  size_t POTWidth = nearestPowerOfTwo(width);
  size_t POTHeight = nearestPowerOfTwo(height);

  float clipU = width / POTWidth;
  float clipV = height / POTHeight;

  // Allocate buffer, and prepare image data
  size_t bufferSize = POTWidth * POTHeight * 4;
  GLubyte *textureData = calloc(bufferSize, sizeof(GLubyte));

  if(!textureData) {
    NSLog(@"Insufficient RAM for texture %@ (%i bytes)", name, bufferSize);
  } else {
    NSLog(@"Loaded data for texture %@ (%i bytes)", name, bufferSize);
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
  CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image);
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

  // Now create and add texture to our internal collection
  AdefyTexture *texture = [[AdefyTexture alloc] init:name
                                          withHandle:texHandle
                                           withClipU:clipU
                                           withClipV:clipV];

  [self addTexture:texture];
}

- (BOOL) canLoadTexture:(NSString *)name
                 ofType:(NSString *)type
        withCompression:(NSString *)compression {

  // Sadly we don't support texture atlases just yet
  if(![type isEqualToString:@"image"]) {
    NSLog(@"Unsupported texture type: %@", type);
    NSLog(@"Refusing to load texture %@", name);
    return NO;
  }

  // Support uncompressed and ETC1 compressed textures
  if(![compression isEqualToString:@"none"] && ![compression isEqualToString:@"etc1"]) {
    NSLog(@"Unsupported compression type: %@", compression);
    NSLog(@"Refusing to load texture %@", name);
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
