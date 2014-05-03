#import "AdefyJSEngineInterface.h"

@implementation AdefyJSEngineInterface {

}
- (void)initialize:(NSString *)ad width:(int)width height:(int)height logLevel:(int)logLevel id:(NSString *)id1 {

}

- (NSString *)getClearColor {
  return nil;
}

- (void)setClearColor:(float)r g:(float)g b:(float)b {

}

- (void)setRemindMeButton:(float)x y:(float)y width:(float)width height:(float)height {

}

- (void)setLogLevel:(int)level {

}

- (NSString *)getCameraPosition {
  return nil;
}

- (void)setCameraPosition:(float)x y:(float)y {

}

- (void)triggerEnd {

}

- (void)setOrientation:(NSString *)orientation {

}

- (void)log:(NSString *)string {
  NSLog(@"JS: %@", string);
}


@end