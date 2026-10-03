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
@property (nonatomic, strong) NSMutableSet<RptqObject *> *dirtyObjects;
@property (nonatomic, strong) NSMutableArray<MADStoreObject *> *deletedObjects;
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
	context->_dirtyObjects = [NSMutableSet set];
	context->_deletedObjects = [NSMutableArray array];
	return context;
}

- (BOOL)isLoaded { return self.graph != nil; }

/// Any unsaved insert, attribute set, relationship set, or deletion.
- (BOOL)hasChanges { return self.dirtyObjects.count > 0 || self.deletedObjects.count > 0; }

#pragma mark - Loading

- (BOOL)loadAllWithError:(NSError **)error {
	MADStoreGraph *graph = [self.store allObjectsWithError:error];
	if (!graph) return NO;
	self.graph = graph;
	[self.registry removeAllObjects];
	[self.dirtyObjects removeAllObjects];
	[self.deletedObjects removeAllObjects];
	return YES;
}

- (BOOL)loadPart:(MADStorePart)part error:(NSError **)error {
	MADStoreGraph *graph = [self.store graphForPart:part error:error];
	if (!graph) return NO;
	self.graph = graph;
	[self.registry removeAllObjects];
	[self.dirtyObjects removeAllObjects];
	[self.deletedObjects removeAllObjects];
	return YES;
}

#pragma mark - Faulting

- (RptqObject *)objectForEntity:(NSString *)entity identifier:(int64_t)identifier {
	RptqObject *cached = self.registry[entity][@(identifier)];
	if (cached) return cached;

	MADStoreObject *row = [self.graph objectForEntity:entity identifier:identifier];
	if (!row) return nil;

	// The row's entity is its concrete kind -- RptqDocumentElementLabel, not the table
	// it shares.  Fault the matching Rptq subclass so callers get the real class back,
	// falling back to the base for any entity the model names but no class implements.
	Class objectClass = NSClassFromString(row.entity);
	if (![objectClass isSubclassOfClass:[RptqObject class]]) objectClass = [RptqObject class];
	cached = [objectClass objectWithBackingObject:row storeContext:self];
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
	[object awakeFromInsert];
	[self.dirtyObjects addObject:object];
	return object;
}

/// The row is new or one of its values changed; the next save writes it.
- (void)markObjectChanged:(RptqObject *)object {
	if (object) [self.dirtyObjects addObject:object];
}

- (BOOL)save:(NSError **)error {
	if (!self.hasChanges) return YES; // A clean save must not touch the file.

	NSArray<MADStoreObject *> *dirty = [self dirtyBackingObjects];
	NSArray<MADStoreObject *> *deleted = self.deletedObjects.copy;
	if (![self.store writeObjects:dirty deletingObjects:deleted error:error]) {
		return NO;
	}

	[self.dirtyObjects removeAllObjects];
	[self.deletedObjects removeAllObjects];
	for (MADStoreObject *row in deleted) {
		[self.registry[row.entity] removeObjectForKey:@(row.identifier)];
		[self.graph removeObjectForEntity:row.entity identifier:row.identifier];
	}
	// The store may have assigned surrogate identifiers to rows whose entity has no
	// model identifier; re-key the registry so those rows fault under their new keys.
	[self rekeyRegistry];
	return YES;
}

- (NSArray<MADStoreObject *> *)dirtyBackingObjects {
	NSMutableArray<MADStoreObject *> *rows = [NSMutableArray arrayWithCapacity:self.dirtyObjects.count];
	for (RptqObject *object in self.dirtyObjects) {
		if (![self.deletedObjects containsObject:object.backingObject]) {
			[rows addObject:object.backingObject];
		}
	}
	return rows;
}

- (void)rekeyRegistry {
	for (NSString *entity in self.registry.allKeys) {
		NSMutableDictionary<NSNumber *, RptqObject *> *byIdentifier = self.registry[entity];
		NSMutableDictionary<NSNumber *, RptqObject *> *rekeyed = [NSMutableDictionary dictionaryWithCapacity:byIdentifier.count];
		for (RptqObject *object in byIdentifier.allValues) {
			rekeyed[@(object.identifier)] = object;
		}
		self.registry[entity] = rekeyed;
	}
}

- (BOOL)deleteObject:(RptqObject *)object error:(NSError **)error {
	// Deletion is pending, as in Core Data: the row stays readable until the next
	// save commits the delete.  The object leaves the registry now so it cannot be
	// faulted again, and any unsaved edit to it is dropped with it.
	[self.registry[object.entity] removeObjectForKey:@(object.identifier)];
	[self.dirtyObjects removeObject:object];
	if (![self.deletedObjects containsObject:object.backingObject]) {
		[self.deletedObjects addObject:object.backingObject];
	}
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

	// Both ends of the edge change -- the reference here and the inverse elsewhere --
	// so both rows are dirty and the next save rewrites them both.
	[self.dirtyObjects addObject:object];
	void (^markMember)(int64_t) = ^(int64_t identifier) {
		if (identifier == 0) return;
		RptqObject *member = [self objectForEntity:relationship.destination identifier:identifier];
		if (member) [self.dirtyObjects addObject:member];
	};

	if (!relationship.isToMany) {
		int64_t targetIdentifier = MADStoreIdentifierOfValue(value);
		if (targetIdentifier == 0) {
			[object.backingObject setReference:nil forName:name];
			return;
		}
		[object.backingObject setReference:@(targetIdentifier) forName:name];
		markMember(targetIdentifier);
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
	for (NSNumber *memberIdentifier in identifiers) {
		markMember(memberIdentifier.longLongValue);
	}
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

- (void)addObject:(id)member toRelationshipNamed:(NSString *)name onObject:(RptqObject *)object {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	MADStoreEntity *entity = [schema entityNamed:object.entity];
	MADStoreRelationship *relationship = [entity anyRelationshipNamed:name];
	if (!relationship || !relationship.isToMany) return;

	int64_t memberIdentifier = MADStoreIdentifierOfValue(member);
	if (memberIdentifier == 0) return;
	NSMutableArray<NSNumber *> *collection = [object.backingObject collectionForName:name];
	if ([collection containsObject:@(memberIdentifier)]) return; // Not a change.
	[collection addObject:@(memberIdentifier)];
	[self.dirtyObjects addObject:object];

	MADStoreEntity *destination = [schema entityNamed:relationship.destination];
	MADStoreRelationship *inverse = [destination anyRelationshipNamed:relationship.inverse];
	if (!inverse) return;
	MADStoreObject *target = [self.graph objectForEntity:relationship.destination identifier:memberIdentifier];
	if (!target) return;
	RptqObject *memberObject = [self objectForEntity:relationship.destination identifier:memberIdentifier];
	if (memberObject) [self.dirtyObjects addObject:memberObject];
	if (inverse.isToMany) {
		NSMutableArray<NSNumber *> *members = [target collectionForName:inverse.name];
		if (![members containsObject:@(object.identifier)]) [members addObject:@(object.identifier)];
	} else {
		[target setReference:@(object.identifier) forName:inverse.name];
	}
}

- (void)removeObject:(id)member fromRelationshipNamed:(NSString *)name onObject:(RptqObject *)object {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	MADStoreEntity *entity = [schema entityNamed:object.entity];
	MADStoreRelationship *relationship = [entity anyRelationshipNamed:name];
	if (!relationship || !relationship.isToMany) return;

	int64_t memberIdentifier = MADStoreIdentifierOfValue(member);
	NSMutableArray<NSNumber *> *collection = [object.backingObject existingCollectionForName:name];
	[collection removeObject:@(memberIdentifier)];
	[self.dirtyObjects addObject:object];

	MADStoreEntity *destination = [schema entityNamed:relationship.destination];
	MADStoreRelationship *inverse = [destination anyRelationshipNamed:relationship.inverse];
	if (!inverse) return;
	MADStoreObject *target = [self.graph objectForEntity:relationship.destination identifier:memberIdentifier];
	if (!target) return;
	RptqObject *memberObject = [self objectForEntity:relationship.destination identifier:memberIdentifier];
	if (memberObject) [self.dirtyObjects addObject:memberObject];
	if (inverse.isToMany) {
		NSMutableArray<NSNumber *> *members = [target collectionForName:inverse.name];
		[members removeObject:@(object.identifier)];
	} else {
		[target setReference:nil forName:inverse.name];
	}
}

@end

