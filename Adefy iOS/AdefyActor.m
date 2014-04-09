//
//  AdefyActor.m
//  Adefy iOS
//
//  Created by Cris Mihalache on 08/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import "AdefyActor.h"

@implementation AdefyActor {
    
    BOOL visible;
    int id;
}

-(void) setVisible:(BOOL)isVisible {
    visible = isVisible;
}

-(BOOL) getVisible {
    return visible;
}

-(int)getId {
    return id;
}

@end
