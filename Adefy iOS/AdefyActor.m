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

  GLuint mPosVertexBuffer;
  // GLuint mTexVertexBuffer;

  GLfloat *mRawPosVertices;
  // GLfloat *mRawTexVertices;

  float mRotation;    // Stored in radians
  cpVect mPosition;

  GLKMatrix4 mModelViewMatrix;

  AdefyRenderer *mRenderer;
  AdefyMaterial *mMaterial;
}

-(AdefyActor *)init:(int)id
       withRenderer:(AdefyRenderer *)renderer
       withVertices:(GLfloat *)vertices {

  self = [super init];

  mId = id;
  mRenderer = renderer;
  mRotation = 0.0f;
  mPosition = cpv(0.0f, 0.0f);
  mMaterial = [[AdefySingleColorMaterial alloc] init];
  mPosVertexBuffer = 0;

  [self setVertices:vertices];
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

-(void) setVertices:(GLfloat *)vertices {

  // Save raw vertices, just in case we need them (probably not)
  mRawPosVertices = vertices;

  glDeleteBuffers(1, &mPosVertexBuffer);

  [AdefyRenderer createVertexBuffer:&mPosVertexBuffer
                       withVertices:vertices
                         withUseage:GL_STATIC_DRAW];
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
      modelView:mModelViewMatrix.m
          verts:&mPosVertexBuffer
      vertCount:sizeof(mRawPosVertices)
           mode:GL_TRIANGLE_STRIP];
}

-(void) setupRenderMatrix {

  float finalX = mPosition.x - [mRenderer getCameraPosition].x;
  float finalY = mPosition.y - [mRenderer getCameraPosition].y;

  mModelViewMatrix = GLKMatrix4Identity;
  GLKMatrix4Translate(mModelViewMatrix, finalX, finalY, 1.0f);
  GLKMatrix4Rotate(mModelViewMatrix, mRotation, 0.0f, 0.0f, 1.0f);
}

-(NSString *)getMaterialName {
  return [mMaterial getName];
}

-(AdefyMaterial *)getMaterial {
  return mMaterial;
}

@end
