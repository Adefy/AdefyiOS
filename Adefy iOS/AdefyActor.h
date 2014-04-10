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

-(AdefyActor *)init:(int)id
       withRenderer:(AdefyRenderer *)renderer
       withVertices:(GLfloat *)vertices;

-(void) setVisible:(BOOL)isVisible;
-(void) setVertices:(GLfloat *)vertices;

-(NSString *)getMaterialName;
-(AdefyMaterial *)getMaterial;
-(BOOL) getVisible;
-(int) getId;

-(void) draw:(GLKMatrix4)projection;

@end
