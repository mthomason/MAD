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

// The change notification mirrors Core Data's contract -- the same name, the same
// userInfo keys, object = this context -- so the seven observers registered
// against NSManagedObjectContextObjectsDidChangeNotification keep working.
#import <CoreData/NSManagedObjectContext.h>

@interface RptqStoreContext ()
@property (nonatomic, strong, readwrite) MADStoreGraph *graph;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSNumber *, RptqObject *> *> *registry;
@property (nonatomic, strong) NSMutableSet<RptqObject *> *dirtyObjects;
@property (nonatomic, strong) NSMutableArray<MADStoreObject *> *deletedObjects;
// Accumulated since the last post, so a gesture that sets many properties posts
// one notification instead of one per setter.
@property (nonatomic, strong) NSMutableSet<RptqObject *> *pendingInserted;
@property (nonatomic, strong) NSMutableSet<RptqObject *> *pendingUpdated;
@property (nonatomic, strong) NSMutableSet<RptqObject *> *pendingDeleted;
@property (nonatomic, assign) BOOL postScheduled;
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
	context->_pendingInserted = [NSMutableSet set];
	context->_pendingUpdated = [NSMutableSet set];
	context->_pendingDeleted = [NSMutableSet set];
	return context;
}

- (BOOL)isLoaded { return self.graph != nil; }

/// Any unsaved insert, attribute set, relationship set, or deletion.
- (BOOL)hasChanges { return self.dirtyObjects.count > 0 || self.deletedObjects.count > 0; }

#pragma mark - Change notification

- (void)scheduleChangeNotificationPost {
	@synchronized (self) {
		if (self.postScheduled) return;
		self.postScheduled = YES;
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		[self postChangeNotification];
	});
}

- (void)postChangeNotification {
	NSMutableDictionary<NSString *, NSSet<RptqObject *> *> *userInfo = [NSMutableDictionary dictionary];
	@synchronized (self) {
		self.postScheduled = NO;
		if (self.pendingInserted.count > 0) userInfo[NSInsertedObjectsKey] = self.pendingInserted.copy;
		if (self.pendingUpdated.count > 0) userInfo[NSUpdatedObjectsKey] = self.pendingUpdated.copy;
		if (self.pendingDeleted.count > 0) userInfo[NSDeletedObjectsKey] = self.pendingDeleted.copy;
		[self.pendingInserted removeAllObjects];
		[self.pendingUpdated removeAllObjects];
		[self.pendingDeleted removeAllObjects];
	}
	if (userInfo.count == 0) return;
	[[NSNotificationCenter defaultCenter] postNotificationName:NSManagedObjectContextObjectsDidChangeNotification
														object:self
													  userInfo:userInfo];
}

#pragma mark - Loading

- (BOOL)loadAllWithError:(NSError **)error {
	MADStoreGraph *graph = [self.store allObjectsWithError:error];
	if (!graph) return NO;
	self.graph = graph;
	[self.registry removeAllObjects];
	[self.dirtyObjects removeAllObjects];
	[self.deletedObjects removeAllObjects];
	[self.pendingInserted removeAllObjects];
	[self.pendingUpdated removeAllObjects];
	[self.pendingDeleted removeAllObjects];
	return YES;
}

- (BOOL)loadPart:(MADStorePart)part error:(NSError **)error {
	MADStoreGraph *graph = [self.store graphForPart:part error:error];
	if (!graph) return NO;
	self.graph = graph;
	[self.registry removeAllObjects];
	[self.dirtyObjects removeAllObjects];
	[self.deletedObjects removeAllObjects];
	[self.pendingInserted removeAllObjects];
	[self.pendingUpdated removeAllObjects];
	[self.pendingDeleted removeAllObjects];
	return YES;
}

#pragma mark - Faulting

- (RptqObject *)objectForEntity:(NSString *)entity identifier:(int64_t)identifier {
	RptqObject *cached = self.registry[entity][@(identifier)];
	if (!cached) {
		// A request may name the table-owning base entity while the row is cached
		// under its concrete kind; the same owner-table fallback the graph has.
		MADStoreEntity *named = [[MADStoreSchema sharedSchema] entityNamed:entity];
		BOOL ownsTable = named != nil && [[MADStoreSchema sharedSchema] entityForTable:named.table] == named;
		if (ownsTable) {
			for (NSString *name in self.registry) {
				if ([name isEqualToString:entity]) continue;
				MADStoreEntity *candidate = [[MADStoreSchema sharedSchema] entityNamed:name];
				if (![candidate.table isEqualToString:named.table]) continue;
				cached = self.registry[name][@(identifier)];
				if (cached) break;
			}
		}
	}
	if (cached) return cached;

	MADStoreObject *row = [self.graph objectForEntity:entity identifier:identifier];
	if (!row) return nil;

	// The row's entity is its concrete kind -- RptqDocumentElementLabel, not the table
	// it shares.  Fault the matching Rptq subclass so callers get the real class back,
	// falling back to the base for any entity the model names but no class implements.
	Class objectClass = NSClassFromString(row.entity);
	if (![objectClass isSubclassOfClass:[RptqObject class]]) objectClass = [RptqObject class];
	cached = [objectClass objectWithBackingObject:row storeContext:self];
	// The registry is keyed on the row's own entity, so a row reached by any name
	// caches once and -save:'s deletion clearing finds the entry under row.entity.
	NSMutableDictionary<NSNumber *, RptqObject *> *byIdentifier = self.registry[row.entity];
	if (!byIdentifier) {
		byIdentifier = [NSMutableDictionary dictionary];
		self.registry[row.entity] = byIdentifier;
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
		// Identifiers are unique per table, not per entity: the nine document
		// element kinds share RptqDocumentElement's table.  Mint over the
		// table's owner entity -- the graph's objectsForEntity: fallback returns
		// every kind in the table -- so a subentity insert never collides with
		// a sibling kind already there.  See BUGS.md "insertObjectForEntity:
		// mints identifiers per entity, not per table".
		NSString *mintingEntity = descriptor.parentName != nil ? descriptor.parentName : entity;
		int64_t highest = 0;
		for (MADStoreObject *row in [self.graph objectsForEntity:mintingEntity]) {
			if (row.identifier > highest) highest = row.identifier;
		}
		identifier = highest + 1;
	}

	MADStoreObject *row = [MADStoreObject objectWithEntity:entity identifier:identifier];
	// Core Data applied model defaults at insert; the store's columns are NOT NULL,
	// so the same scalar zero/empty defaults land here rather than at write time.
	for (MADStoreAttribute *attribute in descriptor.allAttributes) {
		if (attribute.optional || [attribute.name isEqualToString:@"identifier"]) continue;
		if ([row attributeValue:attribute.name] != nil) continue;
		id defaultValue = nil;
		switch (attribute.type) {
			case MADStoreValueTypeInteger: defaultValue = @0; break;
			case MADStoreValueTypeReal: defaultValue = @0.0; break;
			case MADStoreValueTypeText: defaultValue = @""; break;
			case MADStoreValueTypeBlob: break; // Absence is NULL, which BLOB allows.
		}
		if (defaultValue != nil) [row setAttributeValue:defaultValue forName:attribute.name];
	}
	[self.graph addObject:row];
	RptqObject *object = [self objectForEntity:entity identifier:identifier];
	NSAssert(object != nil, @"an inserted row must fault back into the context");
	[object awakeFromInsert];
	[self.dirtyObjects addObject:object];
	@synchronized (self) {
		[self.pendingInserted addObject:object];
	}
	[self scheduleChangeNotificationPost];
	return object;
}

/// The row is new or one of its values changed; the next save writes it.
- (void)markObjectChanged:(RptqObject *)object {
	if (!object) return;
	[self.dirtyObjects addObject:object];
	@synchronized (self) {
		[self.pendingUpdated addObject:object];
	}
	[self scheduleChangeNotificationPost];
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
	// The accumulated changes post on the next main-queue turn; a save does not
	// post its own, so a batch that inserts and saves still yields one notification.
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
	@synchronized (self) {
		[self.pendingInserted removeObject:object];
		[self.pendingUpdated removeObject:object];
		[self.pendingDeleted addObject:object];
	}
	[self scheduleChangeNotificationPost];
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
	NSMutableArray<NSNumber *> *collection = (NSMutableArray<NSNumber *> *)[object.backingObject existingCollectionForName:name];
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

