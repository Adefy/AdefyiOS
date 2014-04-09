//
//  AdefyViewController.m
//  Adefy iOS
//
//  Created by Cris Mihalache on 08/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefyViewController.h"
#import "AdefyRenderer.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface AdefyViewController () {
  GLuint mShaderProgram;

  GLKMatrix4 mProjectionMatrix;

  int mPositionHandle;
  int mColorHandle;
  int mModelHandle;
  int mProjectionHandle;

  AdefyRenderer *mRenderer;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation AdefyViewController

- (void)viewDidLoad {

  [super viewDidLoad];

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  if (!self.context) {
    NSLog(@"Failed to create ES context");
  }

  GLKView *view = (GLKView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

  mRenderer = [[AdefyRenderer alloc] init];

  [self setupGL];
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
}

- (void)setupGL {
  [EAGLContext setCurrentContext:self.context];

  [self loadShaders];

  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
}

- (void)tearDownGL {

  [EAGLContext setCurrentContext:self.context];

  if (mShaderProgram) {
    glDeleteProgram(mShaderProgram);
    mShaderProgram = 0;
  }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {
 // Wat wat
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

  // We probably shouldn't do this on each render....
  mProjectionMatrix = GLKMatrix4MakeOrtho(0, rect.size.width, 0, rect.size.height, -10, 10);

  glUseProgram(mShaderProgram);

  [mRenderer drawFrame:mProjectionMatrix];
}

@end
