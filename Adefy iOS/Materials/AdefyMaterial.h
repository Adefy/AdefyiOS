#import <Foundation/Foundation.h>

@interface AdefyMaterial : NSObject

+ (void)setVertSource:(NSString *)src;
+ (void)setFragSource:(NSString *)src;
+ (void)setShader:(GLuint)shader;

+ (NSString *)getVertSource;
+ (NSString *)getFragSource;
+ (GLuint)getShader;

+ (void)buildShader;
+ (BOOL)wasJustUsed;

+ (void)setJustUsed:(BOOL)used;
+ (void)postFinalDraw;
+ (void)destroyShader;

- (NSString *) getName;
- (GLuint) getShader;

@end
