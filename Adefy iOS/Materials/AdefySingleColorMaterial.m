#import "AdefySingleColorMaterial.h"
#import "AdefyColor3.h"
#import "AdefyShader.h"

const int STATIC_VERT_STRIDE = 3 * sizeof(GL_FLOAT);

GLuint STATIC_POSITION_HANDLE;
GLuint STATIC_COLOR_HANDLE;
GLuint STATIC_MODEL_HANDLE;
GLuint STATIC_PROJECTION_HANDLE;

BOOL STATIC_JUST_USED;
NSString *STATIC_NAME;

float STATIC_COLOR[] = {0.0f, 0.0f, 0.0f, 1.0f};

@implementation AdefySingleColorMaterial {

@private
  AdefyColor3* mColor;
}

+ (void)initialize {
  STATIC_NAME = @"single_color";
  STATIC_JUST_USED = NO;

  [self setVertSource:@"ShaderSingleColor"];
  [self setFragSource:@"ShaderSingleColor"];
  [self buildShader];
}

+ (void)buildShader {
  [self destroyShader];

  NSString *vertSource = [self getVertSource];
  NSString *fragSource = [self getFragSource];

  GLuint shader;
  [AdefyShader buildProgram:&shader withVert:vertSource withFrag:fragSource];

  STATIC_POSITION_HANDLE = (GLuint)glGetAttribLocation(shader, "Position");
  STATIC_COLOR_HANDLE = (GLuint)glGetUniformLocation(shader, "Color");
  STATIC_MODEL_HANDLE = (GLuint)glGetUniformLocation(shader, "ModelView");
  STATIC_PROJECTION_HANDLE = (GLuint)glGetUniformLocation(shader, "Projection");

  [self setShader:shader];
}

+ (BOOL)wasJustUsed {
  return STATIC_JUST_USED;
}

+ (void)setJustUsed:(BOOL)used {
  STATIC_JUST_USED = used;
}

- (AdefySingleColorMaterial *)init {
  self = [self init:[[AdefyColor3 alloc] init:255 withG:255 withB:255]];
  return self;
}

- (AdefySingleColorMaterial *)init:(AdefyColor3 *)withColor {
  self = [super init];

  mColor = withColor;

  return self;
}

- (void)setColor:(AdefyColor3 *)color {
  mColor = color;
}

- (AdefyColor3 *)getColor {
  return mColor;
}

- (void)draw:(GLKMatrix4)projection
    modelView:(GLKMatrix4)modelView
        verts:(GLuint *)vertBuffer
    vertCount:(int)vertCount
         mode:(GLenum)mode {

  // Check if we need to re-build our shader
  if([AdefySingleColorMaterial getShader] == 0) {
    [AdefySingleColorMaterial buildShader];
  }

  // Copy color into float[] array, to prevent allocation
  [mColor copyToFloatArray:STATIC_COLOR];

  glUniformMatrix4fv(STATIC_PROJECTION_HANDLE, 1, GL_FALSE, projection.m);
  glUniformMatrix4fv(STATIC_MODEL_HANDLE, 1, GL_FALSE, modelView.m);
  glUniform4fv(STATIC_COLOR_HANDLE, 1, STATIC_COLOR);

  glEnableVertexAttribArray(STATIC_POSITION_HANDLE);
  glVertexAttribPointer(STATIC_POSITION_HANDLE, 3, GL_FLOAT, GL_FALSE, STATIC_VERT_STRIDE, 0);

  // In the future, check if the textured material was just used...
  if(![AdefySingleColorMaterial wasJustUsed]) {
    [AdefySingleColorMaterial setJustUsed:true];
  }

  glDrawArrays(mode, 0, vertCount * 3);
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
}

// Called by other textures if they draw after us
+ (void)postFinalDraw {
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
}

- (GLuint)getShader {
  return [AdefySingleColorMaterial getShader];
}

@end
