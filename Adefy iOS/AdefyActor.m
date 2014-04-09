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
#import "chipmunk.h"
#import "AdefyMaterial.h"
#import "AdefySingleColorMaterial.h"

// Private methods
@interface AdefyActor ()

-(void) addToRenderer;
-(void) setupRenderMatrix;

@end

@implementation AdefyActor {

  // Instance vars
  @private
  int mId;
  BOOL mVisible;

  NSMutableArray *mVertices;

  float mRotation;    // Stored in radians
  cpVect mPosition;

  GLKMatrix4 mModelViewMatrix;

  AdefyRenderer *mRenderer;
  AdefyMaterial *mMaterial;
}

-(AdefyActor *) init:(int)id withRenderer:(AdefyRenderer *)renderer {
  self = [super init];

  mId = id;
  mRenderer = renderer;
  mVertices = [[NSMutableArray alloc] init];
  mRotation = 0.0f;
  mPosition = cpv(0.0f, 0.0f);
  mMaterial = [[AdefySingleColorMaterial alloc] init];

  [self addToRenderer];

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

//
// Fancy stuff
//

-(void) addToRenderer {
  [mRenderer addActor:self];
}

-(void) draw:(GLKMatrix4)projection {
  if(!mVisible) { return; }

  [self setupRenderMatrix];

  // This all has to be moved into a single color material
  // [mMaterial
  //     draw:projection
  //     withModelView:mModelViewMatrix.m
  //     withVerts:mVertices.
  //     withMode:GL_TRIANGLE_STRIP
  //     withVertCount:[mVertices count]
  // ];
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
