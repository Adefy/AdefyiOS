//
// Created by Cris Mihalache on 09/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefyShader.h"

NSString *shaderExt = @"vsh";

@interface AdefyShader ()

+(NSString *)getShaderPath:(NSString *)name;

@end

@implementation AdefyShader {

}

+(BOOL)buildProgram:(GLuint *)prog withVert:(NSString *)vert withFrag:(NSString *)frag {

  GLuint vertShader;
  GLuint fragShader;
  *prog = glCreateProgram();

  // Compile
  if(![AdefyShader compileShader:&vertShader type:GL_VERTEX_SHADER name:vert]) {
    NSLog(@"Failed to compile vertex shader");
    return NO;
  }

  if(![AdefyShader compileShader:&fragShader type:GL_FRAGMENT_SHADER name:frag]) {
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

+(BOOL)compileShader:(GLuint *)shader type:(GLenum)type name:(NSString *)name {

  GLint status;
  const GLchar *source;

  NSString *file = [AdefyShader getShaderPath:name];

  source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
  if (!source) {
    NSLog(@"Failed to load vertex shader");
    return NO;
  }

  *shader = glCreateShader(type);
  glShaderSource(*shader, 1, &source, NULL);
  glCompileShader(*shader);

  glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);

  if (status == 0) { glDeleteShader(*shader); }
  return status != 0;
}

+(BOOL)linkProgram:(GLuint)prog {

  GLint status;
  glLinkProgram(prog);

  glGetProgramiv(prog, GL_LINK_STATUS, &status);
  return status != 0;
}

+(NSString *)getShaderPath:(NSString *)name {
  return [[NSBundle mainBundle] pathForResource:name ofType:shaderExt];
}

@end