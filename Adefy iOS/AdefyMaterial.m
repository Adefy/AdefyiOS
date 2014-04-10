//
// Created by Cris Mihalache on 09/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "AdefyMaterial.h"

GLuint STATIC_SHADER = 0;
NSString *STATIC_VERT_SHADER_SRC;
NSString *STATIC_FRAG_SHADER_SRC;

@implementation AdefyMaterial {

@private
  NSString *mName;
}

+ (void)initialize {
  STATIC_VERT_SHADER_SRC = [[NSString alloc] init];
  STATIC_FRAG_SHADER_SRC = [[NSString alloc] init];
}

+ (void)setVertSource:(NSString *)src { STATIC_VERT_SHADER_SRC = src; }
+ (void)setFragSource:(NSString *)src { STATIC_FRAG_SHADER_SRC = src; }
+ (void)setShader:(GLuint)shader { STATIC_SHADER = shader; }
+ (NSString *)getVertSource { return STATIC_VERT_SHADER_SRC; }
+ (NSString *)getFragSource { return STATIC_FRAG_SHADER_SRC; }

+ (GLuint)getShader { return STATIC_SHADER; }
- (GLuint)getShader { return [AdefyMaterial getShader]; }

+ (void)destroyShader { glDeleteProgram([self getShader]); }

+ (BOOL)wasJustUsed { return NO; }
+ (void)buildShader {}
+ (void)setJustUsed:(BOOL)used {}
+ (void)postFinalDraw {}

- (void)draw:(GLKMatrix4)projection
   modelView:(float *)modelView
       verts:(GLuint *)vertBuffer
   vertCount:(int)vertCount
        mode:(GLenum)mode {}

- (NSString *)getName { return @"unnamed"; }
- (void) init:(NSString *)name { mName = name; }

@end