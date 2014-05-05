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

- (void)draw:(GLKMatrix4)projection
  withModelV:(GLKMatrix4)modelView
    withVerts:(GLuint *)vertBuffer
withVertCount:(int)vertCount
withTexCoords:(GLuint *)texCoordBuffer
withTexCCount:(int)texCount
     withMode:(GLenum)mode;

@end