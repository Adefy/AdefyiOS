#import <Foundation/Foundation.h>

@interface AdefyMaterial : NSObject

+ (void)setVertSource:(NSString *)src;
+ (void)setFragSource:(NSString *)src;

+ (NSString *)getVertSource;
+ (NSString *)getFragSource;

+ (void)buildShader;
+ (BOOL)wasJustUsed;

+ (void)setJustUsed:(BOOL)used;
+ (void)postFinalDraw;
+ (void)destroyShader;

- (NSString *) getName;
- (GLuint) getShader;

- (void)glErrorCheck:(NSString *)desc;

@end
