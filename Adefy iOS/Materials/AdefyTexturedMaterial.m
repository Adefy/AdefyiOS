#import <GLKit/GLKit.h>
#import "AdefyTexturedMaterial.h"
#import "AdefyShader.h"
#import "AdefySingleColorMaterial.h"

static const int STATIC_VERT_STRIDE = 3 * sizeof(GLfloat);
static const int STATIC_TEX_VERT_STRIDE = 2 * sizeof(GLfloat);

static GLuint STATIC_SHADER;

static BOOL STATIC_JUST_USED;
static NSString *STATIC_NAME;

static GLuint STATIC_POSITION_HANDLE;
static GLuint STATIC_MODEL_HANDLE;
static GLuint STATIC_PROJECTION_HANDLE;

static GLuint STATIC_UV_SCALE_HANDLE;
static GLuint STATIC_TEX_COORD_HANDLE;
static GLuint STATIC_TEX_SAMPLER_HANDLE;

static GLuint PREV_TEXTURE_HANDLE;

@implementation AdefyTexturedMaterial {

@protected
  GLuint mTextureHandle;
  GLfloat mTextureU;
  GLfloat mTextureV;

  BOOL mNeedsValueRefresh;
}

+ (void)initialize {
  STATIC_NAME = @"textured";
  STATIC_JUST_USED = NO;

  [self setVertSource:@"ShaderTexture"];
  [self setFragSource:@"ShaderTexture"];
  [self buildShader];
}

+ (void)buildShader {
  [self destroyShader];

  NSString *vertSource = [self getVertSource];
  NSString *fragSource = [self getFragSource];

  [AdefyShader buildProgram:&STATIC_SHADER withVert:vertSource withFrag:fragSource];

  STATIC_POSITION_HANDLE = (GLuint)glGetAttribLocation(STATIC_SHADER, "Position");
  STATIC_MODEL_HANDLE = (GLuint)glGetUniformLocation(STATIC_SHADER, "ModelView");
  STATIC_PROJECTION_HANDLE = (GLuint)glGetUniformLocation(STATIC_SHADER, "Projection");

  STATIC_UV_SCALE_HANDLE = (GLuint)glGetAttribLocation(STATIC_SHADER, "aUVScale");
  STATIC_TEX_COORD_HANDLE = (GLuint)glGetAttribLocation(STATIC_SHADER, "aTexCoord");
  STATIC_TEX_SAMPLER_HANDLE = (GLuint)glGetUniformLocation(STATIC_SHADER, "uTexture");

  NSLog(@"<Texture Material> Built shader");
}

+ (void)destroyShader { glDeleteProgram(STATIC_SHADER); }

+ (BOOL)wasJustUsed { return STATIC_JUST_USED; }
+ (void)setJustUsed:(BOOL)used { STATIC_JUST_USED = used; }

+ (NSString *)getName { return STATIC_NAME; }
- (NSString *)getName { return [AdefyTexturedMaterial getName]; }

- (GLuint)getShader { return STATIC_SHADER; }

- (AdefyTexturedMaterial *)init:(GLuint)handle
                          withU:(GLfloat)U
                          withV:(GLfloat)V {
  self = [super init];

  mTextureHandle = handle;
  mTextureU = U;
  mTextureV = V;
  mNeedsValueRefresh = NO;

  return self;
}

- (void)setTextureHandle:(GLuint)handle { mTextureHandle = handle; mNeedsValueRefresh = YES; }
- (void)setUScale:(GLfloat)U { mTextureU = U; mNeedsValueRefresh = YES; }
- (void)setVScale:(GLfloat)V { mTextureV = V; mNeedsValueRefresh = YES; }

- (void)draw:(GLKMatrix4)projection
   withModelV:(GLKMatrix4)modelView
    withVerts:(GLuint *)vertBuffer
withVertCount:(int)vertCount
withTexCoords:(GLuint *)texCoordBuffer
withTexCCount:(int)texCount
     withMode:(GLenum)mode {

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Loop start"];
#endif

  if(mTextureHandle != PREV_TEXTURE_HANDLE || mNeedsValueRefresh) {

    glBindTexture(GL_TEXTURE_2D, mTextureHandle);
    glVertexAttrib2f(STATIC_UV_SCALE_HANDLE, mTextureU, mTextureV);

#ifdef DEBUG
    [self glErrorCheck:@"<TextureMaterial> Bound texture and UV scale"];
#endif

    PREV_TEXTURE_HANDLE = mTextureHandle;
    mNeedsValueRefresh = NO;
  }

  if(!STATIC_JUST_USED) {
    STATIC_JUST_USED = YES;

    [AdefySingleColorMaterial postFinalDraw];
    [AdefySingleColorMaterial setJustUsed:false];

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    glActiveTexture(GL_TEXTURE0);

    glEnableVertexAttribArray(STATIC_POSITION_HANDLE);
    glEnableVertexAttribArray(STATIC_TEX_COORD_HANDLE);

#ifdef DEBUG
    [self glErrorCheck:@"<TextureMaterial> Finished justUsed()"];
#endif
  }

  glUniformMatrix4fv(STATIC_PROJECTION_HANDLE, 1, GL_FALSE, projection.m);
  glUniformMatrix4fv(STATIC_MODEL_HANDLE, 1, GL_FALSE, modelView.m);

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Set uniforms"];
#endif

  //
  // Bind buffers
  glBindBuffer(GL_ARRAY_BUFFER, *vertBuffer);
  glVertexAttribPointer(STATIC_POSITION_HANDLE, 3, GL_FLOAT, GL_FALSE, STATIC_VERT_STRIDE, 0);

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Bound vertex buffer"];
#endif

  glBindBuffer(GL_ARRAY_BUFFER, *texCoordBuffer);
  glVertexAttribPointer(STATIC_TEX_COORD_HANDLE, 2, GL_FLOAT, GL_FALSE, STATIC_TEX_VERT_STRIDE, 0);

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Bound tex coord buffer"];
#endif

  //
  //

  glDrawArrays(mode, 0, vertCount);

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Post drawArrays()"];
#endif
}

// Called by other textures if they draw after us
+ (void)postFinalDraw {
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
  glDisableVertexAttribArray(STATIC_TEX_COORD_HANDLE);
  glDisable(GL_BLEND);
}

@end