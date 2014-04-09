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

-(NSString *) getName;
-(GLuint) getShader;

-(void)draw:(GLKMatrix4)projection
    withModelView:(float *)modelView
    withVerts:(float *)vertBuffer
    withMode:(int)mode
    withVertCount:(int)vertCount;

@end