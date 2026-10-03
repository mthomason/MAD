//
//  RptqStoreContext.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "RptqStoreContext.h"
#import "RptqObject.h"
#import "MADStoreSchema.h"
#import "MADStoreGraph.h"

@interface RptqStoreContext ()
@property (nonatomic, strong, readwrite) MADStoreGraph *graph;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSNumber *, RptqObject *> *> *registry;
@end

static int64_t MADStoreIdentifierOfValue(id value) {
	if ([value isKindOfClass:[RptqObject class]]) return ((RptqObject *)value).identifier;
	if ([value isKindOfClass:[NSNumber class]]) return ((NSNumber *)value).longLongValue;
	return 0;
}

static NSArray<NSNumber *> *MADStoreIdentifiersOfValue(id value) {
	if ([value isKindOfClass:[NSSet class]] || [value isKindOfClass:[NSArray class]] ||
		[value isKindOfClass:[NSOrderedSet class]]) {
		NSMutableArray<NSNumber *> *identifiers = [NSMutableArray array];
		for (id member in value) {
			int64_t identifier = MADStoreIdentifierOfValue(member);
			if (identifier != 0) [identifiers addObject:@(identifier)];
		}
		return identifiers;
	}
	int64_t single = MADStoreIdentifierOfValue(value);
	return single == 0 ? @[] : @[ @(single) ];
}

@implementation RptqStoreContext

+ (instancetype)contextWithStore:(MADStore *)store {
	RptqStoreContext *context = [[self alloc] init];
	context->_store = store;
	context->_registry = [NSMutableDictionary dictionary];
	return context;
}

- (BOOL)isLoaded { return self.graph != nil; }

#pragma mark - Loading

- (BOOL)loadAllWithError:(NSError **)error {
	MADStoreGraph *graph = [self.store allObjectsWithError:error];
	if (!graph) return NO;
	self.graph = graph;
	[self.registry removeAllObjects];
	return YES;
}

- (BOOL)loadPart:(MADStorePart)part error:(NSError **)error {
	MADStoreGraph *graph = [self.store graphForPart:part error:error];
	if (!graph) return NO;
	self.graph = graph;
	[self.registry removeAllObjects];
	return YES;
}

#pragma mark - Faulting

- (RptqObject *)objectForEntity:(NSString *)entity identifier:(int64_t)identifier {
	RptqObject *cached = self.registry[entity][@(identifier)];
	if (cached) return cached;

	MADStoreObject *row = [self.graph objectForEntity:entity identifier:identifier];
	if (!row) return nil;

	cached = [RptqObject objectWithBackingObject:row storeContext:self];
	NSMutableDictionary<NSNumber *, RptqObject *> *byIdentifier = self.registry[entity];
	if (!byIdentifier) {
		byIdentifier = [NSMutableDictionary dictionary];
		self.registry[entity] = byIdentifier;
	}
	byIdentifier[@(identifier)] = cached;
	return cached;
}

- (NSArray<RptqObject *> *)objectsForEntity:(NSString *)entity {
	NSMutableArray<RptqObject *> *objects = [NSMutableArray array];
	for (MADStoreObject *row in [self.graph objectsForEntity:entity]) {
		RptqObject *object = [self objectForEntity:entity identifier:row.identifier];
		if (object) [objects addObject:object];
	}
	return objects;
}

#pragma mark - Writing

- (RptqObject *)insertObjectForEntity:(NSString *)entity identifier:(int64_t)identifier {
	MADStoreEntity *descriptor = [[MADStoreSchema sharedSchema] entityNamed:entity];
	NSAssert(descriptor != nil, @"inserting an entity the store has no descriptor for: %@", entity);

	if (identifier <= 0) {
		int64_t highest = 0;
		for (MADStoreObject *row in [self.graph objectsForEntity:entity]) {
			if (row.identifier > highest) highest = row.identifier;
		}
		identifier = highest + 1;
	}

	MADStoreObject *row = [MADStoreObject objectWithEntity:entity identifier:identifier];
	[self.graph addObject:row];
	RptqObject *object = [self objectForEntity:entity identifier:identifier];
	NSAssert(object != nil, @"an inserted row must fault back into the context");
	return object;
}

- (BOOL)save:(NSError **)error {
	return [self.store writeGraph:self.graph replacingAll:YES error:error];
}

- (BOOL)deleteObject:(RptqObject *)object error:(NSError **)error {
	if (![self.store deleteObjectForEntity:object.entity identifier:object.identifier error:error]) {
		return NO;
	}
	[self.registry[object.entity] removeObjectForKey:@(object.identifier)];
	return YES;
}

#pragma mark - Relationships

- (void)setRelationship:(NSString *)name value:(id)value onObject:(RptqObject *)object {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	MADStoreEntity *entity = [schema entityNamed:object.entity];
	MADStoreRelationship *relationship = [entity anyRelationshipNamed:name];
	if (!relationship) return;

	MADStoreEntity *destination = [schema entityNamed:relationship.destination];
	MADStoreRelationship *inverse = [destination anyRelationshipNamed:relationship.inverse];

	if (!relationship.isToMany) {
		int64_t targetIdentifier = MADStoreIdentifierOfValue(value);
		if (targetIdentifier == 0) {
			[object.backingObject setReference:nil forName:name];
			return;
		}
		[object.backingObject setReference:@(targetIdentifier) forName:name];
		if (!inverse) return;
		MADStoreObject *target = [self.graph objectForEntity:relationship.destination
												  identifier:targetIdentifier];
		if (inverse.isToMany) {
			NSMutableArray<NSNumber *> *members = [target collectionForName:inverse.name];
			if (![members containsObject:@(object.identifier)]) [members addObject:@(object.identifier)];
		} else {
			[target setReference:@(object.identifier) forName:inverse.name];
		}
		return;
	}

	NSArray<NSNumber *> *identifiers = MADStoreIdentifiersOfValue(value);
	NSMutableArray<NSNumber *> *collection = [object.backingObject collectionForName:name];
	[collection removeAllObjects];
	[collection addObjectsFromArray:identifiers];
	if (!inverse) return;
	for (NSNumber *memberIdentifier in identifiers) {
		MADStoreObject *member = [self.graph objectForEntity:relationship.destination
												  identifier:memberIdentifier.longLongValue];
		if (!member) continue;
		if (inverse.isToMany) {
			NSMutableArray<NSNumber *> *members = [member collectionForName:inverse.name];
			if (![members containsObject:@(object.identifier)]) [members addObject:@(object.identifier)];
		} else {
			[member setReference:@(object.identifier) forName:inverse.name];
		}
	}
}

@end
