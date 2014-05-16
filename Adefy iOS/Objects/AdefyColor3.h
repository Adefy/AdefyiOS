#import <Foundation/Foundation.h>

@interface AdefyColor3 : NSObject

-(float *)toFloatArray;
-(void)copyToFloatArray:(float *)array;

-(void)setR:(GLubyte)r;
-(void)setG:(GLubyte)g;
-(void)setB:(GLubyte)b;
-(void)setA:(GLubyte)a;

-(GLubyte)getR;
-(GLubyte)getG;
-(GLubyte)getB;
-(GLubyte)getA;

-(AdefyColor3 *)init:(GLubyte)r
               withG:(GLubyte)g
               withB:(GLubyte)b;

-(AdefyColor3 *)init:(float)r
              withGF:(float)g
              withBF:(float)b;

@end
