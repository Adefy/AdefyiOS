//
//  AdefyActor.h
//  Adefy iOS
//
//  Created by Cris Mihalache on 08/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdefyActor : NSObject {

    @private
    BOOL visible;
    NSNumber *id;
}

-(void) setVisible:(BOOL)isVisible;

-(BOOL) getVisible;
-(NSNumber *) getId;

@end
