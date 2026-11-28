//
//  RptqStoreContext.m
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqStoreContext.h"
#import "RptqObject.h"
#import "MADStoreSchema.h"
#import "MADStoreGraph.h"
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqDirectionalProperty.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/RptqPoint.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqTextStyle.h>
#import <MADAPI/MADDatabaseType.h>

// The change notification mirrors Core Data's contract -- the same userInfo keys,
// object = this context -- under our own name (RptqStoreContext.h), so the
// observers the view controllers register keep working without the framework
// linking Core Data.
NSNotificationName const RptqStoreContextObjectsDidChangeNotification = @"RptqStoreContextObjectsDidChangeNotification";
NSNotificationName const RptqStoreContextWillSaveNotification = @"RptqStoreContextWillSaveNotification";
NSNotificationName const RptqStoreContextDidSaveNotification = @"RptqStoreContextDidSaveNotification";

NSString * const RptqStoreContextInsertedObjectsKey = @"RptqStoreContextInsertedObjects";
NSString * const RptqStoreContextUpdatedObjectsKey = @"RptqStoreContextUpdatedObjects";
NSString * const RptqStoreContextDeletedObjectsKey = @"RptqStoreContextDeletedObjects";

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
		if (self.pendingInserted.count > 0) userInfo[RptqStoreContextInsertedObjectsKey] = self.pendingInserted.copy;
		if (self.pendingUpdated.count > 0) userInfo[RptqStoreContextUpdatedObjectsKey] = self.pendingUpdated.copy;
		if (self.pendingDeleted.count > 0) userInfo[RptqStoreContextDeletedObjectsKey] = self.pendingDeleted.copy;
		[self.pendingInserted removeAllObjects];
		[self.pendingUpdated removeAllObjects];
		[self.pendingDeleted removeAllObjects];
	}
	if (userInfo.count == 0) return;
	[[NSNotificationCenter defaultCenter] postNotificationName:RptqStoreContextObjectsDidChangeNotification
														object:self
													  userInfo:userInfo];
}

#pragma mark - Loading

- (BOOL)loadAllWithError:(NSError * __autoreleasing *)error {
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

- (BOOL)loadPart:(MADStorePart)part error:(NSError * __autoreleasing *)error {
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
		// a sibling kind already there.  See docs/project/registers/BUGS.md "insertObjectForEntity:
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

- (BOOL)save:(NSError * __autoreleasing *)error {
	return [self saveComposed:NO error:error];
}

/// Saves a document that carries a composition graph: the store applies the
/// revision-3 schema and version in the same transaction as the rows.
- (BOOL)saveComposed:(NSError * __autoreleasing *)error {
	return [self saveComposed:YES error:error];
}

- (BOOL)saveComposed:(BOOL)composed error:(NSError * __autoreleasing *)error {
	if (!self.hasChanges && !composed) return YES; // A clean ordinary save must not touch the file.

	NSArray<MADStoreObject *> *dirty = [self dirtyBackingObjects];
	NSArray<MADStoreObject *> *deleted = self.deletedObjects.copy;
	if (![self.store writeObjects:dirty deletingObjects:deleted composed:composed error:error]) {
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

- (BOOL)deleteObject:(RptqObject *)object error:(NSError * __autoreleasing *)error {
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
		int64_t previousIdentifier = [object.backingObject referenceForName:name].longLongValue;
		int64_t targetIdentifier = MADStoreIdentifierOfValue(value);

		// Replacing or clearing the reference leaves the old target's inverse edge
		// pointing at this object unless it is unlinked here.
		if (previousIdentifier != 0 && previousIdentifier != targetIdentifier) {
			[self unlinkInverseForObject:object
						 relationship:relationship
							  inverse:inverse
					  targetIdentifier:previousIdentifier];
		}

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

	NSArray<NSNumber *> *previousIdentifiers =
		[[object.backingObject existingCollectionForName:name] copy] ?: @[];
	NSArray<NSNumber *> *identifiers = MADStoreIdentifiersOfValue(value);

	// A replaced collection removes the inverse edge from every member it no longer
	// contains.  Without this, a dropped member still names the old owner from its
	// side and the member appears in two collections.
	if (inverse) {
		NSSet<NSNumber *> *kept = [NSSet setWithArray:identifiers];
		for (NSNumber *previous in previousIdentifiers) {
			if ([kept containsObject:previous]) continue;
			[self unlinkInverseForObject:object
						 relationship:relationship
							  inverse:inverse
					  targetIdentifier:previous.longLongValue];
		}
	}

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

// Removes `object` from the old target's inverse edge and marks the target dirty.
// The target may be gone (deleted, or never faulted); the caller still owns the
// forward reference, so a missing target is not an error.
- (void)unlinkInverseForObject:(RptqObject *)object
				  relationship:(MADStoreRelationship *)relationship
					   inverse:(MADStoreRelationship *)inverse
			  targetIdentifier:(int64_t)targetIdentifier {
	if (!inverse || targetIdentifier == 0) return;
	RptqObject *target = [self objectForEntity:relationship.destination identifier:targetIdentifier];
	if (!target) return;
	if (inverse.isToMany) {
		NSMutableArray<NSNumber *> *members = [target.backingObject collectionForName:inverse.name];
		[members removeObject:@(object.identifier)];
	} else {
		[target.backingObject setReference:nil forName:inverse.name];
	}
	[self.dirtyObjects addObject:target];
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

#pragma mark - Importing a query graph

static NSSet<NSString *> *MADStoreImportQueryGraphEntities(void) {
	static NSSet<NSString *> *entities = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		entities = [NSSet setWithArray:@[
			@"RptqQuery",
			@"RptqDatabase",
			@"RptqDatabaseCredentals",
			@"RptqDatabaseSchemaTable",
			@"RptqDatabaseSchemaField",
			@"RptqQueryTable",
			@"RptqQueryField",
			@"RptqQueryLinks",
			@"RptqQueryGroup",
			@"RptqQueryPredicate",
			@"RptqQuerySort",
			@"RptqDocumentSection",
			// The element subentities share RptqDocumentElement's table but are named
			// individually so the flat copy reads each kind's own attributes.
			@"RptqDocumentElementAggregate",
			@"RptqDocumentElementBarcode",
			@"RptqDocumentElementChart",
			@"RptqDocumentElementFormula",
			@"RptqDocumentElementGroupKey",
			@"RptqDocumentElementImage",
			@"RptqDocumentElementLabel",
			@"RptqDocumentElementLabelDataField",
			@"RptqDocumentElementLabelLink",
		]];
	});
	return entities;
}

static NSNumber *MADStoreImportIdentifierForSourceIdentifier(NSNumber *sourceIdentifier,
															 NSString *entity,
															 NSDictionary<NSString *, NSDictionary<NSNumber *, RptqObject *> *> *remap) {
	if (sourceIdentifier == nil || sourceIdentifier.longLongValue == 0) return nil;
	RptqObject *imported = remap[entity][sourceIdentifier];
	return imported != nil ? @(imported.identifier) : nil;
}

static void MADStoreResolveRelativeSQLitePaths(NSDictionary<NSNumber *, RptqObject *> *importedDatabases,
											   NSURL *baseURL) {
	if (baseURL == nil || !baseURL.isFileURL) return;
	for (RptqObject *object in importedDatabases.allValues) {
		if (![object isKindOfClass:[RptqDatabase class]]) continue;
		RptqDatabase *database = (RptqDatabase *)object;
		if (database.databaseDriverTypeEnum != MADDatabaseTypeSqlite3) continue;
		RptqDatabaseCredentals *credential = database.ownedByUser;
		if (credential == nil) continue;
		NSString *host = credential.host ?: @"";
		if (host.length > 0 && [host hasPrefix:@"/"]) continue; // already absolute
		NSString *filename = credential.dbname.length > 0 ? credential.dbname : host.lastPathComponent;
		if (filename.length == 0) continue;
		credential.host = [[baseURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:filename isDirectory:NO].path;
		if (credential.dbname.length == 0) credential.dbname = filename;
	}
}

/// Copies an element's value-type satellites from the source onto the imported element.
/// `awakeFromInsert` already created the imported element's satellites (and border/rect's
/// own sub-satellites); this copies the scalar geometry/typography/format values only.
static void MADStoreCopyElementValueTypes(RptqDocumentElement *source, RptqDocumentElement *imported) {
	if (source.alignment != nil) {
		imported.alignment.horizontal = source.alignment.horizontal;
		imported.alignment.vertical = source.alignment.vertical;
	}
	if (source.border != nil) {
		imported.border.width.top = source.border.width.top;
		imported.border.width.bottom = source.border.width.bottom;
		imported.border.width.left = source.border.width.left;
		imported.border.width.right = source.border.width.right;
		imported.border.style.top = source.border.style.top;
		imported.border.style.bottom = source.border.style.bottom;
		imported.border.style.left = source.border.style.left;
		imported.border.style.right = source.border.style.right;
	}
	if (source.dropPoint != nil) {
		imported.dropPoint.x = source.dropPoint.x;
		imported.dropPoint.y = source.dropPoint.y;
	}
	if (source.margin != nil) {
		imported.margin.top = source.margin.top;
		imported.margin.bottom = source.margin.bottom;
		imported.margin.left = source.margin.left;
		imported.margin.right = source.margin.right;
	}
	if (source.numericFormat != nil) {
		imported.numericFormat.locale = source.numericFormat.locale;
		imported.numericFormat.enabled = source.numericFormat.enabled;
		imported.numericFormat.decimalCount = source.numericFormat.decimalCount;
	}
	if (source.padding != nil) {
		imported.padding.top = source.padding.top;
		imported.padding.bottom = source.padding.bottom;
		imported.padding.left = source.padding.left;
		imported.padding.right = source.padding.right;
	}
	if (source.rect != nil) {
		imported.rect.origin.x = source.rect.origin.x;
		imported.rect.origin.y = source.rect.origin.y;
		imported.rect.size.width = source.rect.size.width;
		imported.rect.size.height = source.rect.size.height;
	}
	if (source.textStyle != nil) {
		imported.textStyle.strikethrough = source.textStyle.strikethrough;
		imported.textStyle.underline = source.textStyle.underline;
		imported.textStyle.italic = source.textStyle.italic;
		imported.textStyle.bold = source.textStyle.bold;
	}
}

- (nullable RptqQuery *)importQueryGraphFromContext:(RptqStoreContext *)sourceContext
							   relativePathBaseURL:(nullable NSURL *)relativePathBaseURL
											  error:(NSError * __autoreleasing *)error {
	if (sourceContext == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADStore"
										  code:1
									  userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No source document to import.", @"Import failed: no source document was supplied.") }];
		}
		return nil;
	}

	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	NSSet<NSString *> *copySet = MADStoreImportQueryGraphEntities();
	NSArray<NSString *> *orderedEntities = [copySet.allObjects sortedArrayUsingSelector:@selector(compare:)];

	// Pass 1: insert a fresh object for every source object, remapping identifiers
	// so two independently authored graphs coexist even with identical ids.
	NSMutableDictionary<NSString *, NSMutableDictionary<NSNumber *, RptqObject *> *> *remap =
		[NSMutableDictionary dictionaryWithCapacity:orderedEntities.count];
	for (NSString *entity in orderedEntities) {
		NSArray<RptqObject *> *sourceObjects = [sourceContext objectsForEntity:entity];
		NSMutableDictionary<NSNumber *, RptqObject *> *bySourceId =
			[NSMutableDictionary dictionaryWithCapacity:sourceObjects.count];
		for (RptqObject *sourceObject in sourceObjects) {
			bySourceId[@(sourceObject.identifier)] = [self insertObjectForEntity:entity identifier:0];
		}
		remap[entity] = bySourceId;
	}

	// Pass 2: copy attributes and edges, remapping every identifier and dropping an
	// edge whose destination is outside the query graph (layout bands, elements, and
	// the source document row).
	for (NSString *entity in orderedEntities) {
		MADStoreEntity *descriptor = [schema entityNamed:entity];
		NSDictionary<NSNumber *, RptqObject *> *bySourceId = remap[entity];
		if (bySourceId.count == 0) continue;
		for (RptqObject *sourceObject in [sourceContext objectsForEntity:entity]) {
			RptqObject *imported = bySourceId[@(sourceObject.identifier)];
			if (imported == nil) continue;

			for (MADStoreAttribute *attribute in descriptor.allAttributes) {
				if ([attribute.name isEqualToString:@"identifier"]) continue;
				id value = [sourceObject.backingObject attributeValue:attribute.name];
				if (value != nil) {
					[imported.backingObject setAttributeValue:value forName:attribute.name];
				}
			}

			for (NSString *name in sourceObject.backingObject.references) {
				MADStoreRelationship *relationship = [descriptor anyRelationshipNamed:name];
				if (relationship == nil || ![copySet containsObject:relationship.destination]) continue;
				[imported.backingObject setReference:
					MADStoreImportIdentifierForSourceIdentifier([sourceObject.backingObject referenceForName:name],
																 relationship.destination, remap)
														  forName:name];
			}

			for (NSString *name in sourceObject.backingObject.collections) {
				MADStoreRelationship *relationship = [descriptor anyRelationshipNamed:name];
				if (relationship == nil || ![copySet containsObject:relationship.destination]) continue;
				NSArray<NSNumber *> *sourceIds = [sourceObject.backingObject existingCollectionForName:name];
				NSMutableArray<NSNumber *> *importedIds = [NSMutableArray arrayWithCapacity:sourceIds.count];
				for (NSNumber *sourceId in sourceIds) {
					NSNumber *importedId = MADStoreImportIdentifierForSourceIdentifier(sourceId,
																					   relationship.destination, remap);
					if (importedId != nil) [importedIds addObject:importedId];
				}
				[[imported.backingObject collectionForName:name] addObjectsFromArray:importedIds];
			}
		}
	}

	// Pass 3: resolve relative SQLite source paths so they name the same file from
	// the destination's location.
	MADStoreResolveRelativeSQLitePaths(remap[@"RptqDatabase"], relativePathBaseURL);

	// Pass 4: copy the layout's surrogate-keyed rows and value-type satellites, which
	// have no identifier and so are out of reach of the flat identifier remap above.
	// The sections and elements themselves were already copied (their attributes,
	// field references, and element-to-element edges), remapped by identifier.  A
	// document-structural section belongs to the source's root, so it is assigned to
	// the imported root here; a group section keeps its remapped `inGroup`; a leaf's
	// section already carries its remapped `ownerQuery`.
	RptqDocument *sourceDocument = [RptqDocument newDocumentReadFromManagedObjectContext:sourceContext];
	RptqQuery *sourceRoot = sourceDocument.rootQuery ?: sourceDocument.mainQuery;
	RptqQuery *importedRoot = sourceRoot != nil ? (RptqQuery *)remap[@"RptqQuery"][@(sourceRoot.identifier)] : nil;

	NSString *sectionEntity = NSStringFromClass([RptqDocumentSection class]);
	NSString *rowEntity = NSStringFromClass([RptqDocumentSectionRows class]);
	for (RptqObject *sourceSectionObject in [sourceContext objectsForEntity:sectionEntity]) {
		RptqDocumentSection *sourceSection = (RptqDocumentSection *)sourceSectionObject;
		RptqDocumentSection *importedSection = (RptqDocumentSection *)remap[sectionEntity][@(sourceSection.identifier)];
		if (importedSection == nil) continue;

		BOOL isDocumentSection = sourceSection.inReport != nil ||
			sourceSection.inReportPageFooter != nil ||
			sourceSection.inReportPageHeader != nil ||
			sourceSection.inReportReportFooter != nil ||
			sourceSection.inReportReportHeader != nil;
		if (isDocumentSection && importedRoot != nil) {
			importedSection.ownerQuery = importedRoot;
		}

		for (RptqDocumentSectionRows *sourceRow in sourceSection.hasRows) {
			RptqDocumentSectionRows *importedRow = (RptqDocumentSectionRows *)[self insertObjectForEntity:rowEntity identifier:0];
			importedRow.layoutHeight = sourceRow.layoutHeight;
			importedRow.rowNumber = sourceRow.rowNumber;
			importedRow.inSection = importedSection;

			for (RptqDocumentElement *sourceElement in sourceRow.hasObjects) {
				RptqDocumentElement *importedElement = (RptqDocumentElement *)remap[sourceElement.entity][@(sourceElement.identifier)];
				if (importedElement == nil) continue;
				MADStoreCopyElementValueTypes(sourceElement, importedElement);
				importedElement.inSectionRow = importedRow;
			}
		}
	}

	// A layoutless source imports with five empty sections: a query that ended up with
	// no structural sections of its own (a source that had no designed layout) gets an
	// authorable layout here, eagerly rather than on its first scoped write.
	for (RptqObject *importedQueryObject in remap[@"RptqQuery"].allValues) {
		RptqQuery *importedQuery = (RptqQuery *)importedQueryObject;
		if (importedQuery.hasLayoutSections.count == 0) {
			[RptqDocumentSection createStructuralSectionsForQuery: importedQuery managedObjectContext: self];
		}
	}

	// The imported databases join the destination document's schema list, so the
	// document owns them and every walk (allQueries, the sidebar, refresh) sees them.
	RptqDocument *destinationDocument = [RptqDocument newDocumentReadFromManagedObjectContext:self];
	if (destinationDocument != nil) {
		for (RptqObject *database in remap[@"RptqDatabase"].allValues) {
			[self addObject:database toRelationshipNamed:@"hasDatabaseSchemas" onObject:destinationDocument];
		}
	}

	// The imported root is the source's explicit root, else its single query (resolved
	// in pass 4 above).
	return sourceRoot != nil ? (RptqQuery *)remap[@"RptqQuery"][@(sourceRoot.identifier)] : nil;
}

@end

