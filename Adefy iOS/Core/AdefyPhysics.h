#import <Foundation/Foundation.h>

#define MULTI_THREADED_PHYSICS 0

@class ChipmunkShape;
@class ChipmunkBody;

@interface AdefyPhysics : NSObject

+ (void)setGlobalInstance:(AdefyPhysics *)instance;
+ (AdefyPhysics *)getGlobalInstance;

- (ChipmunkBody *)getStaticBody;
- (void)registerShape:(ChipmunkShape *)shape;
- (void)registerBody:(ChipmunkBody *)body;
- (void)removeShape:(ChipmunkShape *)shape;
- (void)removeBody:(ChipmunkBody *)body;

#if !MULTI_THREADED_PHYSICS
- (void)update:(float)dt;
#endif

@end