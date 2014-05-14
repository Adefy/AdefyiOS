#import <Foundation/Foundation.h>
#import "AdefyAnimation.h"
#import "chipmunk.h"

@class AdefyActor;
@class AdefyAnimationManager;

@interface AdefyBezAnimation : AdefyAnimation

- (AdefyBezAnimation *)init:(AdefyActor *)_actor
                   endValue:(double)_end
                        cp1:(cpVect *)_cp1
                        cp2:(cpVect *)_cp2
                   duration:(double)_duration
                   property:(NSString *)_prop
                  component:(NSString *)_comp
                        fps:(int)_fps
                withManager:(AdefyAnimationManager *)manager;

- (BOOL)isDone;

+ (BOOL)canAnimate:(NSArray *)properties;
@end