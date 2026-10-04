//
//  MADStoreGraph.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "MADStoreGraph.h"
#import "MADStoreSchema.h"

@interface MADStoreGraph ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSNumber *, MADStoreObject *> *> *objects;
@end

@implementation MADStoreGraph

- (instancetype)init {
	self = [super init];
	if (!self) return nil;
	_objects = [NSMutableDictionary dictionary];
	return self;
}

- (void)addObject:(MADStoreObject *)object {
	NSMutableDictionary<NSNumber *, MADStoreObject *> *byIdentifier = self.objects[object.entity];
	if (!byIdentifier) {
		byIdentifier = [NSMutableDictionary dictionary];
		self.objects[object.entity] = byIdentifier;
	}
	// A second object under the same key would replace the first without a word, and
	// a row would go missing somewhere far away.  Two satellites both left at
	// identifier 0 are the way that happens; give them identifiers before adding.
	NSAssert(byIdentifier[@(object.identifier)] == nil || byIdentifier[@(object.identifier)] == object,
			 @"%@ %lld already in the graph", object.entity, (long long)object.identifier);
	byIdentifier[@(object.identifier)] = object;
}

- (void)removeObjectForEntity:(NSString *)entity identifier:(int64_t)identifier {
	[self.objects[entity] removeObjectForKey:@(identifier)];
}

- (MADStoreObject *)objectForEntity:(NSString *)entity identifier:(int64_t)identifier {
	MADStoreObject *object = self.objects[entity][@(identifier)];
	if (object) return object;
	// A to-one edge may name the base entity while the row it points at carries its
	// concrete kind -- RptqDocumentElement.rect points back from RptqRect.inElement,
	// and the element in the graph is an RptqDocumentElementLabel.  Fall back to the
	// table the name resolves to, which is the same row by another name.
	MADStoreEntity *named = [[MADStoreSchema sharedSchema] entityNamed:entity];
	if (!named) return nil;
	for (NSString *name in self.objects) {
		if ([name isEqualToString:entity]) continue;
		MADStoreEntity *candidate = [[MADStoreSchema sharedSchema] entityNamed:name];
		if (![candidate.table isEqualToString:named.table]) continue;
		object = self.objects[name][@(identifier)];
		if (object) return object;
	}
	return nil;
}

- (MADStoreObject *)objectForEntity:(NSString *)entity
						 identifier:(int64_t)identifier
					createIfMissing:(BOOL)createIfMissing {
	MADStoreObject *object = [self objectForEntity:entity identifier:identifier];
	if (object || !createIfMissing) return object;
	object = [MADStoreObject objectWithEntity:entity identifier:identifier];
	[self addObject:object];
	return object;
}

- (NSArray<MADStoreObject *> *)objectsForEntity:(NSString *)entity {
	NSMutableArray<MADStoreObject *> *objects = [NSMutableArray array];
	NSMutableDictionary<NSNumber *, MADStoreObject *> *exact = self.objects[entity];
	if (exact) [objects addObjectsFromArray:exact.allValues];
	// The same table fallback the singular lookup has, for the table's OWNER only:
	// rows carry their concrete kind (RptqDocumentElementLabel), and a query for
	// the owning base entity must return every row of the table, while a query for
	// one kind returns exactly that kind.
	MADStoreEntity *named = [[MADStoreSchema sharedSchema] entityNamed:entity];
	BOOL ownsTable = named != nil && [[MADStoreSchema sharedSchema] entityForTable:named.table] == named;
	if (ownsTable) {
		for (NSString *name in self.objects) {
			if ([name isEqualToString:entity]) continue;
			MADStoreEntity *candidate = [[MADStoreSchema sharedSchema] entityNamed:name];
			if (![candidate.table isEqualToString:named.table]) continue;
			[objects addObjectsFromArray:self.objects[name].allValues];
		}
	}
	if (objects.count == 0) return @[];
	// Identifier order is not meaningful across kinds, but a stable order is.
	return [objects sortedArrayUsingComparator:^NSComparisonResult(MADStoreObject *a, MADStoreObject *b) {
		if (a.identifier < b.identifier) return NSOrderedAscending;
		if (a.identifier > b.identifier) return NSOrderedDescending;
		return NSOrderedSame;
	}];
}

- (NSArray<MADStoreObject *> *)allObjects {
	// A direct walk of the storage, not -objectsForEntity:, whose table fallback
	// would return each shared-table row once per kind.  Sorted per kind by
	// identifier, which is also the writer's row order.
	NSMutableArray<MADStoreObject *> *all = [NSMutableArray array];
	NSArray<NSString *> *names = [self.objects.allKeys sortedArrayUsingSelector:@selector(compare:)];
	for (NSString *name in names) {
		NSArray<MADStoreObject *> *sorted = [self.objects[name].allValues sortedArrayUsingComparator:^NSComparisonResult(MADStoreObject *a, MADStoreObject *b) {
			if (a.identifier < b.identifier) return NSOrderedAscending;
			if (a.identifier > b.identifier) return NSOrderedDescending;
			return NSOrderedSame;
		}];
		[all addObjectsFromArray:sorted];
	}
	return all;
}

- (NSArray<NSString *> *)entityNames {
	return [self.objects.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

- (NSUInteger)count {
	NSUInteger count = 0;
	for (NSMutableDictionary *byIdentifier in self.objects.allValues) count += byIdentifier.count;
	return count;
}

#pragma mark - Inverses

static MADStoreRelationship *MADStoreInverseOf(MADStoreEntity *__unused entity, MADStoreRelationship *relationship) {
	MADStoreEntity *destination = [[MADStoreSchema sharedSchema] entityNamed:relationship.destination];
	return [destination anyRelationshipNamed:relationship.inverse];
}

- (MADStoreGraph *)graphByCompletingInverses {
	MADStoreGraph *complete = [MADStoreGraph new];
	for (MADStoreObject *object in [self allObjects]) {
		[complete addObject:[object copy]];
	}

	for (MADStoreObject *object in [complete allObjects]) {
		MADStoreEntity *entity = [[MADStoreSchema sharedSchema] entityNamed:object.entity];
		if (!entity) continue;

		// A to-one edge names its target; give the target the paired edge back.
		for (MADStoreRelationship *relationship in entity.allRelationships) {
			if (relationship.isToMany) continue;
			NSNumber *targetIdentifier = [object referenceForName:relationship.name];
			if (!targetIdentifier) continue;
			MADStoreObject *target = [complete objectForEntity:relationship.destination
													identifier:targetIdentifier.longLongValue];
			if (!target) continue;
			MADStoreRelationship *inverse = MADStoreInverseOf(entity, relationship);
			if (!inverse) continue;
			if (inverse.isToMany) {
				NSMutableArray<NSNumber *> *list = [target collectionForName:inverse.name];
				if (![list containsObject:@(object.identifier)]) [list addObject:@(object.identifier)];
			} else {
				[target setReference:@(object.identifier) forName:inverse.name];
			}
		}

		// A to-many edge names its members; give each member its edge back.  This is
		// also what carries a many-to-many across to the far side.
		for (MADStoreRelationship *relationship in entity.allRelationships) {
			if (!relationship.isToMany) continue;
			NSArray<NSNumber *> *members = [object existingCollectionForName:relationship.name];
			if (!members) continue;
			MADStoreRelationship *inverse = MADStoreInverseOf(entity, relationship);
			for (NSNumber *memberIdentifier in members) {
				MADStoreObject *member = [complete objectForEntity:relationship.destination
														identifier:memberIdentifier.longLongValue];
				if (!member || !inverse) continue;
				if (inverse.isToMany) {
					NSMutableArray<NSNumber *> *list = [member collectionForName:inverse.name];
					if (![list containsObject:@(object.identifier)]) [list addObject:@(object.identifier)];
				} else {
					[member setReference:@(object.identifier) forName:inverse.name];
				}
			}
		}
	}

	return complete;
}

#pragma mark - Equality

- (BOOL)isEqualToGraph:(MADStoreGraph *)other {
	if (other == self) return YES;
	if (![other isKindOfClass:[MADStoreGraph class]]) return NO;
	if (self.count != other.count) return NO;
	for (MADStoreObject *object in [self allObjects]) {
		MADStoreObject *mine = [other objectForEntity:object.entity identifier:object.identifier];
		if (!mine || ![object isEqualToObject:mine]) return NO;
	}
	return YES;
}

- (BOOL)isEqual:(id)object {
	return [self isEqualToGraph:object];
}

- (NSString *)description {
	NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"<%@ %lu objects", NSStringFromClass(self.class), (unsigned long)self.count];
	for (NSString *name in [self entityNames]) {
		[description appendFormat:@"\n\t%@ x%lu", name, (unsigned long)[self objectsForEntity:name].count];
	}
	[description appendString:@">"];
	return description;
}

@end
