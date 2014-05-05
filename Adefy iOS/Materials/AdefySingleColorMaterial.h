#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "AdefyMaterial.h"

@class AdefyColor3;

@interface AdefySingleColorMaterial : AdefyMaterial

+ (NSString *)getName;

- (AdefySingleColorMaterial *)init:(AdefyColor3 *)withColor;

- (void)setColor:(AdefyColor3 *)color;
- (AdefyColor3 *)getColor;

- (void)draw:(GLKMatrix4)projection
   modelView:(GLKMatrix4)modelView
       verts:(GLuint *)vertBuffer
   vertCount:(int)vertCount
        mode:(GLenum)mode;

@end
