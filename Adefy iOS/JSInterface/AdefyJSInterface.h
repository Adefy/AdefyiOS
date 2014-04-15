#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface AdefyJSInterface : NSObject

+ (void) registerInterface:(JSContext *)context;

@end