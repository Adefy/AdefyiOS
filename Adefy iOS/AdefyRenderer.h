//
//  AdefyRenderer.h
//  Adefy iOS
//
//  Created by Cris Mihalache on 09/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdefyRenderer : NSObject {
    
    @private
    int targetFPS;
    int targetFrameTime;
}

-(void) setFPS:(int)fps;

@end
