#import <GLKit/GLKit.h>
#import "AdefyTexturedMaterial.h"
#import "AdefyShader.h"
#import "AdefySingleColorMaterial.h"
#import "AdefyRenderer.h"

static GLuint STATIC_SHADER;

static BOOL STATIC_JUST_USED;
static NSString *STATIC_NAME;

static GLuint STATIC_POSITION_HANDLE;
static GLuint STATIC_MODEL_HANDLE;
static GLuint STATIC_PROJECTION_HANDLE;

static GLuint STATIC_UV_SCALE_HANDLE;
static GLuint STATIC_TEX_COORD_HANDLE;
static GLuint STATIC_TEX_SAMPLER_HANDLE;
static GLuint STATIC_LAYER_HANDLE;

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
  STATIC_LAYER_HANDLE = (GLuint) glGetUniformLocation(STATIC_SHADER, "Layer");
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

- (void) draw:(GLKMatrix4)projection
   withModelV:(GLKMatrix4)modelView
withIndiceBuffer:(GLuint)indiceBuffer
withVertCount:(GLuint)vertCount
    withLayer:(GLint)layer
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

    // Alpha blending
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Texture! TODO: Create a texture atlas manager, that can stitch textures together
    glActiveTexture(GL_TEXTURE0);

    // Setup pointers into bound VBO
    glEnableVertexAttribArray(STATIC_POSITION_HANDLE);
    glEnableVertexAttribArray(STATIC_TEX_COORD_HANDLE);

    glVertexAttribPointer(STATIC_POSITION_HANDLE, 2, GL_SHORT, GL_FALSE, sizeof(VertexData2D), 0);
    glVertexAttribPointer(STATIC_TEX_COORD_HANDLE, 2, GL_UNSIGNED_SHORT, GL_TRUE, sizeof(VertexData2D), BUFFER_OFFSET(sizeof(GLshort) * 2));

#ifdef DEBUG
    [self glErrorCheck:@"<TextureMaterial> Finished justUsed()"];
#endif
  }

  // Setup actor state
  glUniformMatrix4fv(STATIC_PROJECTION_HANDLE, 1, GL_FALSE, projection.m);
  glUniformMatrix4fv(STATIC_MODEL_HANDLE, 1, GL_FALSE, modelView.m);
  glUniform1i(STATIC_LAYER_HANDLE, layer);

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Set uniforms"];
#endif

  // Bind actor indices
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indiceBuffer);

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Bound indice buffer"];
#endif

  glDrawElements(mode, vertCount, GL_UNSIGNED_SHORT, 0);

#ifdef DEBUG
  [self glErrorCheck:@"<TextureMaterial> Post glDrawElements()"];
#endif
}

// Called by other textures if they draw after us
+ (void)postFinalDraw {
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
  glDisableVertexAttribArray(STATIC_TEX_COORD_HANDLE);
  glDisable(GL_BLEND);
}

@end