#import <JavaScriptCore/JavaScriptCore.h>
#import "AdefyViewController.h"
#import "AdefyRenderer.h"
#import "AdefySingleColorMaterial.h"
#import "AdefyActor.h"
#import "AdefyRectangleActor.h"
#import "AdefyColor3.h"
#import "AdefyPhysics.h"
#import "AdefyJSInterface.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface AdefyViewController () {

  GLKMatrix4 mProjectionMatrix;
  AdefyRenderer *mRenderer;
  AdefyPhysics *mPhysics;

  JSVirtualMachine *jsVM;
  JSContext *jsContext;
  AdefyJSInterface *jsInterface;
}

- (void)initTest;

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

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

  [EAGLContext setCurrentContext:self.context];

  [self setPreferredFramesPerSecond:60];

  mPhysics = [[AdefyPhysics alloc] init];
  mRenderer = [[AdefyRenderer alloc] init:(GLsizei)self.view.bounds.size.width
                                   height:(GLsizei)self.view.bounds.size.height];

  [AdefyRenderer setGlobalInstance:mRenderer];
  [AdefyPhysics setGlobalInstance:mPhysics];

  [self initJSInterface];

  [self initTest];
}

- (void)initJSInterface {

  jsVM = [[JSVirtualMachine alloc] init];
  jsContext = [[JSContext alloc] initWithVirtualMachine:jsVM];

  jsInterface = [[AdefyJSInterface alloc] init:jsContext
                                  withRenderer:mRenderer];
}

- (void)initTest {

  /*
  AdefyRectangleActor *ground = [[AdefyRectangleActor alloc] init:1
                                                           width:200
                                                          height:20];

  AdefyColor3 *colorBlue = [[AdefyColor3 alloc] init:0 withG:153 withB:204];

  [ground setColor:colorBlue];
  [ground setPosition:cpv(150, 50)];
  [ground createPhysicsBody:0 friction:0.5f elasticity:0.2f];

  AdefyRectangleActor *box = [[AdefyRectangleActor alloc] init:2
                                                            width:30
                                                           height:30];

  AdefyColor3 *colorRed = [[AdefyColor3 alloc] init:204 withG:139 withB:0];

  [box setColor:colorRed];
  [box setRotation:45.0f inDegrees:YES];
  [box setPosition:cpv(150, 200)];
  [box createPhysicsBody:10.0f friction:1.0f elasticity:0.1f];
  */
}

- (void)dealloc {
  if ([EAGLContext currentContext] == self.context) {
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];

  if ([self isViewLoaded] && ([[self view] window] == nil)) {
    self.view = nil;

    if ([EAGLContext currentContext] == self.context) {
      [EAGLContext setCurrentContext:nil];
    }

    self.context = nil;
  }

  // Dispose of any resources that can be recreated.
  [AdefySingleColorMaterial destroyShader];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {

  [mRenderer update];
  [mPhysics update:(float)[self timeSinceLastUpdate]];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  [mRenderer drawFrame:rect];
}

@end
