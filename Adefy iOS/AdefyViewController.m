#import <JavaScriptCore/JavaScriptCore.h>
#import "AdefyViewController.h"
#import "AdefyRenderer.h"
#import "AdefySingleColorMaterial.h"
#import "AdefyPhysics.h"
#import "AdefyJSInterface.h"
#import "AdefyDownloader.h"
#import "AdefyAnimationManager.h"
#import "AdefyTexturedMaterial.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#if !defined(DEBUG) || !(TARGET_IPHONE_SIMULATOR)
#define NSLog(...)
#endif

@interface AdefyViewController () {

  EAGLContext *mContext;

  GLKMatrix4 mProjectionMatrix;
  AdefyRenderer *mRenderer;
  AdefyPhysics *mPhysics;
  AdefyAnimationManager *mAnimations;

  JSVirtualMachine *mJSVM;
  JSContext *mJSContext;
  AdefyJSInterface *mJSInterface;
  AdefyDownloader *mDownloader;

  NSString *mTargetAdName;
  NSString *mTargetAdTemplate;
  NSNumber *mTargetAdDuration;
  NSString *mAPIKey;
}

@end

@implementation AdefyViewController

/**
* Called when we are first loaded, sets up all core Adefy classes and begins downloading an ad
*/
- (void)viewDidLoad {
  [super viewDidLoad];

  mJSVM = nil;
  mJSContext = nil;
  mJSInterface = nil;

  // Setup GL context
  mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  if (!mContext) {
    NSLog(@"Failed to create ES context");
  }

  GLKView *view = (GLKView *)self.view;
  view.context = mContext;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

  [EAGLContext setCurrentContext:mContext];
  [self setPreferredFramesPerSecond:30];

  // Initialise core Adefy engines
  mRenderer = [[AdefyRenderer alloc] init:(GLsizei)self.view.bounds.size.width
                                   height:(GLsizei)self.view.bounds.size.height];
  mPhysics = [[AdefyPhysics alloc] init];
  mAnimations = [[AdefyAnimationManager alloc] init:mRenderer];

  // TODO: Remove the need for global instances
  [AdefyRenderer setGlobalInstance:mRenderer];
  [AdefyPhysics setGlobalInstance:mPhysics];

  if(!mAPIKey) {
    mAPIKey = @"IOS_SDK_DEFAULT_KEY";
    NSLog(@"Warning! No API key provided. Going with %@", mAPIKey);
  }

  if(!mTargetAdName) {
    mTargetAdName = @"adefy_ios_sdk_default_ad";
    mTargetAdTemplate = @"test";
    NSLog(@"Warning! No target ad name provided. Going with %@ (template %@)", mTargetAdName, mTargetAdTemplate);
  }

  if(!mTargetAdDuration) {
    mTargetAdDuration = [NSNumber numberWithInt:5000];
    NSLog(@"Warning! No target ad duration specified, going with %ldms", (long)[mTargetAdDuration integerValue]);
  }

  mDownloader = [[AdefyDownloader alloc] init:mAPIKey];

  // Download ad if needed, and show immediately
  if(![mDownloader adDownloaded:mTargetAdName]) {

    [mDownloader fetchAd:mTargetAdName
          withDurationMS:[mTargetAdDuration integerValue]
            withTemplate:mTargetAdTemplate withCB:^{
        [self displayGLAd:mTargetAdName];
    }];

  } else {
    [self displayGLAd:mTargetAdName];
  }
}

- (void) launchForAd:(NSString *)name
      withDurationMS:(NSNumber *)duration
        withTemplate:(NSString *)template {

  mTargetAdName = name;
  mTargetAdDuration = duration;
  mTargetAdTemplate = template;
}

/**
* This does a whole bunch of fun stuff. Initialises our JS VM/context/interface, and loads up the provided AJS
* library and ad logic in the context.
*
* Note that the JS VM/Context/Interface is only ever created once!
*/
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
  if(mJSVM == nil) { mJSVM = [[JSVirtualMachine alloc] init]; }
  if(mJSContext == nil) { mJSContext = [[JSContext alloc] initWithVirtualMachine:mJSVM]; }
  if(mJSInterface == nil) {
    mJSInterface = [[AdefyJSInterface alloc] init:mJSContext
                                     withRenderer:mRenderer
                             withAnimationManager:mAnimations];
  }

  [mJSContext evaluateScript:AJS];

  // We have to map param manually (no actual window, we partially fake it)
  [mJSContext evaluateScript:@"var param = window.param;"];
  [mJSContext evaluateScript:adLogic];
}

- (void)dealloc {

  [AdefySingleColorMaterial destroyShader];
  [AdefyTexturedMaterial destroyShader];

  if ([EAGLContext currentContext] == mContext) {
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];

  if ([self isViewLoaded] && ([[self view] window] == nil)) {
    self.view = nil;

    if ([EAGLContext currentContext] == mContext) {
      [EAGLContext setCurrentContext:nil];
    }

    mContext = nil;
  }

  // Dispose of any resources that can be recreated.
  [AdefySingleColorMaterial destroyShader];
  [AdefyTexturedMaterial destroyShader];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {

#if !MULTI_THREADED_PHYSICS

  // Update physics in three steps, to minimise tunnelling
  // If it's possible to unroll loops with a C pp #define, please let me know :)
  float dt = (float)[self timeSinceLastUpdate] / 3.0f;
  [mPhysics update:dt];
  [mPhysics update:dt];
  [mPhysics update:dt];
#endif

  [mAnimations update];
  [mRenderer update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  [mRenderer drawFrame:rect];
}

/**
* Does everything necessary to get an ad on-screen by name. This does nothing if the ad isn't found!
*/
- (void)displayGLAd:(NSString *)name {

  NSString *path = [mDownloader getPathForGLAd:name];

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

  // BOOOOOOOM
  [self executeAdLogic:path
             withLogic:adFile
               withAJS:AJSFile];
}

@end
