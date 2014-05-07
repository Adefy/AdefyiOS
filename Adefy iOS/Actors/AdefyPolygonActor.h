#import <Foundation/Foundation.h>
#import "AdefyActor.h"

@interface AdefyPolygonActor : AdefyActor
- (AdefyPolygonActor *)init:(int)id1 withRadius:(float)radius withSegments:(unsigned int)segments;

+ (unsigned int)getVertCount:(unsigned int)segments;
@end