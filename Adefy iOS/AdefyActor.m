//
//  AdefyActor.m
//  Adefy iOS
//
//  Created by Cris Mihalache on 08/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "AdefyActor.h"
#import "AdefyRenderer.h"
#import "AdefyMaterial.h"
#import "AdefySingleColorMaterial.h"

// Private methods
@interface AdefyActor ()

-(void) addToRenderer:(AdefyRenderer *)renderer;
-(void) setupRenderMatrix;

@end

@implementation AdefyActor {

  // Instance vars
  @private
  int mId;
  BOOL mVisible;

  int mPosVertexCount;
  GLuint mPosVertexBuffer;
  GLuint mPosVertexArray;
  GLfloat *mRawPosVertices;

  float mRotation;    // Stored in radians
  cpVect mPosition;

  GLKMatrix4 mModelViewMatrix;

  AdefyRenderer *mRenderer;
  AdefyMaterial *mMaterial;
}

-(AdefyActor *)init:(int)id
           renderer:(AdefyRenderer *)renderer
           vertices:(GLfloat *)vertices
              count:(int)count {

  self = [super init];

  mId = id;
  mRenderer = renderer;
  mRotation = 0.0f;
  mPosition = cpv(100.0f, 100.0f);
  mMaterial = [[AdefySingleColorMaterial alloc] init];
  mPosVertexBuffer = 0;
  mPosVertexArray = 0;
  mVisible = YES;

  [self setVertices:vertices count:count];
  [self addToRenderer:mRenderer];

  return self;
}

//
// Getters and setters
//

-(void) setVisible:(BOOL)isVisible {
  mVisible = isVisible;
}

-(BOOL) getVisible { return mVisible; }
-(int)  getId      { return mId; }

-(void) setVertices:(GLfloat *)vertices
              count:(int)count {

  // Save raw vertices, just in case we need them (probably not)
  mRawPosVertices = vertices;
  mPosVertexCount = count;

  glDeleteBuffers(1, &mPosVertexBuffer);

  [AdefyRenderer createVertexBuffer:&mPosVertexBuffer
                           vertices:vertices
                              count:count
                             useage:GL_STATIC_DRAW];
}

//
// Fancy stuff
//

-(void) addToRenderer:(AdefyRenderer *)renderer {
  [renderer addActor:self];
}

-(void) draw:(GLKMatrix4)projection {
  if(!mVisible) { return; }

  [self setupRenderMatrix];

  // This all has to be moved into a single color material
  [mMaterial
           draw:projection
      modelView:mModelViewMatrix
          verts:&mPosVertexBuffer
      vertCount:&mPosVertexCount
           mode:GL_TRIANGLE_FAN];
}

-(void) setupRenderMatrix {

  float finalX = mPosition.x - [mRenderer getCameraPosition].x;
  float finalY = mPosition.y - [mRenderer getCameraPosition].y;

  mModelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, finalX, finalY, 0.0f);
  mModelViewMatrix = GLKMatrix4Rotate(mModelViewMatrix, mRotation, 0.0f, 0.0f, 1.0f);
}

-(NSString *)getMaterialName {
  return [mMaterial getName];
}

-(AdefyMaterial *)getMaterial {
  return mMaterial;
}

@end
