#import <Foundation/Foundation.h>

@interface AdefyColor3 : NSObject

-(float *)toFloatArray;
-(void)copyToFloatArray:(float *)array;

-(void)setR:(int)r;
-(void)setG:(int)g;
-(void)setB:(int)b;

-(AdefyColor3 *)init:(int)r withG:(int)g withB:(int)b;
-(AdefyColor3 *)init:(float)r withGF:(float)g withBF:(float)b;

@end
