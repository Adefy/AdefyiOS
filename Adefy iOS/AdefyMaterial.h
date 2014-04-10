//
// Created by Cris Mihalache on 09/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AdefyMaterial : NSObject

+(void)setVertSource:(NSString *)src;
+(void)setFragSource:(NSString *)src;
+(void)setShader:(GLuint)shader;

+(NSString *)getVertSource;
+(NSString *)getFragSource;
+(GLuint)getShader;

+(void)buildShader;
+(BOOL)wasJustUsed;

+(void)setJustUsed:(BOOL)used;
+(void)postFinalDraw;
+ (void)destroyShader;

-(NSString *) getName;
-(GLuint) getShader;

-(void)draw:(GLKMatrix4)projection
    modelView:(float *)modelView
        verts:(GLuint *)vertBuffer
    vertCount:(int)vertCount
         mode:(GLenum)mode;

@end