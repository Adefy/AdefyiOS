#import "AdefyShader.h"

@interface AdefyShader ()

+ (NSString *)getShaderPath:(NSString *)name
                   withExt:(NSString *)ext;

@end

@implementation AdefyShader {

}

+ (BOOL)buildProgram:(GLuint *)prog
           withVert:(NSString *)vert
           withFrag:(NSString *)frag {

  GLuint vertShader;
  GLuint fragShader;
  *prog = glCreateProgram();

  // Compile
  if(![AdefyShader compileShader:&vertShader
                            type:GL_VERTEX_SHADER
                            name:vert
                             ext:@"vsh"]) {
    NSLog(@"Failed to compile vertex shader");
    return NO;
  }

  if(![AdefyShader compileShader:&fragShader
                            type:GL_FRAGMENT_SHADER
                            name:frag
                             ext:@"fsh"]) {

    NSLog(@"Failed to compile fragment shader");
    return NO;
  }

  //Attach
  glAttachShader(*prog, vertShader);
  glAttachShader(*prog, fragShader);

  // Link
  if(![AdefyShader linkProgram:*prog]) {
    NSLog(@"Failed to link program: %d", *prog);

    if(vertShader) {
      glDeleteShader(vertShader);
      vertShader = 0;
    }

    if(fragShader) {
      glDeleteShader(fragShader);
      fragShader = 0;
    }

    if(*prog) {
      glDeleteProgram(*prog);
      *prog = 0;
    }

    return NO;
  }

  // Release
  if (vertShader) {
    glDetachShader(*prog, vertShader);
    glDeleteShader(vertShader);
  }

  if (fragShader) {
    glDetachShader(*prog, fragShader);
    glDeleteShader(fragShader);
  }

  return YES;
}

+ (BOOL)compileShader:(GLuint *)shader
                type:(GLenum)type
                name:(NSString *)name
                 ext:(NSString *)ext {

  GLint status;
  const GLchar *source;

  NSString *file = [AdefyShader getShaderPath:name withExt:ext];

  source = (GLchar *)[[NSString stringWithContentsOfFile:file
                                                encoding:NSUTF8StringEncoding
                                                   error:nil]
                      UTF8String];

  if (!source) {
    NSLog(@"Failed to load vertex shader");
    return NO;
  }

  *shader = glCreateShader(type);
  glShaderSource(*shader, 1, &source, NULL);
  glCompileShader(*shader);

#if defined(DEBUG)
  GLint logLength;
  glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);

  if (logLength > 0) {
    GLchar *log = (GLchar *)malloc(logLength);

    glGetShaderInfoLog(*shader, logLength, &logLength, log);
    NSLog(@"%@ compile log:\n%s", name, log);

    free(log);
  }
#endif

  glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);

  if (status == 0) {
    glDeleteShader(*shader);
  }

  return status != 0;
}

+ (BOOL)linkProgram:(GLuint)prog {

  GLint status;
  glLinkProgram(prog);

#if defined(DEBUG)
  GLint logLength;
  glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);

  if (logLength > 0) {
    GLchar *log = (GLchar *)malloc(logLength);

    glGetProgramInfoLog(prog, logLength, &logLength, log);
    NSLog(@"Program link log:\n%s", log);

    free(log);
  }
#endif

  glGetProgramiv(prog, GL_LINK_STATUS, &status);
  return status != 0;
}

+ (NSString *)getShaderPath:(NSString *)name
                   withExt:(NSString *)ext {
  return [[NSBundle mainBundle] pathForResource:name ofType:ext];
}

@end
