// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

#define CP_ALLOW_PRIVATE_ACCESS
#import "ObjectiveChipmunk.h"

#import <TargetConditionals.h>

#ifdef CHIPMUNK_PRO_TRIAL
#if TARGET_OS_IPHONE == 1
	#import <UIKit/UIKit.h>
#else
	#import <AppKit/AppKit.h>
#endif
#endif


// Just in case the user doesn't have -ObjC in their linker flags.
// Annoyingly, this will be the case more often than not.
@interface NSArrayChipmunkObject : NSArray<ChipmunkObject>

@property(nonatomic, retain) NSArray *chipmunkObjects;

@end

@implementation NSArrayChipmunkObject

@synthesize chipmunkObjects = _chipmunkObjects;

-(id)initWithArray:(NSArray *)objects {
	if((self = [super init])){
		self.chipmunkObjects = objects;
	}
	
	return self;
}

-(NSUInteger)count
{
	return [_chipmunkObjects count];
}

-(id)objectAtIndex:(NSUInteger)index
{
	return [_chipmunkObjects objectAtIndex:index];
}

@end


// Private class used to wrap the statically allocated staticBody attached to each space.
@interface _ChipmunkStaticBodySingleton : ChipmunkBody {
	cpBody *_bodyPtr;
	ChipmunkSpace *space; // weak ref
}

@end

typedef struct handlerContext {
	id delegate;
	ChipmunkSpace *space;
	cpCollisionType typeA, typeB;
	SEL beginSelector;
	bool (*beginFunc)(id self, SEL selector, cpArbiter *arb, ChipmunkSpace *space);
	SEL preSolveSelector;
	bool (*preSolveFunc)(id self, SEL selector, cpArbiter *arb, ChipmunkSpace *space);
	SEL postSolveSelector;
	void (*postSolveFunc)(id self, SEL selector, cpArbiter *arb, ChipmunkSpace *space);
	SEL separateSelector;
	void (*separateFunc)(id self, SEL selector, cpArbiter *arb, ChipmunkSpace *space);
} handlerContext;

@implementation ChipmunkSpace

#ifdef CHIPMUNK_PRO_TRIAL
static NSString *dialogTitle = @"Chipmunk Pro Trial";
static NSString *dialogMessage = @"This copy of Chipmunk Pro is a trial, please consider purchasing if you continue using it.";

+(void)initialize
{
	[super initialize];

	static BOOL done = FALSE;
	if(done) return; else done = TRUE;
	
#if TARGET_OS_IPHONE == 1
	UIAlertView *alert = [[UIAlertView alloc]
		initWithTitle:dialogTitle
		message:dialogMessage
		delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil
	];
	
	[alert show];
	[alert release];
#else
	[self performSelectorOnMainThread:@selector(dialog) withObject:nil waitUntilDone:FALSE];
#endif

}

#if TARGET_OS_IPHONE != 1
+(void)dialog
{
	[NSApplication sharedApplication];
	[[NSAlert
		alertWithMessageText:dialogTitle
		defaultButton:@"OK"
		alternateButton:nil
		otherButton:nil
		informativeTextWithFormat:dialogMessage
	] runModal];
}
#endif

#endif

+(ChipmunkSpace *)spaceFromCPSpace:(cpSpace *)space;
{	
	ChipmunkSpace *obj = space->data;
	cpAssertHard([obj isKindOfClass:[ChipmunkSpace class]], "'space->data' is not a pointer to a ChipmunkSpace object.");
	
	return obj;
}

- (id)initWithSpace:(cpSpace *)space
{
	if((self = [super init])){
		_children = [[NSMutableSet alloc] init];
		_handlers = [[NSMutableArray alloc] init];
		
		_space = space;
		cpSpaceSetUserData(_space, self);
		_staticBody = [[ChipmunkBody alloc] initStaticBody];
		_space->staticBody = _staticBody.body;
	}
	
	return self;
}

- (id)init {
	// Use a fast space instead if the class is available.
	// However if you don't specify -ObjC as a linker flag the dynamic substitution won't work.
	Class hastySpace = NSClassFromString(@"ChipmunkHastySpace");
	if(hastySpace && [self isMemberOfClass:[ChipmunkSpace class]]){
		[self release];
		return [[hastySpace alloc] init];
	} else {
		return [self initWithSpace:cpSpaceNew()];
	}
}

-(void)freeSpace
{
	cpSpaceFree(_space);
}

- (void) dealloc {
	[self freeSpace];
	[_staticBody release];
	
	[_children release];
	[_handlers release];
	
	[super dealloc];
}

- (cpSpace *)space {return _space;}

@synthesize data = _data;

// accessor macros
#define getter(type, lower, upper) \
- (type)lower {return cpSpaceGet##upper(_space);}
#define setter(type, lower, upper) \
- (void)set##upper:(type)value {cpSpaceSet##upper(_space, value);};
#define both(type, lower, upper) \
getter(type, lower, upper) \
setter(type, lower, upper)

both(int, iterations, Iterations);
both(cpVect, gravity, Gravity);
both(cpFloat, damping, Damping);
both(cpFloat, idleSpeedThreshold, IdleSpeedThreshold);
both(cpFloat, sleepTimeThreshold, SleepTimeThreshold);
both(cpFloat, collisionSlop, CollisionSlop);
both(cpFloat, collisionBias, CollisionBias);
both(cpTimestamp, collisionPersistence, CollisionPersistence);
both(bool, enableContactGraph, EnableContactGraph);
getter(cpFloat, currentTimeStep, CurrentTimeStep);

- (ChipmunkBody *)staticBody {return _staticBody;}

static bool Begin(cpArbiter *arb, struct cpSpace *space, handlerContext *ctx){return ctx->beginFunc(ctx->delegate, ctx->beginSelector, arb, ctx->space);}
static bool PreSolve(cpArbiter *arb, struct cpSpace *space, handlerContext *ctx){return ctx->preSolveFunc(ctx->delegate, ctx->preSolveSelector, arb, ctx->space);}
static void PostSolve(cpArbiter *arb, struct cpSpace *space, handlerContext *ctx){return ctx->postSolveFunc(ctx->delegate, ctx->postSolveSelector, arb, ctx->space);}
static void Separate(cpArbiter *arb, struct cpSpace *space, handlerContext *ctx){return ctx->separateFunc(ctx->delegate, ctx->separateSelector, arb, ctx->space);}


//#define HFUNC(fname, Fname) (fname ? (cpCollision##Fname##Func)fname : NULL)
//#define HFUNCS() \
//HFUNC(begin, Begin), \
//HFUNC(preSolve, PreSolve), \
//HFUNC(postSolve, PostSolve), \
//HFUNC(separate, Separate)

// Free collision handler delegates for the given type pair
static void
FilterHandlers(NSMutableArray **handlers, cpCollisionType typeA, cpCollisionType typeB)
{
	NSMutableArray *newHandlers = [[NSMutableArray alloc] initWithCapacity:[(*handlers) count]];
	
	for(NSData *data in (*handlers)){
		const handlerContext *context = [data bytes];
		if(
			!(context->typeA == typeA && context->typeB == typeB) &&
			!(context->typeA == typeB && context->typeB == typeA)
		){
			[newHandlers addObject:data];
		}
	}
	
	[(*handlers) release];
	(*handlers) = newHandlers;
}

- (void)setDefaultCollisionHandler:(id)delegate
	begin:(SEL)begin
	preSolve:(SEL)preSolve
	postSolve:(SEL)postSolve
	separate:(SEL)separate;
{
	cpCollisionType sentinel = (cpCollisionType)@"DEFAULT";
	FilterHandlers(&_handlers, sentinel, sentinel);
	
	handlerContext handler = {
		delegate, self, sentinel, sentinel,
		begin, (void *)(begin ? [delegate methodForSelector:begin] : NULL),
		preSolve, (void *)(preSolve ? [delegate methodForSelector:preSolve] : NULL),
		postSolve, (void *)(postSolve ? [delegate methodForSelector:postSolve] : NULL),
		separate, (void *)(separate ? [delegate methodForSelector:separate] : NULL),
	};
	NSData *data = [NSData dataWithBytes:&handler length:sizeof(handler)];
	[_handlers addObject:data];
	
	cpSpaceSetDefaultCollisionHandler(_space,
		(begin ? (cpCollisionBeginFunc)Begin : NULL),
		(preSolve ? (cpCollisionPreSolveFunc)PreSolve : NULL),
		(postSolve ? (cpCollisionPostSolveFunc)PostSolve : NULL),
		(separate ? (cpCollisionSeparateFunc)Separate : NULL),
		(void *)[data bytes]
	);
}
	
- (void)addCollisionHandler:(id)delegate
	typeA:(cpCollisionType)a typeB:(cpCollisionType)b
	begin:(SEL)begin
	preSolve:(SEL)preSolve
	postSolve:(SEL)postSolve
	separate:(SEL)separate;
{
	[self removeCollisionHandlerForTypeA:a andB:b];
	
	handlerContext handler = {
		delegate, self, a, b,
		begin, (void *)(begin ? [delegate methodForSelector:begin] : NULL),
		preSolve, (void *)(preSolve ? [delegate methodForSelector:preSolve] : NULL),
		postSolve, (void *)(postSolve ? [delegate methodForSelector:postSolve] : NULL),
		separate, (void *)(separate ? [delegate methodForSelector:separate] : NULL),
	};
	NSData *data = [NSData dataWithBytes:&handler length:sizeof(handler)];
	
	cpSpaceAddCollisionHandler(
		_space, a, b,
		(begin ? (cpCollisionBeginFunc)Begin : NULL),
		(preSolve ? (cpCollisionPreSolveFunc)PreSolve : NULL),
		(postSolve ? (cpCollisionPostSolveFunc)PostSolve : NULL),
		(separate ? (cpCollisionSeparateFunc)Separate : NULL),
		(void *)[data bytes]
	);
	
	[_handlers addObject:data];
}

- (void)removeCollisionHandlerForTypeA:(cpCollisionType)a andB:(cpCollisionType)b;
{
	FilterHandlers(&_handlers, a, b);
	cpSpaceRemoveCollisionHandler(_space, a, b);
}

- (id)add:(NSObject<ChipmunkObject> *)obj;
{
	if([obj conformsToProtocol:@protocol(ChipmunkBaseObject)]){
		[(NSObject<ChipmunkBaseObject> *)obj addToSpace:self];
	} else if([obj conformsToProtocol:@protocol(ChipmunkObject)]){
		for(NSObject<ChipmunkBaseObject> *child in [obj chipmunkObjects]) [self add:child];
	} else {
		[NSException raise:@"NSArgumentError" format:@"Attempted to add an object of type %@ to a ChipmunkSpace.", [obj class]];
	}
	
	[_children addObject:obj];
	return obj;
}

- (id)remove:(NSObject<ChipmunkObject> *)obj;
{
	if([obj conformsToProtocol:@protocol(ChipmunkBaseObject)]){
		[(NSObject<ChipmunkBaseObject> *)obj removeFromSpace:self];
	} else if([obj conformsToProtocol:@protocol(ChipmunkObject)]){
		for(NSObject<ChipmunkBaseObject> *child in [obj chipmunkObjects]) [self remove:child];
	} else {
		[NSException raise:@"NSArgumentError" format:@"Attempted to remove an object of type %@ from a ChipmunkSpace.", [obj class]];
	}
	
	[_children removeObject:obj];
	return obj;
}

-(BOOL)contains:(NSObject<ChipmunkObject> *)obj;
{
	return [_children containsObject:obj];
}

- (NSObject<ChipmunkObject> *)smartAdd:(NSObject<ChipmunkObject> *)obj;
{
	if(cpSpaceIsLocked(_space)){
		[self addPostStepAddition:obj];
	} else {
		[self add:obj];
	}
	
	return obj;
}

- (NSObject<ChipmunkObject> *)smartRemove:(NSObject<ChipmunkObject> *)obj;
{
	if(cpSpaceIsLocked(_space)){
		[self addPostStepRemoval:obj];
	} else {
		[self remove:obj];
	}
	
	return obj;
}

struct PostStepTargetContext {
	id target;
	SEL selector;
};

static void
postStepPerform(cpSpace *unused, id key, struct PostStepTargetContext *context)
{
	[context->target performSelector:context->selector withObject:key];
	
	[context->target release];
	cpfree(context);
	[key release];
}

- (BOOL)addPostStepCallback:(id)target selector:(SEL)selector key:(id)key;
{
	if(!cpSpaceGetPostStepCallback(_space, key)){
		struct PostStepTargetContext *context = cpcalloc(1, sizeof(struct PostStepTargetContext));
		(*context) = (struct PostStepTargetContext){target, selector};
		cpSpaceAddPostStepCallback(_space, (cpPostStepFunc)postStepPerform, key, context);
		
		[target retain];
		[key retain];
		
		return TRUE;
	} else {
		return FALSE;
	}
}

static void
postStepPerformBlock(cpSpace *unused, id key, ChipmunkPostStepBlock block)
{
	block();
	
	[block release];
	[key release];
}

- (BOOL)addPostStepBlock:(ChipmunkPostStepBlock)block key:(id)key;
{
	if(!cpSpaceGetPostStepCallback(_space, key)){
		cpSpaceAddPostStepCallback(_space, (cpPostStepFunc)postStepPerformBlock, key, [block copy]);
		
		[key retain];
		
		return TRUE;
	} else {
		return FALSE;
	}
}

- (void)addPostStepAddition:(NSObject<ChipmunkObject> *)obj;
{
	[self addPostStepCallback:self selector:@selector(add:) key:obj];
}

- (void)addPostStepRemoval:(NSObject<ChipmunkObject> *)obj;
{
	[self addPostStepCallback:self selector:@selector(remove:) key:obj];
}

static void queryAll(cpShape *shape, NSMutableArray *array){[array addObject:shape->data];}

- (NSArray *)pointQueryAll:(cpVect)point layers:(cpLayers)layers group:(cpGroup)group;
{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	cpSpacePointQuery(_space, point, layers, group, (cpSpacePointQueryFunc)queryAll, array);
	return [array autorelease];
}

- (ChipmunkShape *)pointQueryFirst:(cpVect)point layers:(cpLayers)layers group:(cpGroup)group;
{
	cpShape *shape = cpSpacePointQueryFirst(_space, point, layers, group);
	return (shape ? shape->data : nil);
}

- (NSArray *)nearestPointQueryAll:(cpVect)point maxDistance:(cpFloat)maxDistance layers:(cpLayers)layers group:(cpGroup)group;
{
	NSMutableArray *arr = [NSMutableArray array];
	cpSpaceNearestPointQuery_b(_space, point, maxDistance, layers, group, ^(cpShape *shape, cpFloat d, cpVect p){
		ChipmunkNearestPointQueryInfo *info = [[ChipmunkNearestPointQueryInfo alloc] initWithInfo:&(cpNearestPointQueryInfo){shape, p, d}];
		[arr addObject:info];
		[info release];
	});
	
	return arr;
}

- (ChipmunkNearestPointQueryInfo *)nearestPointQueryNearest:(cpVect)point maxDistance:(cpFloat)maxDistance layers:(cpLayers)layers group:(cpGroup)group;
{
	cpNearestPointQueryInfo info;
	cpSpaceNearestPointQueryNearest(_space, point, maxDistance, layers, group, &info);
	return [[[ChipmunkNearestPointQueryInfo alloc] initWithInfo:&info] autorelease];
}

typedef struct segmentQueryContext {
	cpVect start, end;
	NSMutableArray *array;
} segmentQueryContext;

static void
segmentQueryAll(cpShape *shape, cpFloat t, cpVect n, segmentQueryContext *sqc)
{
	ChipmunkSegmentQueryInfo *info = [[ChipmunkSegmentQueryInfo alloc] initWithInfo:&(cpSegmentQueryInfo){shape, t, n} start:sqc->start end:sqc->end];
	
	[sqc->array addObject:info];
	[info release];
}

- (NSArray *)segmentQueryAllFrom:(cpVect)start to:(cpVect)end layers:(cpLayers)layers group:(cpGroup)group;
{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	segmentQueryContext sqc = {start, end, array};
	
	cpSpaceSegmentQuery(_space, start, end, layers, group, (cpSpaceSegmentQueryFunc)segmentQueryAll, &sqc);
	
	return [array autorelease];
}

- (ChipmunkSegmentQueryInfo *)segmentQueryFirstFrom:(cpVect)start to:(cpVect)end layers:(cpLayers)layers group:(cpGroup)group;
{
	cpSegmentQueryInfo info;
	cpSpaceSegmentQueryFirst(_space, start, end, layers, group, &info);
	
	return [[[ChipmunkSegmentQueryInfo alloc] initWithInfo:&info start:start end:end] autorelease];
}

- (NSArray *)bbQueryAll:(cpBB)bb layers:(cpLayers)layers group:(cpGroup)group;
{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	cpSpaceBBQuery(_space, bb, layers, group, (cpSpaceBBQueryFunc)queryAll, array);
	return [array autorelease];
}

static void
shapeQueryAll(cpShape *shape, cpContactPointSet *points, NSMutableArray *array)
{
	ChipmunkShapeQueryInfo *info = [[ChipmunkShapeQueryInfo alloc] initWithShape:shape->data andPoints:points];
	[array addObject:info];
	[info release];
}

- (NSArray *)shapeQueryAll:(ChipmunkShape *)shape;
{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	cpSpaceShapeQuery(_space, shape.shape, (cpSpaceShapeQueryFunc)shapeQueryAll, array);
	return [array autorelease];
}

- (BOOL)shapeTest:(ChipmunkShape *)shape
{
	return cpSpaceShapeQuery(_space, shape.shape, NULL, NULL);
}

- (void)activateShapesTouchingShape:(ChipmunkShape *)shape;
{
	cpSpaceActivateShapesTouchingShape(_space, shape.shape);
}

static void PushBody(cpBody *body, NSMutableArray *arr){[arr addObject:body->data];}
- (NSArray *)bodies;
{
	NSMutableArray *arr = [NSMutableArray array];
	cpSpaceEachBody(_space, (cpSpaceBodyIteratorFunc)PushBody, arr);
	
	return arr;
}

static void PushShape(cpShape *shape, NSMutableArray *arr){[arr addObject:shape->data];}
- (NSArray *)shapes;
{
	NSMutableArray *arr = [NSMutableArray array];
	cpSpaceEachShape(_space, (cpSpaceShapeIteratorFunc)PushShape, arr);
	
	return arr;
}

static void PushConstraint(cpConstraint *constraint, NSMutableArray *arr){[arr addObject:constraint->data];}
- (NSArray *)constraints;
{
	NSMutableArray *arr = [NSMutableArray array];
	cpSpaceEachConstraint(_space, (cpSpaceConstraintIteratorFunc)PushConstraint, arr);
	
	return arr;
}


- (void)reindexStatic;
{
	cpSpaceReindexStatic(_space);
}

- (void)reindexShape:(ChipmunkShape *)shape;
{
	cpSpaceReindexShape(_space, shape.shape);
}

- (void)reindexShapesForBody:(ChipmunkBody *)body
{
	cpSpaceReindexShapesForBody(_space, body.body);
}

- (void)step:(cpFloat)dt;
{
	cpSpaceStep(_space, dt);
}

//MARK: Extras

- (ChipmunkBody *)addBody:(ChipmunkBody *)obj {
	cpSpaceAddBody(_space, obj.body);
	[_children addObject:obj];
	return obj;
}

- (ChipmunkBody *)removeBody:(ChipmunkBody *)obj {
	cpSpaceRemoveBody(_space, obj.body);
	[_children removeObject:obj];
	return obj;
}


- (ChipmunkShape *)addShape:(ChipmunkShape *)obj {
	cpSpaceAddShape(_space, obj.shape);
	[_children addObject:obj];
	return obj;
}

- (ChipmunkShape *)removeShape:(ChipmunkShape *)obj {
	cpSpaceRemoveShape(_space, obj.shape);
	[_children removeObject:obj];
	return obj;
}

- (ChipmunkShape *)addStaticShape:(ChipmunkShape *)obj {
	cpSpaceAddStaticShape(_space, obj.shape);
	[_children addObject:obj];
	return obj;
}

- (ChipmunkShape *)removeStaticShape:(ChipmunkShape *)obj {
	cpSpaceRemoveStaticShape(_space, obj.shape);
	[_children removeObject:obj];
	return obj;
}

- (ChipmunkConstraint *)addConstraint:(ChipmunkConstraint *)obj {
	cpSpaceAddConstraint(_space, obj.constraint);
	[_children addObject:obj];
	return obj;
}

- (ChipmunkConstraint *)removeConstraint:(ChipmunkConstraint *)obj {
	cpSpaceRemoveConstraint(_space, obj.constraint);
	[_children removeObject:obj];
	return obj;
}

static ChipmunkStaticSegmentShape *
boundSeg(ChipmunkBody *body, cpVect a, cpVect b, cpFloat radius, cpFloat elasticity,cpFloat friction, cpLayers layers, cpGroup group, cpCollisionType collisionType)
{
	ChipmunkStaticSegmentShape *seg = [ChipmunkStaticSegmentShape segmentWithBody:body from:a to:b radius:radius];
	seg.elasticity = elasticity;
	seg.friction = friction;
	seg.layers = layers;
	seg.group = group;
	seg.collisionType = collisionType;
	
	return seg;
}

- (NSArray *)addBounds:(CGRect)bounds thickness:(cpFloat)radius
	elasticity:(cpFloat)elasticity friction:(cpFloat)friction
	layers:(cpLayers)layers group:(cpGroup)group
	collisionType:(cpCollisionType)collisionType;
{
	cpFloat l = bounds.origin.x - radius;
	cpFloat r = bounds.origin.x + bounds.size.width + radius;
	cpFloat b = bounds.origin.y - radius;
	cpFloat t = bounds.origin.y + bounds.size.height + radius;
	
	NSArray *segs = [[NSArrayChipmunkObject alloc] initWithArray:[NSArray arrayWithObjects:
		boundSeg(_staticBody, cpv(l,b), cpv(l,t), radius, elasticity, friction, layers, group, collisionType),
		boundSeg(_staticBody, cpv(l,t), cpv(r,t), radius, elasticity, friction, layers, group, collisionType),
		boundSeg(_staticBody, cpv(r,t), cpv(r,b), radius, elasticity, friction, layers, group, collisionType),
		boundSeg(_staticBody, cpv(r,b), cpv(l,b), radius, elasticity, friction, layers, group, collisionType),
		nil
	]];
	
	[self add:segs];
	return segs;
}

@end
