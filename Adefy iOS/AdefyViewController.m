#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/message.h>
#import "AdefyViewController.h"
#import "AdefyRenderer.h"
#import "AdefySingleColorMaterial.h"
#import "AdefyPhysics.h"
#import "AdefyJSInterface.h"
#import "AdefyDownloader.h"
#import "AdefyAnimationManager.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#if !defined(DEBUG) || !(TARGET_IPHONE_SIMULATOR)
#define NSLog(...)
#endif

@interface AdefyViewController () {

  GLKMatrix4 mProjectionMatrix;
  AdefyRenderer *mRenderer;
  AdefyPhysics *mPhysics;
  AdefyAnimationManager *mAnimations;

  JSVirtualMachine *jsVM;
  JSContext *jsContext;
  AdefyJSInterface *jsInterface;
  AdefyDownloader *downloader;
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

  [self setPreferredFramesPerSecond:30];

  downloader = [[AdefyDownloader alloc] init:@"FAKE_APIKEY"];
  [downloader fetchAd:@"watch" withDurationMS:1000 withTemplate:@"watch_template" withCB:^{
    [self initTest];
  }];

  mPhysics = [[AdefyPhysics alloc] init];
  mRenderer = [[AdefyRenderer alloc] init:(GLsizei)self.view.bounds.size.width
                                   height:(GLsizei)self.view.bounds.size.height];
  mAnimations = [[AdefyAnimationManager alloc] init:mRenderer];

  [AdefyRenderer setGlobalInstance:mRenderer];
  [AdefyPhysics setGlobalInstance:mPhysics];
}

- (void)executeAdLogic:(NSString *)basePath
             withLogic:(NSString *)logicPath
               withAJS:(NSString *)AJSPath {

  // Load files
  NSError *error;
  NSString *fullAJSPath = [[NSString alloc] initWithFormat:@"%@%@", basePath, AJSPath];
  NSString *AJS = [[NSString alloc] initWithContentsOfFile:fullAJSPath
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];

  if(!AJS || error) {
    NSLog(@"%@", [error localizedDescription]);
    NSLog(@"Failed to load AJS library from %@", AJSPath);
    return;
  }

  NSString *fullLogicPath = [[NSString alloc] initWithFormat:@"%@%@", basePath, logicPath];
  NSString *adLogic = [[NSString alloc] initWithContentsOfFile:fullLogicPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];

  if(!adLogic || error) {
    NSLog(@"%@", [error localizedDescription]);
    NSLog(@"Failed to load AJS library from %@", AJSPath);
    return;
  }

  // Prepare context and interface
  jsVM = [[JSVirtualMachine alloc] init];
  jsContext = [[JSContext alloc] initWithVirtualMachine:jsVM];
  jsInterface = [[AdefyJSInterface alloc] init:jsContext
                                  withRenderer:mRenderer
                          withAnimationManager:mAnimations];

  [jsContext evaluateScript:AJS];

  // We have to map param manually (no actual window, we partially fake it)
  [jsContext evaluateScript:@"var param = window.param;"];

  [jsContext evaluateScript:adLogic];
}

- (void)initTest {
  [self displayGLAd:@"watch"];
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

- (void)displayGLAd:(NSString *)name {

  NSString *path = [downloader getPathForGLAd:name];

  // Ensure path exists
  BOOL isDir;
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path
                                                         isDirectory:&isDir];

  if(!fileExists || !isDir) {
    NSLog(@"GLAd with name '%@' not found.", name);
    return;
  }

  NSLog(@"Loading...");

  NSError *error;
  NSString *manifestPath = [[NSString alloc] initWithFormat:@"%@package.json", path];
  NSData *manifestData = [NSData dataWithContentsOfFile:manifestPath
                                                options:0
                                                  error:&error];

  if(error) {
    NSLog(@"Error loading GLAd manifest: %@", [error localizedDescription]);
    NSLog(@"Attempted load from %@", manifestPath);
    return;
  }

  NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:manifestData
                                                           options:0
                                                             error:&error];

  if(error) {
    NSLog(@"Error parsing GLAd manifest: %@", [error localizedDescription]);
    return;
  }

  NSString *adFile = [manifest valueForKey:@"ad"];
  NSString *AJSFile = [manifest valueForKey:@"lib"];
  NSString *clickURL = [manifest valueForKey:@"click"];
  NSString *impressionURL = [manifest valueForKey:@"impression"];

  if(!adFile) { NSLog(@"Ad filename missing from manifest"); }
  if(!AJSFile) { NSLog(@"AJS library filename missing from manifest"); }
  if(!clickURL) { NSLog(@"Click URL missing from manifest"); }
  if(!impressionURL) { NSLog(@"Impression URL missing from manifest"); }

  if(!adFile || !AJSFile || !clickURL || !impressionURL) {
    NSLog(@"Invalid manifest, can't load GLAd %@", name);
    return;
  }

  NSArray *textures = [manifest valueForKey:@"textures"];

  // Load up textures
  if(textures) {
    for(NSDictionary *texture in textures) {

      NSString *texCompression = [texture valueForKey:@"compression"];
      NSString *texName = [texture valueForKey:@"name"];
      NSString *texType = [texture valueForKey:@"type"];
      NSString *texPath = [[NSString alloc]
          initWithFormat:@"%@%@", path, [texture valueForKey:@"path"]];

      [mRenderer loadTexture:texName
                      ofType:texType
                    fromPath:texPath
             withCompression:texCompression];
    }
  }

  [self executeAdLogic:path
             withLogic:adFile
               withAJS:AJSFile];
}

@end
