#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class AdefyRenderer;

@interface AdefyJSInterface : NSObject

- (AdefyJSInterface *)init:(JSContext *)context
              withRenderer:(AdefyRenderer *)renderer;

@end