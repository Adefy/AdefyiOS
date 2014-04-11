#import "AdefyViewController.h"
#import "AdefyRenderer.h"
#import "AdefySingleColorMaterial.h"
#import "AdefyActor.h"
#import "AdefyRectangleActor.h"
#import "AdefyColor3.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface AdefyViewController () {

  GLKMatrix4 mProjectionMatrix;
  AdefyRenderer *mRenderer;
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

  mRenderer = [[AdefyRenderer alloc] init:(GLsizei)self.view.bounds.size.width
                                   height:(GLsizei)self.view.bounds.size.height];

  [self initTest];
}

- (void)initTest {

  AdefyRectangleActor *actor = [[AdefyRectangleActor alloc] init:1
                                                        renderer:mRenderer
                                                           width:25
                                                          height:25];

  AdefyColor3 *color = [[AdefyColor3 alloc] init:0 withG:153 withB:204];

  [actor setRotation:45 inDegrees:YES];
  [actor setColor:color];
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

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  [mRenderer drawFrame:rect];
}

@end
