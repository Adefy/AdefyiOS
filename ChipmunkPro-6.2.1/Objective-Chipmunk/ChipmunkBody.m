// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

#import "ObjectiveChipmunk.h"

@implementation ChipmunkBody

// MARK: Integration Helpers

-(void)updateVelocity:(cpFloat)dt gravity:(cpVect)gravity damping:(cpFloat)damping
{
	cpBodyUpdateVelocity(&_body, gravity, damping, dt);
}

-(void)updatePosition:(cpFloat)dt
{
	cpBodyUpdatePosition(&_body, dt);
}

static void
VelocityFunction
(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	[(ChipmunkBody *)body->data updateVelocity:dt gravity:gravity damping:damping];
}

static void
PositionFunction
(cpBody *body, cpFloat dt)
{
	[(ChipmunkBody *)body->data updatePosition:dt];
}

// Check if the method was overridden.
// No reason to add the extra method overhead if it's not needed.
-(BOOL)methodIsOverriden:(SEL)selector
{
	return ([self methodForSelector:selector] != [[ChipmunkBody class] instanceMethodForSelector:selector]);
}

// MARK: Constructors

+(ChipmunkBody *)bodyFromCPBody:(cpBody *)body
{	
	ChipmunkBody *obj = body->data;
	cpAssertHard([obj isKindOfClass:[ChipmunkBody class]], "'body->data' is not a pointer to a ChipmunkBody object.");
	
	return obj;
}

+ (id)bodyWithMass:(cpFloat)mass andMoment:(cpFloat)moment;
{
	return [[[self alloc] initWithMass:mass andMoment:moment] autorelease];
}

+ (id)staticBody;
{
	return [[[self alloc] initStaticBody] autorelease];
}

- (id)initWithMass:(cpFloat)mass andMoment:(cpFloat)moment;
{
	if((self = [super init])){
		cpBodyInit(&_body, mass, moment);
		_body.data = self;
		
		// Setup integration callbacks if necessary.
		if([self methodIsOverriden:@selector(updateVelocity:gravity:damping:)]){
			_body.velocity_func = VelocityFunction;
		}
		
		if([self methodIsOverriden:@selector(updatePosition:)]){
			_body.position_func = PositionFunction;
		}
	}
	
	return self;
}

- (id)initStaticBody;
{
	if((self = [super init])){
		cpBodyInitStatic(&_body);
		_body.data = self;
	}
	
	return self;
}

- (void) dealloc;
{
	cpBodyDestroy(&_body);
	[super dealloc];
}


- (cpBody *)body {return &_body;}


@synthesize data;

// accessor macros
#define getter(type, lower, upper) \
- (type)lower {return cpBodyGet##upper(&_body);}
#define setter(type, lower, upper) \
- (void)set##upper:(type)value {cpBodySet##upper(&_body, value);};
#define both(type, lower, upper) \
getter(type, lower, upper) \
setter(type, lower, upper)


both(cpFloat, mass, Mass)
both(cpFloat, moment, Moment)
both(cpVect, pos, Pos)
both(cpVect, vel, Vel)
both(cpVect, force, Force)
both(cpFloat, angle, Angle)
both(cpFloat, angVel, AngVel)
both(cpFloat, torque, Torque)
getter(cpVect, rot, Rot)
both(cpFloat, velLimit, VelLimit);
both(cpFloat, angVelLimit, AngVelLimit);

-(ChipmunkSpace *)space {
	cpSpace *space = cpBodyGetSpace(&_body);
	return (ChipmunkSpace *)(space ? cpSpaceGetUserData(space) : nil);
}

- (cpFloat)kineticEnergy {return cpBodyKineticEnergy(&_body);}

- (cpVect)local2world:(cpVect)v {return cpBodyLocal2World(&_body, v);}
- (cpVect)world2local:(cpVect)v {return cpBodyWorld2Local(&_body, v);}

- (cpVect)velocityAtLocalPoint:(cpVect)p {return cpBodyGetVelAtLocalPoint(&_body, p);}
- (cpVect)velocityAtWorldPoint:(cpVect)p {return cpBodyGetVelAtWorldPoint(&_body, p);}

- (void)resetForces {cpBodyResetForces(&_body);}
- (void)applyForce:(cpVect)force offset:(cpVect)offset {cpBodyApplyForce(&_body, force, offset);}
- (void)applyImpulse:(cpVect)j offset:(cpVect)offset {cpBodyApplyImpulse(&_body, j, offset);}

- (bool)isSleeping {return cpBodyIsSleeping(&_body);}
- (bool)isRogue {return cpBodyIsRogue(&_body);}
- (bool)isStatic {return cpBodyIsStatic(&_body);}

- (void)activate {cpBodyActivate(&_body);}
- (void)activateStatic:(ChipmunkShape *)filter {cpBodyActivateStatic(&_body, filter.shape);}
- (void)sleepWithGroup:(ChipmunkBody *)group {cpBodySleepWithGroup(&_body, group.body);}
- (void)sleep {cpBodySleep(&_body);}

- (NSArray *)chipmunkObjects {return [NSArray arrayWithObject:self];}
- (void)addToSpace:(ChipmunkSpace *)space {[space addBody:self];}
- (void)removeFromSpace:(ChipmunkSpace *)space {[space removeBody:self];}

static void PushShape(cpBody *ignored, cpShape *shape, NSMutableArray *arr){[arr addObject:shape->data];}
- (NSArray *)shapes;
{
	NSMutableArray *arr = [NSMutableArray array];
	cpBodyEachShape(&_body, (cpBodyShapeIteratorFunc)PushShape, arr);
	
	return arr;
}

static void PushConstraint(cpBody *ignored, cpConstraint *constraint, NSMutableArray *arr){[arr addObject:constraint->data];}
- (NSArray *)constraints;
{
	NSMutableArray *arr = [NSMutableArray array];
	cpBodyEachConstraint(&_body, (cpBodyConstraintIteratorFunc)PushConstraint, arr);
	
	return arr;
}

static void CallArbiterBlock(cpBody *body, cpArbiter *arbiter, ChipmunkBodyArbiterIteratorBlock block){block(arbiter);}
- (void)eachArbiter:(ChipmunkBodyArbiterIteratorBlock)block;
{
	cpBodyEachArbiter(&_body, (cpBodyArbiterIteratorFunc)CallArbiterBlock, block);
}

//MARK: Extras

- (CGAffineTransform) affineTransform;
{
	cpVect rot = _body.rot, pos = _body.p;
	return CGAffineTransformMake(rot.x, rot.y, -rot.y, rot.x, pos.x, pos.y);
}

@end
