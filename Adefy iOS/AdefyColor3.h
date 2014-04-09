//
// Created by Cris Mihalache on 09/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

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