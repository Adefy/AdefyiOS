#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class AdefyRenderer;
@class AdefyAnimationManager;

@interface AdefyJSInterface : NSObject

- (AdefyJSInterface *)init:(JSContext *)context
              withRenderer:(AdefyRenderer *)renderer
      withAnimationManager:(AdefyAnimationManager *)manager;

@end