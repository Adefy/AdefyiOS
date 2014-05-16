#import <Foundation/Foundation.h>
#import "AdefyMaterial.h"

@interface AdefyTexturedMaterial : AdefyMaterial

+ (NSString *)getName;
- (AdefyTexturedMaterial *)init:(GLuint)handle
                          withU:(GLfloat)U
                          withV:(GLfloat)V;

- (void)setTextureHandle:(GLuint)handle;
- (void)setUScale:(GLfloat)U;
- (void)setVScale:(GLfloat)V;

- (void) draw:(GLKMatrix4)projection
   withModelV:(GLKMatrix4)modelView
withIndiceBuffer:(GLuint)indiceBuffer
withVertCount:(GLuint)vertCount
     withMode:(GLenum)mode;

@end