#import <GLKit/GLKit.h>
#import "AdefyTexturedMaterial.h"
#import "AdefyShader.h"

static const int STATIC_VERT_STRIDE = 3 * sizeof(GL_FLOAT);
static const int STATIC_TEX_VERT_STRIDE = 2 * sizeof(GL_FLOAT);

BOOL STATIC_JUST_USED;
NSString *STATIC_NAME;

GLuint STATIC_POSITION_HANDLE;
GLuint STATIC_MODEL_HANDLE;
GLuint STATIC_PROJECTION_HANDLE;

GLuint STATIC_UV_SCALE_HANDLE;
GLuint STATIC_TEX_COORD_HANDLE;
GLuint STATIC_TEX_SAMPLER_HANDLE;

GLuint PREV_TEXTURE_HANDLE;

@implementation AdefyTexturedMaterial {

@protected
  GLuint mTextureHandle;
  GLfloat mTextureU;
  GLfloat mTextureV;
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

  GLuint shader;
  [AdefyShader buildProgram:&shader withVert:vertSource withFrag:fragSource];

  STATIC_POSITION_HANDLE = (GLuint)glGetAttribLocation(shader, "Position");
  STATIC_MODEL_HANDLE = (GLuint)glGetUniformLocation(shader, "ModelView");
  STATIC_PROJECTION_HANDLE = (GLuint)glGetUniformLocation(shader, "Projection");

  STATIC_UV_SCALE_HANDLE = (GLuint)glGetAttribLocation(shader, "aUVScale");
  STATIC_TEX_COORD_HANDLE = (GLuint)glGetAttribLocation(shader, "aTexCoord");
  STATIC_TEX_SAMPLER_HANDLE = (GLuint)glGetUniformLocation(shader, "uTexture");

  [self setShader:shader];
}

+ (BOOL)wasJustUsed { return STATIC_JUST_USED; }
+ (void)setJustUsed:(BOOL)used { STATIC_JUST_USED = used; }

+ (NSString *)getName { return STATIC_NAME; }
- (NSString *)getName { return [AdefyTexturedMaterial getName]; }

- (GLuint)getShader { return [AdefyTexturedMaterial getShader]; }

- (AdefyTexturedMaterial *)init:(GLuint)handle
                          withU:(GLfloat)U
                          withV:(GLfloat)V {
  self = [super init];

  mTextureHandle = handle;
  mTextureU = U;
  mTextureV = V;

  return self;
}

- (void)setTextureHandle:(GLuint)handle { mTextureHandle = handle; }
- (void)setUScale:(GLfloat)U { mTextureU = U; }
- (void)setVScale:(GLfloat)V { mTextureV = V; }

- (void)draw:(GLKMatrix4)projection
   withModelV:(GLKMatrix4)modelView
    withVerts:(GLuint *)vertBuffer
withVertCount:(int)vertCount
withTexCoords:(GLuint *)texCoordBuffer
withTexCCount:(int)texCount
     withMode:(GLenum)mode {

  // Check if we need to re-build our shader
  if([AdefyTexturedMaterial getShader] == 0) {
    [AdefyTexturedMaterial buildShader];
  }

  glBindBuffer(GL_ARRAY_BUFFER, *vertBuffer);

  if(![AdefyTexturedMaterial wasJustUsed]) {
    [AdefyTexturedMaterial setJustUsed:true];

    glEnableVertexAttribArray(STATIC_POSITION_HANDLE);
    glEnableVertexAttribArray(STATIC_TEX_COORD_HANDLE);

    glVertexAttribPointer(STATIC_POSITION_HANDLE, 3, GL_FLOAT, GL_FALSE, STATIC_VERT_STRIDE, 0);
    glVertexAttribPointer(STATIC_TEX_COORD_HANDLE, 2, GL_FLOAT, GL_FALSE, STATIC_TEX_VERT_STRIDE, 0);

    glActiveTexture(GL_TEXTURE0);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
  }

  if(mTextureHandle != PREV_TEXTURE_HANDLE) {
    glBindTexture(GL_TEXTURE_2D, mTextureHandle);
    glUniform1i(STATIC_TEX_SAMPLER_HANDLE, 0);
    glVertexAttrib2f(STATIC_UV_SCALE_HANDLE, mTextureU, mTextureV);

    PREV_TEXTURE_HANDLE = mTextureHandle;
  }

  glUniformMatrix4fv(STATIC_PROJECTION_HANDLE, 1, GL_FALSE, projection.m);
  glUniformMatrix4fv(STATIC_MODEL_HANDLE, 1, GL_FALSE, modelView.m);

  glDrawArrays(mode, 0, vertCount * 3);
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
}

// Called by other textures if they draw after us
+ (void)postFinalDraw {
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
  glDisableVertexAttribArray(STATIC_TEX_COORD_HANDLE);
  glDisable(GL_BLEND);
}

@end