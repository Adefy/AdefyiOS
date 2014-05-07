#import <Foundation/Foundation.h>

@interface AdefyTexture : NSObject

- (AdefyTexture *)init:(NSString *)_name
            withHandle:(int)_handle
             withClipU:(float)_u
             withClipV:(float)_v;

- (NSString *)getName;
- (GLuint)getHandle;
- (float)getClipScaleU;
- (float)getClipScaleV;

@end