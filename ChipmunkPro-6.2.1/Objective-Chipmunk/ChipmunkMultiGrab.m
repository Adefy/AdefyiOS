// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

#import "ChipmunkMultiGrab.h"


// A constraint subclass that tracks a grab point
@interface ChipmunkGrab() <ChipmunkObject>

@property(nonatomic, readwrite) cpVect pos;
@property(nonatomic, readonly) NSArray *chipmunkObjects;

@end


@implementation ChipmunkGrab

@synthesize pos = _pos;
@synthesize chipmunkObjects = _chipmunkObjects;
@synthesize grabbedShape = _grabbedShape;
@synthesize data = _data;

static void 
GrabPreSolve(cpConstraint *constraint, cpSpace *space)
{
	cpBody *grabBody = cpConstraintGetA(constraint);
	ChipmunkGrab *grab = [ChipmunkConstraint constraintFromCPConstraint:constraint].data;
	cpFloat dt = cpSpaceGetCurrentTimeStep(space);
	cpFloat coef = cpfpow(grab->_smoothing, dt);
	
	// Smooth out the mouse position.
	cpVect pos = cpvlerp(grab->_pos, cpBodyGetPos(grabBody), coef);
	cpBodySetVel(grabBody, cpvmult(cpvsub(pos, cpBodyGetPos(grabBody)), 1.0/dt));
	cpBodySetPos(grabBody, pos);
}

// Body will be nil if no object was grabbed.
-(id)initWithMultiGrab:(ChipmunkMultiGrab *)multiGrab pos:(cpVect)pos nearest:(cpVect)nearest
	body:(ChipmunkBody *)body grabbedShape:(ChipmunkShape *)grabbedShape
	chipmunkObjects:(NSArray *)chipmunkObjects;
{
	ChipmunkBody *grabBody = [ChipmunkBody bodyWithMass:INFINITY andMoment:INFINITY];
	grabBody.pos = pos;
	
	if((self = [super init])){
		_pos = pos;
		_smoothing = multiGrab.smoothing;
		_grabbedShape = grabbedShape;
		
		if(body){
			ChipmunkPivotJoint *pivot = [ChipmunkPivotJoint pivotJointWithBodyA:grabBody bodyB:body anchr1:cpvzero anchr2:[body world2local:nearest]];
			pivot.maxForce = multiGrab.grabForce;
			pivot.data = self;
			cpConstraintSetPreSolveFunc(pivot.constraint, GrabPreSolve);
			chipmunkObjects = [chipmunkObjects arrayByAddingObject:pivot];
			
			if(grabbedShape){
				cpFloat frictionForce = multiGrab.grabFriction;
				if(frictionForce > 0.0 && (1.0/body.mass + 1.0/grabBody.mass != 0.0)){
					ChipmunkPivotJoint *friction = [ChipmunkPivotJoint pivotJointWithBodyA:grabBody bodyB:body anchr1:cpvzero anchr2:[body world2local:nearest]];
					friction.maxForce = frictionForce;
					friction.maxBias = 0.0;
					chipmunkObjects = [chipmunkObjects arrayByAddingObject:friction];
				}
				
				cpFloat rotaryFriction = multiGrab.grabRotaryFriction;
				if(rotaryFriction > 0.0 && (1.0/body.moment + 1.0/grabBody.moment != 0.0)){
					ChipmunkGearJoint *friction = [ChipmunkGearJoint gearJointWithBodyA:grabBody bodyB:body phase:0.0 ratio:1.0];
					friction.maxForce = rotaryFriction;
					friction.maxBias = 0.0;
					chipmunkObjects = [chipmunkObjects arrayByAddingObject:friction];
				}
			}
			
			_chipmunkObjects = [chipmunkObjects retain];
		}
	}
	
	return self;
}

-(void)dealloc
{
	[_chipmunkObjects release]; _chipmunkObjects = nil;
	[super dealloc];
}

@end


@implementation ChipmunkMultiGrab

@synthesize grabForce = _grabForce;
@synthesize smoothing = _smoothing;

@synthesize layers = _layers, group = _group;
@synthesize grabFilter = _grabFilter;
@synthesize grabSort = _grabSort;

@synthesize grabFriction = _grabFriction, grabRotaryFriction = _grabRotaryFriction;
@synthesize grabRadius = _grabRadius;

@synthesize pullMode = _pullMode, pushMode = _pushMode;

@synthesize pushMass = _pushMass;
@synthesize pushFriction = _pushFriction, pushElasticity = _pushElasticity;
@synthesize pushCollisionType = _pushCollisionType;

-(id)initForSpace:(ChipmunkSpace *)space withSmoothing:(cpFloat)smoothing withGrabForce:(cpFloat)grabForce;
{
	if((self = [super init])){
		_space = [space retain];
		_grabs = [[NSMutableArray alloc] init];
		
		_smoothing = smoothing;
		_grabForce = grabForce;
		
		_layers = CP_ALL_LAYERS;
		_group = CP_NO_GROUP;
		
		_grabFilter = ^(ChipmunkShape *shape){return (bool)TRUE;};
		_grabSort = ^(ChipmunkShape *shape, cpFloat depth){return depth;};
		
		_pullMode = TRUE;
		_pushMode = FALSE;
	}
	
	return self;
}

-(void)dealloc
{
	[_space release];
	[_grabs release];
	
	[super dealloc];
}

// Don't integrate push bodies.
static void PushBodyVelocityUpdate(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt){}

-(ChipmunkGrab *)beginLocation:(cpVect)pos;
{
	__block cpFloat min = INFINITY;
	__block cpVect nearest = pos;
	__block ChipmunkShape *grabbedShape = nil;
	
	if(_pullMode){
		cpSpaceNearestPointQuery_b(_space.space, pos, _grabRadius, _layers, _group, ^(cpShape *c_shape, cpFloat dist, cpVect point){
			ChipmunkShape *shape = [ChipmunkShape shapeFromCPShape:c_shape];
			cpFloat sort = dist;
			
			// Call the sorting callback if dist is negative.
			// Otherwise just take the nearest shape.
			if(dist <= 0.0f){
				sort = -_grabSort(shape, -dist);
				cpAssertWarn(sort <= 0.0f, "You must return a positive value from the sorting callback.");
			}
			
			if(sort < min && cpBodyGetMass(cpShapeGetBody(c_shape)) != INFINITY){
				if(_grabFilter(shape)){
					min = sort;
					nearest = (dist > 0.0 ? point : pos);
					grabbedShape = shape;
				}
			}
		});
	}
	
	ChipmunkBody *pushBody = nil;
	NSArray *chipmunkObjects = [NSArray array];
	
	if(!grabbedShape && _pushMode){
		pushBody = [ChipmunkBody bodyWithMass:_pushMass andMoment:INFINITY];
		pushBody.pos = pos;
		pushBody.body->velocity_func = PushBodyVelocityUpdate;
		
		ChipmunkShape *pushShape = [ChipmunkCircleShape circleWithBody:pushBody radius:_grabRadius offset:cpvzero];
		pushShape.friction = _pushFriction;
		pushShape.elasticity = _pushElasticity;
		pushShape.layers = _layers;
		pushShape.group = _group;
		pushShape.collisionType = _pushCollisionType;
		
		chipmunkObjects = [NSArray arrayWithObjects:pushBody, pushShape, nil];
	}
	
	ChipmunkBody *grabBody = (grabbedShape ? grabbedShape.body : pushBody);
	ChipmunkGrab *grab = [[ChipmunkGrab alloc] initWithMultiGrab:self pos:pos nearest:nearest body:grabBody grabbedShape:grabbedShape chipmunkObjects:chipmunkObjects];
	
	[_grabs addObject:grab];
	[_space add:grab];
	[grab release];
	
	return (grab.grabbedShape ? grab : nil);
}

static ChipmunkGrab *
BestGrab(NSArray *grabs, cpVect pos)
{
	ChipmunkGrab *match = nil;
	cpFloat best = INFINITY;
	
	for(ChipmunkGrab *grab in grabs){
		cpFloat dist = cpvdistsq(pos, grab.pos);
		if(dist < best){
			match = grab;
			best = dist;
		}
	}
	
	return match;
}

-(ChipmunkGrab *)updateLocation:(cpVect)pos;
{
	ChipmunkGrab *grab = BestGrab(_grabs, pos);
	grab.pos = pos;
	
	return (grab.grabbedShape ? grab : nil);
}

-(ChipmunkGrab *)endLocation:(cpVect)pos;
{
	cpAssertHard([_grabs count] != 0, "Grab set is already empty!");
	ChipmunkGrab *grab = BestGrab(_grabs, pos);
	[grab retain];
	
	[_space remove:grab];
	[_grabs removeObject:grab];
	
	[grab autorelease];
	return (grab.grabbedShape ? grab : nil);
}

-(NSArray *)grabs
{
	NSMutableArray *grabs = [NSMutableArray array];
	for(ChipmunkGrab *grab in _grabs){
		if(grab.grabbedShape) [grabs addObject:grab];
	}
	
	return grabs;
}

@end
