#import "AdefySingleColorMaterial.h"
#import "AdefyColor3.h"
#import "AdefyShader.h"
#import "AdefyTexturedMaterial.h"
#import "AdefyRenderer.h"

static GLuint STATIC_SHADER;

static GLuint STATIC_POSITION_HANDLE;
static GLuint STATIC_COLOR_HANDLE;
static GLuint STATIC_MODEL_HANDLE;
static GLuint STATIC_PROJECTION_HANDLE;
static GLuint STATIC_LAYER_HANDLE;

static BOOL STATIC_JUST_USED;
static BOOL STATIC_SHADER_BUILT;
static NSString *STATIC_NAME;

static GLfloat *STATIC_COLOR;

@implementation AdefySingleColorMaterial {

@private
  AdefyColor3* mColor;
}

+ (void)initialize {
  STATIC_NAME = @"single_color";
  STATIC_JUST_USED = NO;
  STATIC_SHADER_BUILT = NO;

  STATIC_COLOR = malloc(sizeof(GLfloat) * 4);
  STATIC_COLOR[0] = 1.0f;
  STATIC_COLOR[1] = 1.0f;
  STATIC_COLOR[2] = 1.0f;
  STATIC_COLOR[3] = 1.0f;
}

+ (void)initShader {

  [self setVertSource:@"ShaderSingleColor"];
  [self setFragSource:@"ShaderSingleColor"];
  [self buildShader];
}

+ (void)buildShader {
  [self destroyShader];

  NSString *vertSource = [self getVertSource];
  NSString *fragSource = [self getFragSource];

  [AdefyShader buildProgram:&STATIC_SHADER withVert:vertSource withFrag:fragSource];

  STATIC_POSITION_HANDLE = (GLuint)glGetAttribLocation(STATIC_SHADER, "Position");
  STATIC_COLOR_HANDLE = (GLuint)glGetUniformLocation(STATIC_SHADER, "Color");
  STATIC_MODEL_HANDLE = (GLuint)glGetUniformLocation(STATIC_SHADER, "ModelView");
  STATIC_PROJECTION_HANDLE = (GLuint)glGetUniformLocation(STATIC_SHADER, "Projection");
  STATIC_LAYER_HANDLE = (GLuint) glGetUniformLocation(STATIC_SHADER, "Layer");

  NSLog(@"<SingleColorMaterial> Built shader");

  STATIC_SHADER_BUILT = YES;
  STATIC_JUST_USED = NO;
}

+ (void)destroyShader {
  glDeleteProgram(STATIC_SHADER);
  STATIC_SHADER = 0;
  STATIC_SHADER_BUILT = NO;
}

+ (BOOL)wasJustUsed { return STATIC_JUST_USED; }
+ (void)setJustUsed:(BOOL)used { STATIC_JUST_USED = used; }

+ (NSString *)getName { return STATIC_NAME; }
- (NSString *)getName { return [AdefySingleColorMaterial getName]; }

- (GLuint)getShader { return STATIC_SHADER; }

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

- (void) draw:(GLKMatrix4)projection
      withModelV:(GLKMatrix4)modelView
withIndiceBuffer:(GLuint)indiceBuffer
   withVertCount:(GLuint)vertCount
       withLayer:(GLint)layer
        withMode:(GLenum)mode {

#ifdef DEBUG
  [self glErrorCheck:@"<SingleColorMaterial> Loop start"];
#endif

  if(!STATIC_JUST_USED) {
    STATIC_JUST_USED = YES;

    [AdefyTexturedMaterial postFinalDraw];
    [AdefyTexturedMaterial setJustUsed:false];

    glEnableVertexAttribArray(STATIC_POSITION_HANDLE);

    glVertexAttribPointer(STATIC_POSITION_HANDLE, 2, GL_SHORT, GL_FALSE, sizeof(VertexData2D), 0);

#ifdef DEBUG
    [self glErrorCheck:@"<SingleColorMaterial> Finished justUsed()"];
#endif
  }

  // Copy color into float[] array, to prevent allocation
  [mColor copyToFloatArray:STATIC_COLOR];

#ifdef DEBUG
  [self glErrorCheck:@"<SingleColorMaterial> Bound vert buffer"];
#endif

  // Setup actor state
  glUniformMatrix4fv(STATIC_PROJECTION_HANDLE, 1, GL_FALSE, projection.m);
  glUniformMatrix4fv(STATIC_MODEL_HANDLE, 1, GL_FALSE, modelView.m);
  glUniform4fv(STATIC_COLOR_HANDLE, 1, STATIC_COLOR);
  glUniform1i(STATIC_LAYER_HANDLE, layer);

#ifdef DEBUG
  [self glErrorCheck:@"<SingleColorMaterial> Set uniforms"];
#endif

  // Bind actor indices
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indiceBuffer);

#ifdef DEBUG
  [self glErrorCheck:@"<SingleColorMaterial> Bound indice buffer"];
#endif

  glDrawElements(GL_TRIANGLE_FAN, vertCount, GL_UNSIGNED_SHORT, 0);

#ifdef DEBUG
  [self glErrorCheck:@"<SingleColorMaterial> Post glDrawElements()"];
#endif

}

// Called by other textures if they draw after us
+ (void)postFinalDraw {
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
}

@end
