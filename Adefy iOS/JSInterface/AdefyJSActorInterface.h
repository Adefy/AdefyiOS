#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class AdefyRenderer;

@protocol AdefyJSActorInterfaceExports <JSExport>

JSExportAs(destroyActor, - (BOOL) destroyActor:(int)id);

JSExportAs(createRectangleActor,
- (int) createRectangleActor:(float)width
                      height:(float)height);

JSExportAs(createCircleActor, - (int) createCircleActor:(float)radius);

JSExportAs(createTextActor,
- (int) createTextActor:(NSString *)text
                   size:(int)size
                      r:(int)r
                      g:(int)g
                      b:(int)b);

JSExportAs(createPolygonActor,
- (int)createPolygonActor:(float)radius
                 segments:(unsigned int)segments);

JSExportAs(attachTexture,
- (BOOL) attachTexture:(NSString *)texture
                 width:(float)width
                height:(float)height
                     x:(float)x
                     y:(float)y
                 angle:(float)angle
                    id:(int)id);

JSExportAs(removeAttachment, - (BOOL) removeAttachment:(int)id);
JSExportAs(setAttachmentVisibility, - (BOOL) setAttachmentVisibility:(BOOL)visible id:(int)id);

JSExportAs(setActorLayer, - (BOOL) setActorLayer:(int)layer id:(int)id);
JSExportAs(setActorPhysicsLayer, - (BOOL) setActorPhysicsLayer:(int)layer id:(int)id);
JSExportAs(setPhysicsVertices, - (BOOL) setPhysicsVertices:(NSString *)verts id:(int)id);
JSExportAs(setRenderMode, - (BOOL) setRenderMode:(unsigned int)mode id:(int)id);

JSExportAs(updateVertices, - (BOOL) updateVertices:(NSString *)verts id:(int)id);
JSExportAs(setActorPosition, - (BOOL) setActorPosition:(float)x y:(float)y id:(int)id);
JSExportAs(setActorRotation, - (BOOL) setActorRotation:(float)angle id:(int)id radians:(BOOL)radians);
JSExportAs(setActorColor, - (BOOL) setActorColor:(int)r g:(int)g b:(int)b id:(int)id);
JSExportAs(setActorTexture, - (BOOL) setActorTexture:(NSString *)name id:(int)id);

JSExportAs(getVertices, - (NSString *) getVertices:(int)id);
JSExportAs(getActorPosition, - (NSString *) getActorPosition:(int)id);
JSExportAs(getActorColor, - (NSString *) getActorColor:(int)id);
JSExportAs(getActorRotation, - (float) getActorRotation:(int)id);

JSExportAs(destroyPhysicsBody, - (BOOL) destroyPhysicsBody:(int)id);
JSExportAs(enableActorPhysics,
- (BOOL) enableActorPhysics:(float)mass
                   friction:(float)friction
                 elasticity:(float)elasticity
                         id:(int)id);

@end

@interface AdefyJSActorInterface : NSObject <AdefyJSActorInterfaceExports>

- (AdefyJSActorInterface *)init:(AdefyRenderer *)renderer;

@end