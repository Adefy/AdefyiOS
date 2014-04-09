//
//  AdefyRenderer.m
//  Adefy iOS
//
//  Created by Cris Mihalache on 09/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefyRenderer.h"

@implementation AdefyRenderer

static float PPM;

+(void) initialize {
    PPM = 128.0f;
}

+(float) getPPM { return PPM; }
+(float) getMPP { return 1.0f / PPM; }

-(AdefyRenderer *) init {
    self = [super init];
    
    [self setFPS:60];
    
    return self;
}

-(void) setFPS:(int)fps {
    targetFPS = fps;
    targetFrameTime = 1000 / fps;
}

@end
