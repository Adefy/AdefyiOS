// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

#include <stdarg.h>

#include "ObjectiveChipmunk.h"


@implementation NSArray(ChipmunkObject)

-(id<NSFastEnumeration>)chipmunkObjects
{
	return self;
}

@end


NSSet * ChipmunkObjectFlatten(id <ChipmunkObject> firstObject, ...)
{
	NSSet *result = [NSSet set];
	va_list args;
	va_start(args, firstObject);
		for(id <ChipmunkObject> obj = firstObject; obj != nil; obj = va_arg(args, id)){
			result = [result setByAddingObjectsFromSet:(NSSet *)[obj chipmunkObjects]];
		}
	va_end(args);

	return result;
}
