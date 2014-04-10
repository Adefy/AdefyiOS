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

@interface AdefyRenderer : NSObject

+ (void)createVertexBuffer:(GLuint *)buffer
                 vertices:(GLfloat *)vertices
                    count:(int)count
                   useage:(GLenum)useage;

- (AdefyRenderer *)init:(GLsizei)width
                 height:(GLsizei)height;

- (cpVect)getCameraPosition;

- (void) setFPS:(int)fps;
- (void) addActor:(AdefyActor *)actor;
- (AdefyActor *) getActor:(int)index;

- (void) drawFrame:(CGRect)rect;

@end
