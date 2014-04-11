#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "AdefyMaterial.h"

@class AdefyColor3;

@interface AdefySingleColorMaterial : AdefyMaterial

- (void)setColor:(AdefyColor3 *)color;
- (AdefyColor3 *)getColor;

@end
