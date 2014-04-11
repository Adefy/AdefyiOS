#import <Foundation/Foundation.h>

@class AdefyMaterial;
@class AdefyRenderer;

@interface AdefyActor : NSObject

-(AdefyActor *)init:(int)id
           renderer:(AdefyRenderer *)renderer
           vertices:(GLfloat *)vertices
              count:(int)count;

-(void) setVisible:(BOOL)isVisible;
-(void) setVertices:(GLfloat *)vertices
              count:(int)count;

-(NSString *)getMaterialName;
-(AdefyMaterial *)getMaterial;
-(BOOL) getVisible;
-(int) getId;

-(void) draw:(GLKMatrix4)projection;

@end
