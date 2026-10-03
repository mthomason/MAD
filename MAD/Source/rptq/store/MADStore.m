//
//  MADStore.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "MADStore.h"
#import <sqlite3.h>

NSString * const MADStoreErrorDomain = @"MADStoreErrorDomain";

static NSError *MADStoreError(MADStoreErrorCode code, NSString *message) {
	return [NSError errorWithDomain:MADStoreErrorDomain
							   code:code
						   userInfo:@{ NSLocalizedDescriptionKey: message }];
}

static NSError *MADStoreSQLiteError(sqlite3 *database, NSString *context) {
	NSString *message = [[NSString alloc] initWithFormat:@"%@: %s", context, sqlite3_errmsg(database)];
	return MADStoreError(MADStoreErrorSQLite, message);
}

static MADStoreAttribute *MADStoreFindAttribute(MADStoreEntity *entity, NSString *name) {
	for (MADStoreAttribute *attribute in entity.allAttributes) {
		if ([attribute.name isEqualToString:name]) return attribute;
	}
	return nil;
}

/// The `position` of each child row, keyed by entity name and then by identifier.
/// The reader collects these while it reads the rows and hands them to the ordering
/// pass; it is not keyed by object, because the graph fills in edges between the two
/// and an object-keyed dictionary stops matching once it does.
typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSNumber *, NSNumber *> *> MADStorePositions;

/// Every column the store reads or writes for a table, in a fixed order, with the
/// type each one binds and reads as.
@interface MADStoreColumn : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) MADStoreValueType type;
@property (nonatomic, strong, nullable) MADStoreAttribute *attribute;
@property (nonatomic, strong, nullable) MADStoreRelationship *relationship;
@end

@implementation MADStoreColumn
@end

@interface MADStore ()
@property (nonatomic, strong) MADStoreSchema *schema;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, assign, getter=isOpen) BOOL open;
@property (nonatomic, assign) sqlite3 *database;
@end

@implementation MADStore

+ (instancetype)storeWithURL:(NSURL *)url {
	return [[MADStore alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
	self = [super init];
	if (!self) return nil;
	_url = [url copy];
	_schema = [MADStoreSchema sharedSchema];
	return self;
}

- (void)dealloc {
	[self close];
}

#pragma mark - Opening

- (BOOL)openWithError:(NSError **)error {
	if (self.open) return YES;

	sqlite3 *database = NULL;
	int result = sqlite3_open_v2(self.url.path.fileSystemRepresentation, &database,
								 SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
	if (result != SQLITE_OK) {
		if (error) *error = MADStoreSQLiteError(database, @"Could not open the store");
		if (database) sqlite3_close(database);
		return NO;
	}
	self.database = database;

	// A document is a single file that gets archived, so the rollback journal is the
	// right mode: unlike WAL it leaves nothing in a side file for a reader to miss.
	if (![self execute:@"PRAGMA journal_mode = DELETE;" error:error]) {
		[self close];
		return NO;
	}
	if (![self execute:self.schema.createSchemaSQL error:error]) {
		[self close];
		return NO;
	}

	self.open = YES;
	return YES;
}

- (void)close {
	if (self.database) {
		sqlite3_close(self.database);
		self.database = NULL;
	}
	self.open = NO;
}

- (BOOL)execute:(NSString *)sql error:(NSError **)error {
	char *message = NULL;
	int result = sqlite3_exec(self.database, sql.UTF8String, NULL, NULL, &message);
	if (result == SQLITE_OK) return YES;
	if (error) {
		NSString *text = message ? [NSString stringWithUTF8String:message] : @"unknown error";
		*error = MADStoreError(MADStoreErrorSQLite, text);
	}
	if (message) sqlite3_free(message);
	return NO;
}

#pragma mark - Transactions

- (BOOL)beginTransactionWithError:(NSError **)error {
	return [self execute:@"BEGIN IMMEDIATE TRANSACTION;" error:error];
}

- (BOOL)commitTransactionWithError:(NSError **)error {
	return [self execute:@"COMMIT;" error:error];
}

- (void)rollbackTransaction {
	[self execute:@"ROLLBACK;" error:NULL];
}

#pragma mark - Columns

/// The columns for a table, in read/write order.  A shared table contributes its
/// subentities' attributes and foreign keys too, because any row in it may be of
/// any kind.
- (NSArray<MADStoreColumn *> *)columnsForTable:(MADStoreEntity *)table {
	NSMutableArray<MADStoreColumn *> *columns = [NSMutableArray array];

	MADStoreColumn *identifier = [MADStoreColumn new];
	identifier.name = @"identifier";
	identifier.type = MADStoreValueTypeInteger;
	[columns addObject:identifier];

	if (table.subentities.count > 0) {
		MADStoreColumn *kind = [MADStoreColumn new];
		kind.name = @"kind";
		kind.type = MADStoreValueTypeText;
		[columns addObject:kind];
	}

	// A shared table carries each column once, however many of its kinds declare it.
	NSMutableArray<MADStoreAttribute *> *attributes = [NSMutableArray arrayWithArray:table.allAttributes];
	for (MADStoreEntity *subentity in table.subentities) {
		[attributes addObjectsFromArray:subentity.attributes];
	}
	NSMutableSet<NSString *> *seen = [NSMutableSet setWithCapacity:attributes.count];
	for (MADStoreAttribute *attribute in attributes) {
		// The model's own `identifier` attribute is the row key; there is no second
		// column for it, and no second place to keep it.
		if ([attribute.name isEqualToString:@"identifier"]) continue;
		if ([seen containsObject:attribute.name]) continue;
		[seen addObject:attribute.name];
		MADStoreColumn *column = [MADStoreColumn new];
		column.name = attribute.name;
		column.type = attribute.type;
		column.attribute = attribute;
		[columns addObject:column];
	}

	NSMutableArray<MADStoreRelationship *> *relationships = [NSMutableArray arrayWithArray:table.allRelationships];
	for (MADStoreEntity *subentity in table.subentities) {
		[relationships addObjectsFromArray:subentity.relationships];
	}
	[seen removeAllObjects];
	for (MADStoreRelationship *relationship in relationships) {
		if (!relationship.ownsForeignKey) continue;
		if ([seen containsObject:relationship.column]) continue;
		[seen addObject:relationship.column];
		MADStoreColumn *column = [MADStoreColumn new];
		column.name = relationship.column;
		column.type = MADStoreValueTypeInteger;
		column.relationship = relationship;
		[columns addObject:column];
	}

	if (table.hasPositionColumn) {
		MADStoreColumn *position = [MADStoreColumn new];
		position.name = MADStorePositionColumn;
		position.type = MADStoreValueTypeInteger;
		[columns addObject:position];
	}

	return columns;
}

#pragma mark - Reading

static id MADStoreReadColumn(sqlite3_stmt *statement, int index, MADStoreValueType type) {
	if (sqlite3_column_type(statement, index) == SQLITE_NULL) return nil;
	switch (type) {
		case MADStoreValueTypeInteger:
			return @(sqlite3_column_int64(statement, index));
		case MADStoreValueTypeReal:
			return @(sqlite3_column_double(statement, index));
		case MADStoreValueTypeText: {
			const unsigned char *text = sqlite3_column_text(statement, index);
			return text ? [NSString stringWithUTF8String:(const char *)text] : nil;
		}
		case MADStoreValueTypeBlob: {
			const void *bytes = sqlite3_column_blob(statement, index);
			int length = sqlite3_column_bytes(statement, index);
			return (bytes && length > 0) ? [NSData dataWithBytes:bytes length:(NSUInteger)length] : nil;
		}
	}
	return nil;
}

/// Reads rows of one table.  Objects are named by their `kind` when the table is
/// shared, so an element comes back as RptqDocumentElementLabel and not as the
/// table it lives in.
- (NSArray<MADStoreObject *> *)readTable:(MADStoreEntity *)table
								   where:(nullable NSString *)where
								bindings:(NSArray *)bindings
							   positions:(MADStorePositions *)positions
								   error:(NSError **)error {
	NSArray<MADStoreColumn *> *columns = [self columnsForTable:table];

	NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:columns.count];
	for (MADStoreColumn *column in columns) {
		[names addObject:[[NSString alloc] initWithFormat:@"\"%@\"", column.name]];
	}
	NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT %@ FROM \"%@\"",
							[names componentsJoinedByString:@", "], table.name];
	if (where) [sql appendFormat:@" WHERE %@", where];
	[sql appendString:@";"];

	sqlite3_stmt *statement = NULL;
	if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
		if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the read");
		return @[];
	}
	for (NSUInteger index = 0; index < bindings.count; index++) {
		id binding = bindings[index];
		if ([binding isKindOfClass:[NSString class]]) {
			sqlite3_bind_text(statement, (int)index + 1, [binding UTF8String], -1, SQLITE_TRANSIENT);
		} else {
			sqlite3_bind_int64(statement, (int)index + 1, [binding longLongValue]);
		}
	}

	BOOL hasKind = table.subentities.count > 0;
	NSMutableArray<MADStoreObject *> *objects = [NSMutableArray array];
	while (sqlite3_step(statement) == SQLITE_ROW) {
		int64_t identifier = sqlite3_column_int64(statement, 0);
		NSString *entityName = table.name;
		if (hasKind) {
			const unsigned char *kind = sqlite3_column_text(statement, 1);
			if (kind) entityName = [NSString stringWithUTF8String:(const char *)kind];
		}

		MADStoreObject *object = [MADStoreObject objectWithEntity:entityName identifier:identifier];
		for (NSUInteger index = 0; index < columns.count; index++) {
			MADStoreColumn *column = columns[index];
			id value = MADStoreReadColumn(statement, (int)index, column.type);
			if (!value) continue;
			if (column.attribute) {
				[object setAttributeValue:value forName:column.attribute.name];
			} else if (column.relationship) {
				[object setReference:value forName:column.relationship.name];
			} else if ([column.name isEqualToString:MADStorePositionColumn]) {
				// Keyed by name and identifier rather than by the object: the graph
				// goes on to fill in edges, and a dictionary keyed by value equality
				// would stop matching the moment it did.
				NSMutableDictionary<NSNumber *, NSNumber *> *byIdentifier = positions[object.entity];
				if (!byIdentifier) {
					byIdentifier = [NSMutableDictionary dictionary];
					positions[object.entity] = byIdentifier;
				}
				byIdentifier[@(object.identifier)] = value;
			}
		}
		[objects addObject:object];
	}
	sqlite3_finalize(statement);
	return objects;
}

- (MADStoreObject *)objectForEntity:(NSString *)entityName
						 identifier:(int64_t)identifier
							  error:(NSError **)error {
	if (!self.open) {
		if (error) *error = MADStoreError(MADStoreErrorNotOpen, @"The store is not open");
		return nil;
	}
	MADStoreEntity *entity = [self.schema entityNamed:entityName];
	if (!entity) {
		if (error) *error = MADStoreError(MADStoreErrorUnknownEntity, entityName);
		return nil;
	}

	// A subentity's rows live in its table, and are told apart by `kind`.
	MADStoreEntity *table = entity.isSubentity ? [self.schema entityForTable:entity.table] : entity;
	NSString *where = entity.isSubentity ? @"\"identifier\" = ? AND \"kind\" = ?" : @"\"identifier\" = ?";
	NSArray *bindings = entity.isSubentity ? @[ @(identifier), entity.name ] : @[ @(identifier) ];
	MADStorePositions *positions = [NSMutableDictionary dictionary];
	NSArray<MADStoreObject *> *objects = [self readTable:table
												   where:where
												bindings:bindings
											   positions:positions
												   error:error];
	return objects.firstObject;
}

- (NSArray<MADStoreObject *> *)objectsForEntity:(NSString *)entityName error:(NSError **)error {
	if (!self.open) {
		if (error) *error = MADStoreError(MADStoreErrorNotOpen, @"The store is not open");
		return @[];
	}
	MADStoreEntity *entity = [self.schema entityNamed:entityName];
	if (!entity) {
		if (error) *error = MADStoreError(MADStoreErrorUnknownEntity, entityName);
		return @[];
	}
	MADStoreEntity *table = entity.isSubentity ? [self.schema entityForTable:entity.table] : entity;
	NSString *where = entity.isSubentity ? @"\"kind\" = ?" : nil;
	NSArray *bindings = entity.isSubentity ? @[ entity.name ] : @[];
	MADStorePositions *positions = [NSMutableDictionary dictionary];
	return [self readTable:table where:where bindings:bindings positions:positions error:error];
}

/// Many-to-many edges live in a join table and nowhere else, so they have to be
/// read back separately.  Both ends are filled, and an edge whose other end is not
/// in the graph is dropped -- a part loaded on its own legitimately dangles.
- (void)readJoinTablesIntoGraph:(MADStoreGraph *)graph error:(NSError **)error {
	NSMutableSet<NSString *> *read = [NSMutableSet set];
	for (MADStoreEntity *entity in self.schema.entities) {
		for (MADStoreRelationship *relationship in entity.relationships) {
			if (!relationship.joinTable || [read containsObject:relationship.joinTable]) continue;
			[read addObject:relationship.joinTable];

			MADStoreEntity *destination = [self.schema entityNamed:relationship.destination];
			MADStoreRelationship *inverse = [destination anyRelationshipNamed:relationship.inverse];
			if (!inverse) continue;

			NSString *sql = [[NSString alloc] initWithFormat:@"SELECT \"%@\", \"%@\" FROM \"%@\";",
							 relationship.joinColumn, inverse.joinColumn, relationship.joinTable];
			sqlite3_stmt *statement = NULL;
			if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
				if (error) *error = MADStoreSQLiteError(self.database, @"Could not read a join table");
				return;
			}
			while (sqlite3_step(statement) == SQLITE_ROW) {
				int64_t mine = sqlite3_column_int64(statement, 0);
				int64_t theirs = sqlite3_column_int64(statement, 1);
				MADStoreObject *owner = [graph objectForEntity:entity.name identifier:mine];
				MADStoreObject *member = [graph objectForEntity:destination.name identifier:theirs];
				if (!owner || !member) continue;
				NSMutableArray<NSNumber *> *forward = [owner collectionForName:relationship.name];
				if (![forward containsObject:@(theirs)]) [forward addObject:@(theirs)];
				NSMutableArray<NSNumber *> *backward = [member collectionForName:inverse.name];
				if (![backward containsObject:@(mine)]) [backward addObject:@(mine)];
			}
			sqlite3_finalize(statement);
		}
	}
}

/// The reader's wiring pass: an ordered to-many is ordered by the child's
/// `position` column, which only the rows themselves know.
- (void)orderCollectionsInGraph:(MADStoreGraph *)graph
					  positions:(MADStorePositions *)positions {
	for (MADStoreEntity *table in self.schema.tables) {
		for (MADStoreRelationship *relationship in table.allRelationships) {
			if (!relationship.isToMany || !relationship.isOrdered) continue;
			MADStoreEntity *childEntity = [self.schema entityNamed:relationship.destination];
			NSArray<MADStoreObject *> *children = [graph objectsForEntity:childEntity.name];
			if (children.count == 0) {
				// A shared table's rows carry their own entity names.
				NSMutableArray<MADStoreObject *> *gathered = [NSMutableArray array];
				for (NSString *name in graph.entityNames) {
					MADStoreEntity *named = [self.schema entityNamed:name];
					if ([named.table isEqualToString:childEntity.name]) {
						[gathered addObjectsFromArray:[graph objectsForEntity:name]];
					}
				}
				children = gathered;
			}
			if (children.count == 0) continue;

			for (MADStoreObject *parent in [graph objectsForEntity:table.name]) {
				NSMutableArray<MADStoreObject *> *members = [NSMutableArray array];
				for (MADStoreObject *child in children) {
					NSNumber *owner = [child referenceForName:relationship.inverse];
					if (owner.longLongValue == parent.identifier) [members addObject:child];
				}
				[members sortUsingComparator:^NSComparisonResult(MADStoreObject *a, MADStoreObject *b) {
					int64_t left = [positions[a.entity][@(a.identifier)] longLongValue];
					int64_t right = [positions[b.entity][@(b.identifier)] longLongValue];
					if (left < right) return NSOrderedAscending;
					if (left > right) return NSOrderedDescending;
					return NSOrderedSame;
				}];
				// An empty collection and no collection at all are the same thing to
				// the model, so do not conjure one up for a parent that has none.
				if (members.count == 0 && ![parent existingCollectionForName:relationship.name]) continue;
				NSMutableArray<NSNumber *> *identifiers = [parent collectionForName:relationship.name];
				[identifiers removeAllObjects];
				for (MADStoreObject *child in members) [identifiers addObject:@(child.identifier)];
			}
		}
	}
}

- (MADStoreGraph *)graphForEntityNames:(NSArray<NSString *> *)entityNames error:(NSError **)error {
	if (!self.open) {
		if (error) *error = MADStoreError(MADStoreErrorNotOpen, @"The store is not open");
		return nil;
	}

	NSMutableArray<MADStoreEntity *> *tables = [NSMutableArray array];
	NSMutableSet<NSString *> *seen = [NSMutableSet set];
	for (NSString *name in entityNames) {
		MADStoreEntity *entity = [self.schema entityNamed:name];
		if (!entity) {
			if (error) *error = MADStoreError(MADStoreErrorUnknownEntity, name);
			return nil;
		}
		if ([seen containsObject:entity.table]) continue;
		[seen addObject:entity.table];
		[tables addObject:[self.schema entityForTable:entity.table]];
	}

	MADStoreGraph *graph = [MADStoreGraph new];
	MADStorePositions *positions = [NSMutableDictionary dictionary];
	for (MADStoreEntity *table in tables) {
		for (MADStoreObject *object in [self readTable:table where:nil bindings:@[] positions:positions error:error]) {
			[graph addObject:object];
		}
	}
	[self readJoinTablesIntoGraph:graph error:error];
	[self orderCollectionsInGraph:graph positions:positions];
	return [graph graphByCompletingInverses];
}

- (MADStoreGraph *)graphForPart:(MADStorePart)part error:(NSError **)error {
	NSMutableArray<NSString *> *names = [NSMutableArray array];
	for (MADStoreEntity *table in self.schema.tables) {
		if ([self.schema entityName:table.name belongsToPart:part]) [names addObject:table.name];
	}
	return [self graphForEntityNames:names error:error];
}

- (MADStoreGraph *)allObjectsWithError:(NSError **)error {
	NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:self.schema.tables.count];
	for (MADStoreEntity *table in self.schema.tables) [names addObject:table.name];
	return [self graphForEntityNames:names error:error];
}

#pragma mark - Writing

static BOOL MADStoreBindColumn(sqlite3_stmt *statement, int index, MADStoreColumn *column, id value) {
	if (!value) return sqlite3_bind_null(statement, index) == SQLITE_OK;
	switch (column.type) {
		case MADStoreValueTypeInteger:
			return sqlite3_bind_int64(statement, index, [value longLongValue]) == SQLITE_OK;
		case MADStoreValueTypeReal:
			return sqlite3_bind_double(statement, index, [value doubleValue]) == SQLITE_OK;
		case MADStoreValueTypeText:
			return sqlite3_bind_text(statement, index, [[value description] UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK;
		case MADStoreValueTypeBlob: {
			NSData *data = [value isKindOfClass:[NSData class]] ? value : nil;
			if (!data) return sqlite3_bind_null(statement, index) == SQLITE_OK;
			return sqlite3_bind_blob(statement, index, data.bytes, (int)data.length, SQLITE_TRANSIENT) == SQLITE_OK;
		}
	}
	return NO;
}

/// The identifier a satellite row is keyed by.  The model gives those entities no
/// identifier, so the store hands out the next one past whatever the table holds.
- (int64_t)nextIdentifierForTable:(NSString *)table error:(NSError **)error {
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT MAX(\"identifier\") FROM \"%@\";", table];
	sqlite3_stmt *statement = NULL;
	if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
		if (error) *error = MADStoreSQLiteError(self.database, @"Could not allocate an identifier");
		return 1;
	}
	int64_t maximum = 0;
	if (sqlite3_step(statement) == SQLITE_ROW) maximum = sqlite3_column_int64(statement, 0);
	sqlite3_finalize(statement);
	return maximum + 1;
}

- (BOOL)writeRowForObject:(MADStoreObject *)object error:(NSError **)error {
	MADStoreEntity *entity = [self.schema entityNamed:object.entity];
	if (!entity) {
		if (error) *error = MADStoreError(MADStoreErrorUnknownEntity, object.entity);
		return NO;
	}

	NSMutableArray<MADStoreColumn *> *columns = [NSMutableArray array];
	NSMutableArray *values = [NSMutableArray array];

	MADStoreColumn *identifier = [MADStoreColumn new];
	identifier.name = @"identifier";
	identifier.type = MADStoreValueTypeInteger;
	[columns addObject:identifier];
	[values addObject:@(object.identifier)];

	// A subentity writes the `kind` of the table it shares, not of itself.
	MADStoreEntity *owner = entity.isSubentity ? [self.schema entityForTable:entity.table] : entity;
	if (owner.subentities.count > 0) {
		MADStoreColumn *kind = [MADStoreColumn new];
		kind.name = @"kind";
		kind.type = MADStoreValueTypeText;
		[columns addObject:kind];
		[values addObject:object.entity];
	}

	for (NSString *name in [object.values.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
		MADStoreAttribute *attribute = MADStoreFindAttribute(entity, name);
		if (!attribute) {
			if (error) {
				*error = MADStoreError(MADStoreErrorUnknownAttribute,
									   [[NSString alloc] initWithFormat:@"%@ has no attribute %@", entity.name, name]);
			}
			return NO;
		}
		// The model's `identifier` attribute is the row key, written once as the
		// primary key above; a value here would be a second, contradictory identity.
		if ([attribute.name isEqualToString:@"identifier"]) {
			if (error) {
				*error = MADStoreError(MADStoreErrorUnwritableAttribute,
									   [[NSString alloc] initWithFormat:@"%@ %lld carries an identifier value",
										object.entity, (long long)object.identifier]);
			}
			return NO;
		}
		MADStoreColumn *column = [MADStoreColumn new];
		column.name = attribute.name;
		column.type = attribute.type;
		[columns addObject:column];
		[values addObject:object.values[name] ?: [NSNull null]];
	}

	// Non-optional attributes carry their model defaults from insert time
	// (insertObjectForEntity: applies them, the way Core Data did); a row that
	// somehow lacks one fails the NOT NULL constraint loudly instead of being
	// quietly filled with an invented value here.

	for (MADStoreRelationship *relationship in entity.allRelationships) {
		if (relationship.isToMany || !relationship.ownsForeignKey) continue;
		NSNumber *target = [object referenceForName:relationship.name];
		if (!target) continue;
		MADStoreColumn *column = [MADStoreColumn new];
		column.name = relationship.column;
		column.type = MADStoreValueTypeInteger;
		[columns addObject:column];
		[values addObject:target];
	}

	NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:columns.count];
	NSMutableArray<NSString *> *placeholders = [NSMutableArray arrayWithCapacity:columns.count];
	for (MADStoreColumn *column in columns) {
		[names addObject:[[NSString alloc] initWithFormat:@"\"%@\"", column.name]];
		[placeholders addObject:@"?"];
	}
	NSString *sql = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO \"%@\" (%@) VALUES (%@);",
					 entity.table,
					 [names componentsJoinedByString:@", "],
					 [placeholders componentsJoinedByString:@", "]];

	sqlite3_stmt *statement = NULL;
	if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
		if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the write");
		return NO;
	}
	BOOL bound = YES;
	for (NSUInteger index = 0; index < columns.count && bound; index++) {
		id value = values[index] == [NSNull null] ? nil : values[index];
		bound = MADStoreBindColumn(statement, (int)index + 1, columns[index], value);
	}
	int result = bound ? sqlite3_step(statement) : SQLITE_ERROR;
	if (result != SQLITE_DONE) {
		if (error) {
			*error = MADStoreSQLiteError(self.database,
										 [[NSString alloc] initWithFormat:@"Could not write %@ %lld",
										  object.entity, (long long)object.identifier]);
		}
	}
	sqlite3_finalize(statement);
	return result == SQLITE_DONE;
}

- (BOOL)writePositionsForGraph:(MADStoreGraph *)graph error:(NSError **)error {
	for (MADStoreEntity *table in self.schema.tables) {
		for (MADStoreRelationship *relationship in table.allRelationships) {
			if (!relationship.isToMany || !relationship.isOrdered) continue;
			MADStoreEntity *childEntity = [self.schema entityNamed:relationship.destination];
			NSString *sql = [[NSString alloc] initWithFormat:@"UPDATE \"%@\" SET \"%@\" = ? WHERE \"identifier\" = ?;",
							 childEntity.table, MADStorePositionColumn];
			sqlite3_stmt *statement = NULL;
			if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
				if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the ordering");
				return NO;
			}
			for (MADStoreObject *parent in [graph objectsForEntity:table.name]) {
				NSArray<NSNumber *> *members = [parent existingCollectionForName:relationship.name];
				for (NSUInteger index = 0; index < members.count; index++) {
					sqlite3_reset(statement);
					sqlite3_bind_int64(statement, 1, (sqlite3_int64)index);
					sqlite3_bind_int64(statement, 2, members[index].longLongValue);
					if (sqlite3_step(statement) != SQLITE_DONE) {
						if (error) *error = MADStoreSQLiteError(self.database, @"Could not order a relationship");
						sqlite3_finalize(statement);
						return NO;
					}
				}
			}
			sqlite3_finalize(statement);
		}
	}
	return YES;
}

- (BOOL)writeJoinTablesForGraph:(MADStoreGraph *)graph error:(NSError **)error {
	NSMutableSet<NSString *> *cleared = [NSMutableSet set];
	for (MADStoreEntity *entity in self.schema.entities) {
		for (MADStoreRelationship *relationship in entity.relationships) {
			if (!relationship.joinTable || [cleared containsObject:relationship.joinTable]) continue;
			[cleared addObject:relationship.joinTable];
			if (![self execute:[[NSString alloc] initWithFormat:@"DELETE FROM \"%@\";", relationship.joinTable]
						error:error]) {
				return NO;
			}
		}
	}

	// Walk every object once and write the edges it holds.  Both ends write the same
	// row with the columns swapped, and INSERT OR IGNORE collapses the pair.
	for (MADStoreObject *object in [graph allObjects]) {
		MADStoreEntity *entity = [self.schema entityNamed:object.entity];
		for (MADStoreRelationship *relationship in entity.allRelationships) {
			if (!relationship.joinTable) continue;
			NSArray<NSNumber *> *members = [object existingCollectionForName:relationship.name];
			if (members.count == 0) continue;
			MADStoreEntity *destination = [self.schema entityNamed:relationship.destination];
			MADStoreRelationship *inverse = [destination anyRelationshipNamed:relationship.inverse];
			if (!inverse) continue;

			NSString *sql = [[NSString alloc] initWithFormat:@"INSERT OR IGNORE INTO \"%@\" (\"%@\", \"%@\") VALUES (?, ?);",
							 relationship.joinTable, relationship.joinColumn, inverse.joinColumn];
			sqlite3_stmt *statement = NULL;
			if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
				if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the join table write");
				return NO;
			}
			for (NSNumber *member in members) {
				sqlite3_reset(statement);
				sqlite3_bind_int64(statement, 1, object.identifier);
				sqlite3_bind_int64(statement, 2, member.longLongValue);
				if (sqlite3_step(statement) != SQLITE_DONE) {
					if (error) *error = MADStoreSQLiteError(self.database, @"Could not write a join row");
					sqlite3_finalize(statement);
					return NO;
				}
			}
			sqlite3_finalize(statement);
		}
	}
	return YES;
}

- (MADStoreGraph *)graphByAssigningSurrogates:(MADStoreGraph *)graph error:(NSError **)error {
	MADStoreGraph *resolved = [MADStoreGraph new];
	NSMutableDictionary<NSString *, NSNumber *> *nextIdentifier = [NSMutableDictionary dictionary];
	for (MADStoreObject *object in [graph allObjects]) {
		MADStoreEntity *entity = [self.schema entityNamed:object.entity];
		if (!entity.hasModelIdentifier && object.identifier == 0) {
			NSNumber *next = nextIdentifier[entity.table];
			if (!next) next = @([self nextIdentifierForTable:entity.table error:error]);
			object.identifier = next.longLongValue;
			nextIdentifier[entity.table] = @(next.longLongValue + 1);
		}
		[resolved addObject:object];
	}
	return resolved;
}

- (BOOL)deleteAllInTransactionWithError:(NSError **)error {
	for (MADStoreEntity *table in self.schema.tables) {
		if (![self execute:[[NSString alloc] initWithFormat:@"DELETE FROM \"%@\";", table.name] error:error]) {
			return NO;
		}
	}
	for (MADStoreEntity *entity in self.schema.entities) {
		for (MADStoreRelationship *relationship in entity.relationships) {
			if (!relationship.joinTable) continue;
			if (![self execute:[[NSString alloc] initWithFormat:@"DELETE FROM \"%@\";", relationship.joinTable]
						error:error]) {
				return NO;
			}
		}
	}
	return YES;
}

- (BOOL)writeGraph:(MADStoreGraph *)graph error:(NSError **)error {
	return [self writeGraph:graph replacingAll:NO error:error];
}

- (BOOL)writeGraph:(MADStoreGraph *)graph replacingAll:(BOOL)replacingAll error:(NSError **)error {
	if (!self.open) {
		if (error) *error = MADStoreError(MADStoreErrorNotOpen, @"The store is not open");
		return NO;
	}

	// Work on the reader's canonical form, then resolve the identifiers the model
	// does not supply.  Foreign keys are declared in the schema but not enforced:
	// the writer's ordering is not a guarantee, and the tests are what hold the
	// graph together.
	MADStoreGraph *complete = [graph graphByCompletingInverses];
	MADStoreGraph *resolved = [self graphByAssigningSurrogates:complete error:error];

	if (![self beginTransactionWithError:error]) return NO;
	if (replacingAll && ![self deleteAllInTransactionWithError:error]) {
		[self rollbackTransaction];
		return NO;
	}
	for (MADStoreObject *object in [resolved allObjects]) {
		if (![self writeRowForObject:object error:error]) {
			[self rollbackTransaction];
			return NO;
		}
	}
	if (![self writePositionsForGraph:resolved error:error] ||
		![self writeJoinTablesForGraph:resolved error:error] ||
		![self commitTransactionWithError:error]) {
		[self rollbackTransaction];
		return NO;
	}
	return YES;
}

- (BOOL)writeObject:(MADStoreObject *)object error:(NSError **)error {
	MADStoreGraph *graph = [MADStoreGraph new];
	[graph addObject:object];
	return [self writeGraph:graph error:error];
}

#pragma mark - Incremental writing

/// Deletes the named row's half of every join table its entity participates in, so
/// a deleted row cannot leave join rows behind the full rewrite never produced.
- (BOOL)deleteJoinRowsForObject:(MADStoreObject *)object error:(NSError **)error {
	MADStoreEntity *entity = [self.schema entityNamed:object.entity];
	MADStoreEntity *owner = entity.isSubentity ? [self.schema entityForTable:entity.table] : entity;
	for (MADStoreRelationship *relationship in owner.allRelationships) {
		if (!relationship.joinTable) continue;
		NSString *sql = [[NSString alloc] initWithFormat:@"DELETE FROM \"%@\" WHERE \"%@\" = ?;",
						 relationship.joinTable, relationship.joinColumn];
		sqlite3_stmt *statement = NULL;
		if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
			if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the join delete");
			return NO;
		}
		sqlite3_bind_int64(statement, 1, object.identifier);
		int result = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if (result != SQLITE_DONE) {
			if (error) *error = MADStoreSQLiteError(self.database, @"Could not delete the join rows");
			return NO;
		}
	}
	return YES;
}

/// Sets each member's `position` column from the parent's ordered edge list, for
/// the named parents only; other parents' members keep their positions.
- (BOOL)writePositionsForObjects:(NSArray<MADStoreObject *> *)parents error:(NSError **)error {
	for (MADStoreObject *parent in parents) {
		MADStoreEntity *entity = [self.schema entityNamed:parent.entity];
		MADStoreEntity *owner = entity.isSubentity ? [self.schema entityForTable:entity.table] : entity;
		for (MADStoreRelationship *relationship in owner.allRelationships) {
			if (!relationship.isToMany || !relationship.isOrdered) continue;
			MADStoreEntity *childEntity = [self.schema entityNamed:relationship.destination];
			NSString *sql = [[NSString alloc] initWithFormat:@"UPDATE \"%@\" SET \"%@\" = ? WHERE \"identifier\" = ?;",
							 childEntity.table, MADStorePositionColumn];
			sqlite3_stmt *statement = NULL;
			if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
				if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the ordering");
				return NO;
			}
			NSArray<NSNumber *> *members = [parent existingCollectionForName:relationship.name];
			for (NSUInteger index = 0; index < members.count; index++) {
				sqlite3_reset(statement);
				sqlite3_bind_int64(statement, 1, (sqlite3_int64)index);
				sqlite3_bind_int64(statement, 2, members[index].longLongValue);
				if (sqlite3_step(statement) != SQLITE_DONE) {
					if (error) *error = MADStoreSQLiteError(self.database, @"Could not order a relationship");
					sqlite3_finalize(statement);
					return NO;
				}
			}
			sqlite3_finalize(statement);
		}
	}
	return YES;
}

/// Rebuilds the named rows' half of every join table they participate in.  Each
/// object rewrites its own rows (INSERT OR IGNORE collapses the two halves), and
/// an object that holds no members ends with no rows.
- (BOOL)writeJoinRowsForObjects:(NSArray<MADStoreObject *> *)objects error:(NSError **)error {
	for (MADStoreObject *object in objects) {
		MADStoreEntity *entity = [self.schema entityNamed:object.entity];
		MADStoreEntity *owner = entity.isSubentity ? [self.schema entityForTable:entity.table] : entity;
		for (MADStoreRelationship *relationship in owner.allRelationships) {
			if (!relationship.joinTable) continue;
			if (![self deleteJoinRowsForObject:object error:error]) return NO;

			NSArray<NSNumber *> *members = [object existingCollectionForName:relationship.name];
			if (members.count == 0) continue;
			MADStoreEntity *destination = [self.schema entityNamed:relationship.destination];
			MADStoreRelationship *inverse = [destination anyRelationshipNamed:relationship.inverse];
			if (!inverse) continue;

			NSString *sql = [[NSString alloc] initWithFormat:@"INSERT OR IGNORE INTO \"%@\" (\"%@\", \"%@\") VALUES (?, ?);",
							 relationship.joinTable, relationship.joinColumn, inverse.joinColumn];
			sqlite3_stmt *statement = NULL;
			if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
				if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the join table write");
				return NO;
			}
			for (NSNumber *member in members) {
				sqlite3_reset(statement);
				sqlite3_bind_int64(statement, 1, object.identifier);
				sqlite3_bind_int64(statement, 2, member.longLongValue);
				if (sqlite3_step(statement) != SQLITE_DONE) {
					if (error) *error = MADStoreSQLiteError(self.database, @"Could not write a join row");
					sqlite3_finalize(statement);
					return NO;
				}
			}
			sqlite3_finalize(statement);
		}
	}
	return YES;
}

- (BOOL)writeObjects:(NSArray<MADStoreObject *> *)objects
	 deletingObjects:(NSArray<MADStoreObject *> *)deletedObjects
			   error:(NSError **)error {
	if (!self.open) {
		if (error) *error = MADStoreError(MADStoreErrorNotOpen, @"The store is not open");
		return NO;
	}
	if (objects.count == 0 && deletedObjects.count == 0) return YES;

	// Resolve the identifiers the model does not supply before anything is written,
	// so the rows land under the keys the reader will look them up by.
	MADStoreGraph *graph = [MADStoreGraph new];
	for (MADStoreObject *object in objects) [graph addObject:object];
	MADStoreGraph *resolved = [self graphByAssigningSurrogates:graph error:error];
	if (!resolved) return NO;

	if (![self beginTransactionWithError:error]) return NO;
	for (MADStoreObject *deleted in deletedObjects) {
		if (![self deleteObjectForEntity:deleted.entity identifier:deleted.identifier error:error] ||
			![self deleteJoinRowsForObject:deleted error:error]) {
			[self rollbackTransaction];
			return NO;
		}
	}
	for (MADStoreObject *object in [resolved allObjects]) {
		if (![self writeRowForObject:object error:error]) {
			[self rollbackTransaction];
			return NO;
		}
	}
	if (![self writePositionsForObjects:resolved.allObjects error:error] ||
		![self writeJoinRowsForObjects:resolved.allObjects error:error] ||
		![self commitTransactionWithError:error]) {
		[self rollbackTransaction];
		return NO;
	}
	return YES;
}

- (BOOL)deleteObjectForEntity:(NSString *)entityName identifier:(int64_t)identifier error:(NSError **)error {
	if (!self.open) {
		if (error) *error = MADStoreError(MADStoreErrorNotOpen, @"The store is not open");
		return NO;
	}
	MADStoreEntity *entity = [self.schema entityNamed:entityName];
	if (!entity) {
		if (error) *error = MADStoreError(MADStoreErrorUnknownEntity, entityName);
		return NO;
	}
	// A subentity shares its table with its siblings, so it has to name itself: an
	// identifier alone would delete whichever kind happened to sit on that row.
	NSString *where = entity.isSubentity ? @"\"identifier\" = ? AND \"kind\" = ?" : @"\"identifier\" = ?";
	NSString *sql = [[NSString alloc] initWithFormat:@"DELETE FROM \"%@\" WHERE %@;", entity.table, where];
	sqlite3_stmt *statement = NULL;
	if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
		if (error) *error = MADStoreSQLiteError(self.database, @"Could not prepare the delete");
		return NO;
	}
	sqlite3_bind_int64(statement, 1, identifier);
	if (entity.isSubentity) {
		sqlite3_bind_text(statement, 2, entity.name.UTF8String, -1, SQLITE_TRANSIENT);
	}
	int result = sqlite3_step(statement);
	sqlite3_finalize(statement);
	if (result != SQLITE_DONE) {
		if (error) *error = MADStoreSQLiteError(self.database, @"Could not delete the row");
		return NO;
	}
	return YES;
}

- (BOOL)deleteAllObjectsWithError:(NSError **)error {
	if (!self.open) {
		if (error) *error = MADStoreError(MADStoreErrorNotOpen, @"The store is not open");
		return NO;
	}
	if (![self beginTransactionWithError:error]) return NO;
	if (![self deleteAllInTransactionWithError:error]) {
		[self rollbackTransaction];
		return NO;
	}
	return [self commitTransactionWithError:error];
}

@end
