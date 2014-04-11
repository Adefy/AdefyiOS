//
// Created by Cris Mihalache on 11/04/14.
// Copyright (c) 2014 Adefy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdefyActor.h"

@class AdefyRenderer;

@interface AdefyRectangleActor : AdefyActor

- (AdefyRectangleActor *)init:(int)id
                     renderer:(AdefyRenderer *)renderer
                        width:(float)width
                       height:(float)height;

- (void)setWidth:(float)width;
- (void)setHeight:(float)height;

- (float)getWidth;
- (float)getHeight;

@end