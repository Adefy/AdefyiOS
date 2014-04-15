#import <Foundation/Foundation.h>

@interface AdefyJSActorInterface : NSObject

+ (BOOL) destroyActor:(int)id;
+ (int) createPolygonActor:(NSString *)verts;

+ (int) createRectangleActor:(float)width
                      height:(float)height;

+ (int) createCircleActor:(float)radius
                    verts:(NSString *)verts;

+ (int) createTextActor:(NSString *)text
                   size:(int)size
                      r:(int)r
                      g:(int)g
                      b:(int)b;

+ (BOOL) attachTexture:(NSString *)texture
                 width:(float)width
                height:(float)height
                     x:(float)x
                     y:(float)y
                 angle:(float)angle
                    id:(int)id;

+ (BOOL) removeAttachment:(int)id;
+ (BOOL) setAttachmentVisibility:(BOOL)visible id:(int)id;

+ (BOOL) setActorLayer:(int)layer id:(int)id;
+ (BOOL) setActorPhysicsLayer:(int)layer id:(int)id;
+ (BOOL) setPhysicsVertices:(NSString *)verts id:(int)id;
+ (BOOL) setRenderMode:(int)layer id:(int)id;

+ (BOOL) updateVertices:(NSString *)verts id:(int)id;
+ (BOOL) setActorPosition:(float)x y:(float)y id:(int)id;
+ (BOOL) setActorRotation:(float)angle id:(int)id radians:(BOOL)radians;
+ (BOOL) setActorColor:(int)r g:(int)g b:(int)b id:(int)id;
+ (BOOL) setActorTexture:(NSString *)name id:(int)id;

+ (NSString *) getVertices:(int)id;
+ (NSString *) getActorPosition:(int)id;
+ (NSString *) getActorColor:(int)id;
+ (float) getActorRotation:(int)id;

+ (BOOL) destroyPhysicsBody:(int)id;
+ (BOOL) enableActorPhysics:(float)mass
                   friction:(float)friction
                 elasticity:(float)elasticity
                         id:(int)id;

@end