//
//  AdefyActor.h
//  Adefy iOS
//
//  Created by Cris Mihalache on 08/04/14.
//  Copyright (c) 2014 Adefy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AdefyMaterial;

@interface AdefyActor : NSObject

-(void) setVisible:(BOOL)isVisible;

-(NSString *)getMaterialName;
-(AdefyMaterial *)getMaterial;
-(BOOL) getVisible;
-(int) getId;

-(void) draw:(GLKMatrix4)projection;

@end
