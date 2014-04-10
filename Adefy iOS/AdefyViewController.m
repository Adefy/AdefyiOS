//
//  AdefyViewController.m
//  Adefy iOS
//
//  Created by Cris Mihalache on 08/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefyViewController.h"
#import "AdefyRenderer.h"
#import "AdefySingleColorMaterial.h"
#import "AdefyActor.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface AdefyViewController () {

  GLKMatrix4 mProjectionMatrix;

  AdefyRenderer *mRenderer;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)tearDownGL;

@end

@implementation AdefyViewController

- (void)viewDidLoad {

  [super viewDidLoad];

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  if (!self.context) {
    NSLog(@"Failed to create ES context");
  }

  // Set up GL and whatnot
  GLKView *view = (GLKView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

  [EAGLContext setCurrentContext:self.context];

  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);

  // Initialize renderer, add some test actors
  mRenderer = [[AdefyRenderer alloc] init];

  GLfloat verts[] = {
      -5.0f, -5.0f,
      -5.0f,  5.0f,
       5.0f,  5.0f,
       5.0f, -5.0f
  };

  int actorId = 1;
  AdefyActor *actor = [[AdefyActor alloc] init:actorId
                                  withRenderer:mRenderer
                                  withVertices:verts];
}

- (void)tearDownGL {

}

- (void)dealloc {
  [self tearDownGL];

  if ([EAGLContext currentContext] == self.context) {
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];

  if ([self isViewLoaded] && ([[self view] window] == nil)) {
    self.view = nil;

    [self tearDownGL];

    if ([EAGLContext currentContext] == self.context) {
      [EAGLContext setCurrentContext:nil];
    }

    self.context = nil;
  }

  // Dispose of any resources that can be recreated.
  [AdefySingleColorMaterial destroyShader];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update { }
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

  // We probably shouldn't do this on each render....
  mProjectionMatrix = GLKMatrix4MakeOrtho(0, rect.size.width, 0, rect.size.height, -10, 10);

  // Pass it on to our renderer
  [mRenderer drawFrame:mProjectionMatrix];
}

@end
