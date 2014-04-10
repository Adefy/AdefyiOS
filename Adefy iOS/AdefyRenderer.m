//
//  AdefyRenderer.m
//  Adefy iOS
//
//  Created by Cris Mihalache on 09/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefyRenderer.h"
#import "AdefyActor.h"
#import "AdefyMaterial.h"

@implementation AdefyRenderer {
  cpVect mCameraPosition;
  NSMutableString *mActiveMaterial;
}

static float PPM;

//
// Init
//

+(void) initialize {
  PPM = 128.0f;
}

-(AdefyRenderer *) init {
  self = [super init];

  mActors = [[NSMutableArray alloc] init];
  mCameraPosition = cpv(0.0f, 0.0f);

  [mActiveMaterial setString:@""];

  [self setFPS:60];

  return self;
}

//
// Getters and setters
//

+(float) getPPM { return PPM; }
+(float) getMPP { return 1.0f / PPM; }

-(void) addActor:(AdefyActor *)actor {
  [mActors addObject:actor];
}

-(AdefyActor *) getActor:(int)index {
  return [mActors objectAtIndex:index];
}

-(cpVect) getCameraPosition {
  return mCameraPosition;
}

-(void) setFPS:(int)fps {
  mTargetFPS = fps;
  mTargetFrameTime = 1000 / fps;
}

//
//
//

+(void)createVertexBuffer:(GLuint *)buffer
             withVertices:(GLfloat *)vertices
               withUseage:(GLenum)useage {

  glGenBuffers(1, buffer);
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  glBufferData(buffer, sizeof(vertices), vertices, useage);
}

-(void) drawFrame:(GLKMatrix4)projection {

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  for(AdefyActor *actor in mActors) {

    // Switch material if needed
    if(mActiveMaterial != [actor getMaterialName]) {
      glUseProgram([[actor getMaterial] getShader]);
      [mActiveMaterial setString:[actor getMaterialName]];
    }

    [actor draw:projection];
  }
}

@end
