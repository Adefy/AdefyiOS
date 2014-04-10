//
//  AdefyRenderer.h
//  Adefy iOS
//
//  Created by Cris Mihalache on 09/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "chipmunk.h"

@class AdefyActor;

@interface AdefyRenderer : NSObject {

  @private
  int mTargetFPS;
  int mTargetFrameTime;

  NSMutableArray* mActors;
}

+(void)createVertexBuffer:(GLuint *)buffer
             withVertices:(GLfloat *)vertices
               withUseage:(GLenum)useage;

- (cpVect)getCameraPosition;

-(void) setFPS:(int)fps;
-(void) addActor:(AdefyActor *)actor;
-(AdefyActor *) getActor:(int)index;

-(void) drawFrame:(GLKMatrix4)projection;

@end
