#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface AdefyViewController : GLKViewController

- (void)launchForAd:(NSString *)name withDurationMS:(NSNumber *)duration withTemplate:(NSString *)template;
@end
