// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

#import "ObjectiveChipmunk.h"

@implementation ChipmunkShape

@synthesize data;

+(ChipmunkShape *)shapeFromCPShape:(cpShape *)shape;
{
	ChipmunkShape *obj = shape->data;
	cpAssertHard([obj isKindOfClass:[ChipmunkShape class]], "'shape->data' is not a pointer to a ChipmunkShape object.");
	
	return obj;
}

- (void) dealloc {
	[self.body release];
	cpShapeDestroy(self.shape);
	[super dealloc];
}


- (cpShape *)shape {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (ChipmunkBody *)body {
	cpBody *body = self.shape->body;
	return (body ? body->data : nil);
}

- (void)setBody:(ChipmunkBody *)value {
	if(self.body != value){
		[self.body release];
		self.shape->body = [[value retain] body];
	}
}

// accessor macros
#define getter(type, lower, upper, member) \
- (type)lower {return self.shape->member;}
#define setter(type, lower, upper, member) \
- (void)set##upper:(type)value {self.shape->member = value;};
#define both(type, lower, upper, member) \
getter(type, lower, upper, member) \
setter(type, lower, upper, member)

getter(cpBB, bb, BB, bb)
both(BOOL, sensor, Sensor, sensor)
both(cpFloat, elasticity, Elasticity, e)
both(cpFloat, friction, Friction, u)
both(cpVect, surfaceVel, SurfaceVel, surface_v)
both(cpCollisionType, collisionType, CollisionType, collision_type)
both(cpGroup, group, Group, group)
both(cpLayers, layers, Layers, layers)

-(ChipmunkSpace *)space {
	cpSpace *space = cpShapeGetSpace(self.shape);
	return (ChipmunkSpace *)(space ? cpSpaceGetUserData(space) : nil);
}

- (cpBB)cacheBB {return cpShapeCacheBB(self.shape);}

- (bool)pointQuery:(cpVect)point {
	return ([self nearestPointQuery:point].dist <= 0.0f);
}

- (ChipmunkNearestPointQueryInfo *)nearestPointQuery:(cpVect)point;
{
	cpNearestPointQueryInfo info;
	cpShapeNearestPointQuery(self.shape, point, &info);
	return [[[ChipmunkNearestPointQueryInfo alloc] initWithInfo:&info] autorelease];
}

- (ChipmunkSegmentQueryInfo *)segmentQueryFrom:(cpVect)start to:(cpVect)end;
{
	cpSegmentQueryInfo info;
	if(cpShapeSegmentQuery(self.shape, start, end, &info)){
		return [[[ChipmunkSegmentQueryInfo alloc] initWithInfo:&info start:start end:end] autorelease];
	} else {
		return nil;
	}
}


- (NSArray *)chipmunkObjects {return [NSArray arrayWithObject:self];}
- (void)addToSpace:(ChipmunkSpace *)space {[space addShape:self];}
- (void)removeFromSpace:(ChipmunkSpace *)space {[space removeShape:self];}

@end


@implementation ChipmunkNearestPointQueryInfo

- (id)initWithInfo:(cpNearestPointQueryInfo *)info;
{
	if((self = [super init])){
		_info = (*info);
		[self.shape retain];
	}
	
	return self;
}

- (cpNearestPointQueryInfo *)info {return &_info;}
- (ChipmunkShape *)shape {return (_info.shape ? _info.shape->data : nil);}
- (cpFloat)dist {return _info.d;}
- (cpVect)point {return _info.p;}

- (void)dealloc
{
	[self.shape release];
	[super dealloc];
}


@end


@implementation ChipmunkSegmentQueryInfo

- (id)initWithInfo:(cpSegmentQueryInfo *)info start:(cpVect)start end:(cpVect)end;
{
	if((self = [super init])){
		_info = (*info);
		_start = start;
		_end = end;
		
		[self.shape retain];
	}
	
	return self;
}

- (cpSegmentQueryInfo *)info {return &_info;}
- (ChipmunkShape *)shape {return (_info.shape ? _info.shape->data : nil);}
- (cpFloat)t {return _info.t;}
- (cpVect)normal {return _info.n;}
- (cpVect)point {return cpSegmentQueryHitPoint(_start, _end, _info);}
- (cpFloat)dist {return cpSegmentQueryHitDist(_start, _end, _info);}
- (cpVect)start {return _start;}
- (cpVect)end {return _end;}

- (void)dealloc
{
	[self.shape release];
	[super dealloc];
}


@end


@implementation ChipmunkShapeQueryInfo

@synthesize shape = _shape;
- (cpContactPointSet *)contactPoints {return &_contactPoints;}

- (id)initWithShape:(ChipmunkShape *)shape andPoints:(cpContactPointSet *)set;
{
	if((self = [super init])){
		_shape = [shape retain];
		_contactPoints = *set;
	}
	
	return self;
}

- (void)dealloc {
	[_shape release];
	[super dealloc];
}

@end

@implementation ChipmunkCircleShape

+ (ChipmunkCircleShape *)circleWithBody:(ChipmunkBody *)body radius:(cpFloat)radius offset:(cpVect)offset;
{
	return [[[self alloc] initWithBody:body radius:radius offset:offset] autorelease];
}

- (cpShape *)shape {return (cpShape *)&_shape;}

- (id)initWithBody:(ChipmunkBody *)body radius:(cpFloat)radius offset:(cpVect)offset {
	if((self = [super init])){
		[body retain];
		cpCircleShapeInit(&_shape, body.body, radius, offset);
		self.shape->data = self;
	}
	
	return self;
}

- (cpFloat)radius {return cpCircleShapeGetRadius((cpShape *)&_shape);}
- (cpVect)offset {return cpCircleShapeGetOffset((cpShape *)&_shape);}

@end


@implementation ChipmunkSegmentShape

+ (ChipmunkSegmentShape *)segmentWithBody:(ChipmunkBody *)body from:(cpVect)a to:(cpVect)b radius:(cpFloat)radius;
{
	return [[[self alloc] initWithBody:body from:a to:b radius:radius] autorelease];
}

- (cpShape *)shape {return (cpShape *)&_shape;}

- (id)initWithBody:(ChipmunkBody *)body from:(cpVect)a to:(cpVect)b radius:(cpFloat)radius {
	if((self = [super init])){
		[body retain];
		cpSegmentShapeInit(&_shape, body.body, a, b, radius);
		self.shape->data = self;
	}
	
	return self;
}

- (void)setPrevNeighbor:(cpVect)prev nextNeighbor:(cpVect)next;
{
	cpSegmentShapeSetNeighbors((cpShape *)&_shape, prev, next);
}

- (cpVect)a {return cpSegmentShapeGetA((cpShape *)&_shape);}
- (cpVect)b {return cpSegmentShapeGetB((cpShape *)&_shape);}
- (cpVect)normal {return cpSegmentShapeGetNormal((cpShape *)&_shape);}
- (cpFloat)radius {return cpSegmentShapeGetRadius((cpShape *)&_shape);}

@end


@implementation ChipmunkPolyShape

+ (ChipmunkPolyShape *)polyWithBody:(ChipmunkBody *)body count:(int)count verts:(const cpVect *)verts offset:(cpVect)offset;
{
	return [[[self alloc] initWithBody:body count:count verts:verts offset:offset] autorelease];
}

+ (id)polyWithBody:(ChipmunkBody *)body count:(int)count verts:(const cpVect *)verts offset:(cpVect)offset radius:(cpFloat)radius;
{
	return [[[self alloc] initWithBody:body count:count verts:verts offset:offset radius:radius] autorelease];
}

+ (id)boxWithBody:(ChipmunkBody *)body width:(cpFloat)width height:(cpFloat)height;
{
	return [[[self alloc] initBoxWithBody:body width:width height:height] autorelease];
}

+ (id)boxWithBody:(ChipmunkBody *)body bb:(cpBB)bb;
{
	return [[[self alloc] initBoxWithBody:body bb:bb] autorelease];
}

+ (id)boxWithBody:(ChipmunkBody *)body bb:(cpBB)bb radius:(cpFloat)radius;
{
	return [[[self alloc] initBoxWithBody:body bb:bb radius:radius] autorelease];
}

- (cpShape *)shape {return (cpShape *)&_shape;}

- (id)initWithBody:(ChipmunkBody *)body count:(int)count verts:(const cpVect *)verts offset:(cpVect)offset
{
	if((self = [super init])){
		[body retain];
		cpPolyShapeInit(&_shape, body.body, count, verts, offset);
		self.shape->data = self;
	}
	
	return self;
}

- (id)initWithBody:(ChipmunkBody *)body count:(int)count verts:(const cpVect *)verts offset:(cpVect)offset radius:(cpFloat)radius
{
	if((self = [super init])){
		[body retain];
		cpPolyShapeInit2(&_shape, body.body, count, verts, offset, radius);
		self.shape->data = self;
	}
	
	return self;
}

- (id)initBoxWithBody:(ChipmunkBody *)body width:(cpFloat)width height:(cpFloat)height;
{
	if((self = [super init])){
		[body retain];
		cpBoxShapeInit(&_shape, body.body, width, height);
		self.shape->data = self;
	}
	
	return self;
}

- (id)initBoxWithBody:(ChipmunkBody *)body bb:(cpBB)bb;
{
	if((self = [super init])){
		[body retain];
		cpBoxShapeInit2(&_shape, body.body, bb);
		self.shape->data = self;
	}
	
	return self;
}

- (id)initBoxWithBody:(ChipmunkBody *)body bb:(cpBB)bb radius:(cpFloat)radius;
{
	if((self = [super init])){
		[body retain];
		cpBoxShapeInit3(&_shape, body.body, bb, radius);
		self.shape->data = self;
	}
	
	return self;
}

- (int)count {return cpPolyShapeGetNumVerts((cpShape *)&_shape);}
- (cpFloat)radius {return cpPolyShapeGetRadius((cpShape *)&_shape);}
- (cpVect)getVertex:(int)index {return cpPolyShapeGetVert((cpShape *)&_shape, index);}

@end

@implementation ChipmunkStaticCircleShape : ChipmunkCircleShape
- (void)addToSpace:(ChipmunkSpace *)space {[space addStaticShape:self];}
- (void)removeFromSpace:(ChipmunkSpace *)space {[space removeStaticShape:self];}
@end

@implementation ChipmunkStaticSegmentShape : ChipmunkSegmentShape
- (void)addToSpace:(ChipmunkSpace *)space {[space addStaticShape:self];}
- (void)removeFromSpace:(ChipmunkSpace *)space {[space removeStaticShape:self];}
@end

@implementation ChipmunkStaticPolyShape : ChipmunkPolyShape
- (void)addToSpace:(ChipmunkSpace *)space {[space addStaticShape:self];}
- (void)removeFromSpace:(ChipmunkSpace *)space {[space removeStaticShape:self];}
@end
