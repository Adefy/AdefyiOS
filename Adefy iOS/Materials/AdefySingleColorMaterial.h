#import <GLKit/GLKit.h>
#import "AdefyMaterial.h"

@class AdefyColor3;

@interface AdefySingleColorMaterial : AdefyMaterial

+ (void)initShader;

+ (NSString *)getName;

- (AdefySingleColorMaterial *)init:(AdefyColor3 *)withColor;

- (void)setColor:(AdefyColor3 *)color;
- (AdefyColor3 *)getColor;

- (void)draw:(GLKMatrix4)projection
  withModelV:(GLKMatrix4)modelView
    withIndiceBuffer:(GLuint)indiceBuffer
    withVertCount:(GLuint)vertCount
    withLayer:(GLint)layer
    withMode:(GLenum)mode;

@end
