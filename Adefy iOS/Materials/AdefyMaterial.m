#import <GLKit/GLKit.h>
#import "AdefyMaterial.h"

NSString *STATIC_VERT_SHADER_SRC;
NSString *STATIC_FRAG_SHADER_SRC;

static NSDictionary *GL_ERROR_NAMES;

@implementation AdefyMaterial {

@private
  NSString *mName;
}

+ (void)initialize {
  STATIC_VERT_SHADER_SRC = [[NSString alloc] init];
  STATIC_FRAG_SHADER_SRC = [[NSString alloc] init];

  // Used by our sexy glErrorCheck()
  GL_ERROR_NAMES = @{
      @(GL_INVALID_ENUM): @"GL_INVALID_ENUM",
      @(GL_INVALID_VALUE): @"GL_INVALID_VALUE",
      @(GL_INVALID_OPERATION): @"GL_INVALID_OPERATION",
      @(GL_STACK_OVERFLOW): @"GL_STACK_OVERFLOW",
      @(GL_STACK_UNDERFLOW): @"GL_STACK_UNDERFLOW",
      @(GL_OUT_OF_MEMORY): @"GL_OUT_OF_MEMORY"
  };
}

+ (void)setVertSource:(NSString *)src { STATIC_VERT_SHADER_SRC = src; }
+ (void)setFragSource:(NSString *)src { STATIC_FRAG_SHADER_SRC = src; }
+ (NSString *)getVertSource { return STATIC_VERT_SHADER_SRC; }
+ (NSString *)getFragSource { return STATIC_FRAG_SHADER_SRC; }

+ (void)destroyShader {}

+ (BOOL)wasJustUsed { return NO; }
+ (void)buildShader {}
+ (void)setJustUsed:(BOOL)used {}
+ (void)postFinalDraw {}

- (NSString *)getName { return @"unnamed"; }

- (GLuint)getShader { return 0; }

- (void) init:(NSString *)name { mName = name; }

- (void) glErrorCheck:(NSString *)desc {
  GLenum glError;

  while((glError = glGetError()) != GL_NO_ERROR ) {
    NSLog(@"GL ERROR (%@): %@", desc, [GL_ERROR_NAMES objectForKey:@(glError)]);
  }
}

@end
