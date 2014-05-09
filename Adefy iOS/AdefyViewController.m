#import <JavaScriptCore/JavaScriptCore.h>
#import "AdefyViewController.h"
#import "AdefyRenderer.h"
#import "AdefySingleColorMaterial.h"
#import "AdefyPhysics.h"
#import "AdefyJSInterface.h"
#import "AdefyDownloader.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface AdefyViewController () {

  GLKMatrix4 mProjectionMatrix;
  AdefyRenderer *mRenderer;
  AdefyPhysics *mPhysics;

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

  [self setPreferredFramesPerSecond:60];

  downloader = [[AdefyDownloader alloc] init:@"FAKE_APIKEY"];
  // [downloader fetchAd:@"test" withDurationMS:1000];

  mPhysics = [[AdefyPhysics alloc] init];
  mRenderer = [[AdefyRenderer alloc] init:(GLsizei)self.view.bounds.size.width
                                   height:(GLsizei)self.view.bounds.size.height];

  [AdefyRenderer setGlobalInstance:mRenderer];
  [AdefyPhysics setGlobalInstance:mPhysics];

  [self initTest];
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
                                  withRenderer:mRenderer];

  [jsContext evaluateScript:AJS];

  // We have to map param manually (no actual window, we partially fake it)
  [jsContext evaluateScript:@"var param = window.param;"];

  NSLog(@"%@", adLogic);

  [jsContext evaluateScript:adLogic];
}

- (void)initTest {

  [self displayGLAd:@"test"];

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
                                                options:nil
                                                  error:&error];

  if(error) {
    NSLog(@"Error loading GLAd manifest: %@", [error localizedDescription]);
    NSLog(@"Attempted load from %@", manifestPath);
    return;
  }

  NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:manifestData
                                                           options:nil
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
