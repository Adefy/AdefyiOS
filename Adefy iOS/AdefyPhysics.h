#import <Foundation/Foundation.h>

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

@end