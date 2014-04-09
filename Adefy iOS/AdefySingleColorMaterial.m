//
// Created by Cris Mihalache on 09/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefySingleColorMaterial.h"
#import "AdefyColor3.h"
#import "AdefyShader.h"

int STATIC_POSITION_HANDLE;
int STATIC_COLOR_HANDLE;
int STATIC_MODEL_HANDLE;
int STATIC_PROJECTION_HANDLE;

BOOL STATIC_JUST_USED;
NSString *STATIC_NAME;

float STATIC_COLOR[] = {0.0f, 0.0f, 0.0f, 0.0f};

@implementation AdefySingleColorMaterial {

@private
  AdefyColor3* mColor;
}

+(void)initialize {
  STATIC_NAME = @"single_color";
  STATIC_JUST_USED = NO;

  [self setVertSource:@"ShaderSingleColor"];
  [self setFragSource:@"ShaderSingleColor"];
}

+(void)buildShader {

  NSString *vertSource = [self getVertSource];
  NSString *fragSource = [self getFragSource];

  GLuint shader;
  [AdefyShader buildProgram:&shader withVert:vertSource withFrag:fragSource];
  [self setShader:shader];

  STATIC_POSITION_HANDLE = glGetAttribLocation([self getShader], "Position");
  STATIC_COLOR_HANDLE = glGetUniformLocation([self getShader], "Color");
  STATIC_MODEL_HANDLE = glGetUniformLocation([self getShader], "ModelView");
  STATIC_PROJECTION_HANDLE = glGetUniformLocation([self getShader], "Projection");

}

+ (BOOL)wasJustUsed {
  return STATIC_JUST_USED;
}

+ (void)setJustUsed:(BOOL)used {
  STATIC_JUST_USED = used;
}

-(AdefySingleColorMaterial *)init {
  self = [self init:[[AdefyColor3 alloc] init:255 withG:255 withB:255]];
  return self;
}

-(AdefySingleColorMaterial *)init:(AdefyColor3 *)withColor {
  self = [super init];

  mColor = withColor;

  return self;
}

-(void)setColor:(AdefyColor3 *)color {
  mColor = color;
}

-(AdefyColor3 *)getColor {
  return mColor;
}

-(void)draw:(GLKMatrix4)projection
    withModelView:(float *)modelView
    withVerts:(float *)vertBuffer
    withMode:(int)mode
    withVertCount:(int)vertCount {

  // Copy color into float[] array, to prevent allocation
  [mColor copyToFloatArray:STATIC_COLOR];

  glUniformMatrix4fv(STATIC_PROJECTION_HANDLE, 1, false, projection.m);
  glUniformMatrix4fv(STATIC_MODEL_HANDLE, 1, false, modelView);
  glUniform4fv(STATIC_COLOR_HANDLE, 1, STATIC_COLOR);

  glEnableVertexAttribArray(STATIC_POSITION_HANDLE);
  glVertexAttribPointer(STATIC_POSITION_HANDLE, 3, GL_FLOAT, false, 0, vertBuffer);

  if(![AdefySingleColorMaterial wasJustUsed]) {

    // In the future, check if the textured material was just used...

    [AdefySingleColorMaterial setJustUsed:true];
  }

  glDrawArrays(mode, 0, vertCount);
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
}

// Called by other textures if they draw after us
+(void)postFinalDraw {
  glDisableVertexAttribArray(STATIC_POSITION_HANDLE);
}

- (GLuint)getShader {
  return [AdefySingleColorMaterial getShader];
}

@end