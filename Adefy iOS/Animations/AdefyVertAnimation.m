#import "AdefyVertAnimation.h"

@implementation AdefyVertAnimation {

}

+ (BOOL) canAnimate:(NSArray *)properties {

  NSString *prop1 = [properties objectAtIndex:0];

  return [prop1 isEqualToString:@"vertices"];
}

@end