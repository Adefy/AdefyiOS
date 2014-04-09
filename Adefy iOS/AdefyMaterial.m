//
// Created by Cris Mihalache on 09/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefyMaterial.h"


GLuint STATIC_SHADER;
NSString *STATIC_VERT_SHADER_SRC;
NSString *STATIC_FRAG_SHADER_SRC;

@implementation AdefyMaterial {

@private
  NSString *mName;

}

+(void)initialize {
  STATIC_VERT_SHADER_SRC = [[NSString alloc] init];
  STATIC_FRAG_SHADER_SRC = [[NSString alloc] init];
}

+(void)setVertSource:(NSString *)src {
  STATIC_VERT_SHADER_SRC = src;
}

+(void)setFragSource:(NSString *)src {
  STATIC_FRAG_SHADER_SRC = src;
}

+(void)setShader:(GLuint)shader {
  STATIC_SHADER = shader;
}

+(NSString *)getVertSource {
  return STATIC_VERT_SHADER_SRC;
}

+(NSString *)getFragSource {
  return STATIC_FRAG_SHADER_SRC;
}

+(GLuint)getShader {
  return STATIC_SHADER;
}

-(void) init:(NSString *)name {
  mName = name;
}

- (NSString *)getName {
  return nil;
}


// Consider this virtual. Implement eeeeet with the material class
- (GLuint)getShader {
  return [AdefyMaterial getShader];
}


@end