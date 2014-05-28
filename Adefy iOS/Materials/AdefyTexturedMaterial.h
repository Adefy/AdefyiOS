#import "AdefyMaterial.h"

@interface AdefyTexturedMaterial : AdefyMaterial

+ (void)initShader;

+ (NSString *)getName;
- (AdefyTexturedMaterial *)init;

- (void)setTextureHandle:(GLuint)handle;
- (void)setUScale:(GLfloat)U;
- (void)setVScale:(GLfloat)V;

- (void) draw:(GLKMatrix4)projection
   withModelV:(GLKMatrix4)modelView
withIndiceBuffer:(GLuint)indiceBuffer
withVertCount:(GLuint)vertCount
    withLayer:(GLint)layer
     withMode:(GLenum)mode;

@end