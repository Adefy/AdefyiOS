#import "AdefyRenderer.h"
#import "AdefyActor.h"
#import "AdefyMaterial.h"
#import "AdefyTexture.h"

#define THROTTLE_VBO_UPDATES 0

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

  GLuint mVBO;
  GLuint mVBOUpdatesScheduled;
  GLuint mVBOUpdateCount;
  NSMutableArray *mVBOUpdateCancellations;
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

  mVBOUpdatesScheduled = 0;
  mVBOUpdateCount = 0;
  mVBOUpdateCancellations = [[NSMutableArray alloc] init];

  glViewport(0, 0, width, height);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);

  // NOTE: We never bind another array buffer!
  glGenBuffers(1, &mVBO);
  glBindBuffer(GL_ARRAY_BUFFER, mVBO);

  // TODO: Delete VBO on cleanup

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

  [self resortActors];
  [self regenerateVBO];
}

- (void) resortActors {


}

- (void) removeActor:(AdefyActor *)actor {
  [mActors removeObject:actor];
}

/**
* All actor vertices are stored in one central VBO, as we don't have a large range of actor types (we can draw
* everything with the same shader).
*
* As a result, VBO re-generation is expensive with high actor counts, or in rapid succession! To compensate for this,
* VBO re-generation is paced.
*
* Calling this method schedules a re-gen 20ms in the future. If it is called again before that re-gen occurs,
* it is cancelled and a new one is scheduled.
*
* As such, it is best to create all of a scene's actors in BULK at the start of execution,
* and simply make them visible when they are actually needed!
*
* VBO data construction happens on a background thread, which then signals back into the main thread for a GL upload.
*
* TODO: Add helpers to AJS to make this easier
*/
- (void) regenerateVBO {

#if THROTTLE_VBO_UPDATES
  dispatch_queue_t mainQ = dispatch_get_main_queue();
  dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_MSEC);

  unsigned int updateID = [mVBOUpdateCancellations count];
  [mVBOUpdateCancellations addObject:[[NSNumber alloc] initWithBool:NO]];

  // Cancel all other updates
  for(unsigned int i = 0; i < updateID; i++) {
    [mVBOUpdateCancellations replaceObjectAtIndex:i withObject:[[NSNumber alloc] initWithBool:YES]];
  }

  // Perform generation
  dispatch_after(startTime, mainQ, ^ {

    // Check if we've been cancelled
    if([[mVBOUpdateCancellations objectAtIndex:updateID] boolValue]) {
      return;
    } else {
      [mVBOUpdateCancellations removeAllObjects];
    }

    mVBOUpdateCount++;
#endif

  // Get total actor vert count for the malloc call
  unsigned int vertCount = 0;

  for(AdefyActor *actor in mActors)
    vertCount += [actor getVertexCount];

  // Build raw VB data for upload
  VertexData2D *data = malloc(sizeof(VertexData2D) * vertCount);
  unsigned int actorCount = [mActors count];

  AdefyActor *actor;
  VertexData2D *actorData;
  GLushort *indices, currentOffset = 0;
  unsigned int actorVertCount, i, j;

  for(i = 0; i < actorCount; i++) {
    actor = [mActors objectAtIndex:i];

    // We include only actors requiring their own indices,
    // and therefore providing their own vertices, in our VBO
    if([actor hasOwnIndices]) {
      actorVertCount = [actor getVertexCount];
      actorData = [actor getVertexData];

      // Store indices to send back to actor
      indices = malloc(sizeof(GLushort) * actorVertCount);

      for(j = 0; j < actorVertCount; j++) {

        data[currentOffset].vertex.x = actorData[j].vertex.x;
        data[currentOffset].vertex.y = actorData[j].vertex.y;

        data[currentOffset].texture.u = actorData[j].texture.u;
        data[currentOffset].texture.v = actorData[j].texture.v;

        data[currentOffset].color.r = actorData[j].color.r;
        data[currentOffset].color.g = actorData[j].color.g;
        data[currentOffset].color.b = actorData[j].color.b;
        data[currentOffset].color.a = actorData[j].color.a;

        indices[j] = currentOffset;
        currentOffset++;
      }

      // Give new indices to actor
      [actor setVertexIndices:indices];
    }
  }

  glBufferData(GL_ARRAY_BUFFER, vertCount * sizeof(VertexData2D), data, GL_STATIC_DRAW);
  free(data);

#if THROTTLE_VBO_UPDATES
  });
#endif
}

- (GLuint) getVBO {
  return mVBO;
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
      (CGBitmapInfo)kCGImageAlphaPremultipliedLast  // Bitmap info (alpha)
  );

  // Draw image on buffer
  CGContextDrawImage(imageContext, CGRectMake(0, POTHeight - height, width, height), image);
  CGContextRelease(imageContext);

  // TODO: Drop pink color here! (255, 0, 255)

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

  // This increases load time significantly, and is uncecessary for our needs
  // glGenerateMipmap(GL_TEXTURE_2D);

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

- (void) updateClearColorWith:(GLfloat [4])color {

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

- (GLKMatrix4) generateProjection:(CGRect)rect {
  return GLKMatrix4MakeOrtho(0, rect.size.width, 0, rect.size.height, -100, 100);
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
