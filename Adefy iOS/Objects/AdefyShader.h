#import <Foundation/Foundation.h>

@interface AdefyShader : NSObject

+ (BOOL)compileShader:(GLuint *)shader
                type:(GLenum)type
                name:(NSString *)name
                 ext:(NSString *)ext;

+ (BOOL)linkProgram:(GLuint)prog;

+ (BOOL)buildProgram:(GLuint *)prog
           withVert:(NSString *)vert
           withFrag:(NSString *)frag;

@end
