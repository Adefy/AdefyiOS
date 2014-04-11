#import <Foundation/Foundation.h>
#import "AdefyActor.h"

@class AdefyRenderer;

@interface AdefyRectangleActor : AdefyActor

- (AdefyRectangleActor *)init:(int)id
                        width:(float)width
                       height:(float)height;

- (void)setWidth:(float)width;
- (void)setHeight:(float)height;

- (float)getWidth;
- (float)getHeight;

@end