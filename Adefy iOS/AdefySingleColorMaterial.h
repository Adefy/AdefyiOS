//
// Created by Cris Mihalache on 09/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "AdefyMaterial.h"

@class AdefyColor3;

@interface AdefySingleColorMaterial : AdefyMaterial

-(void)setColor:(AdefyColor3 *)color;
-(AdefyColor3 *)getColor;

@end