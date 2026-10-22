//
//  MADStoreConverterTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the bridge from a legacy Core Data `.mad` to the portable store.
//  The fixtures are the two shipping samples, so what is asserted here is asserted
//  about documents a user can actually open: convert, read back, and compare the
//  two graphs -- and, alongside them, the same facts counted straight out of Core
//  Data, so a row the converter never looked at cannot pass by agreeing with
//  itself.  Only the transformable case is hand-built, because neither sample has
//  a colour, an image or a locale set anywhere in it.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import <sqlite3.h>
#import <UIKit/UIKit.h>

#import "MADStoreConverter.h"
#import <MAD/MADStore.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/MADStoreObject.h>
#import <MAD/MADStoreSchema.h>

@interface MADStoreConverterTests : XCTestCase
@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSURL *directory;
@end

@implementation MADStoreConverterTests

#pragma mark - Lifecycle

- (void)setUp {
	[super setUp];
	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD" withExtension:@"momd"];
	XCTAssertNotNil(momdURL, @"MAD.momd was not compiled into the test bundle.");
	self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];

	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	self.directory = [NSURL fileURLWithPath:directory isDirectory:YES];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	self.model = nil;
	[super tearDown];
}

#pragma mark - Helpers

- (NSURL *)sampleURLNamed:(NSString *)name {
	NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:name withExtension:@"mad"];
	XCTAssertNotNil(url, @"%@.mad was not copied into the test bundle.", name);
	return url;
}

/// The legacy document itself, opened the way the converter opens it.  Core Data
/// holds the rows; what the converter does with them is the thing under test.
- (NSManagedObjectContext *)legacyContextForSample:(NSString *)name {
	NSError *error = nil;
	NSManagedObjectContext *context =
		[MADStoreConverter legacyContextForDocumentAtURL:[self sampleURLNamed:name]
											 extractedTo:[self.directory URLByAppendingPathComponent:name isDirectory:YES]
												   model:self.model
												   error:&error];
	XCTAssertNotNil(context, @"opening %@ failed: %@", name, error);
	return context;
}

/// Converts one of the shipping samples and hands back both the graph that was
/// written and what the store reads back out of it.
- (void)convertSample:(NSString *)name
			  written:(MADStoreGraph **)written
				 read:(MADStoreGraph **)read {
	NSURL *storeURL = [self.directory URLByAppendingPathComponent:
					   [[NSString alloc] initWithFormat:@"%@.sqlite", name]];
	NSError *error = nil;
	MADStoreGraph *graph = [MADStoreConverter convertDocumentAtURL:[self sampleURLNamed:name]
													  toStoreAtURL:storeURL
															 model:self.model
															 error:&error];
	XCTAssertNotNil(graph, @"converting %@ failed: %@", name, error);
	if (!graph) return;

	MADStore *store = [MADStore storeWithURL:storeURL];
	XCTAssertTrue([store openWithError:&error], @"opening the converted store failed: %@", error);
	MADStoreGraph *reread = [store allObjectsWithError:&error];
	XCTAssertNotNil(reread, @"reading the converted store failed: %@", error);
	[store close];

	if (written) *written = graph;
	if (read) *read = reread;
}

/// -isEqualToGraph: says only that two graphs differ, and a document has hundreds
/// of rows, so find the first row that does and say what about it.
- (void)assertGraph:(MADStoreGraph *)actual equalsGraph:(MADStoreGraph *)expected {
	NSMutableSet<NSString *> *names = [NSMutableSet setWithArray:actual.entityNames];
	[names addObjectsFromArray:expected.entityNames];

	for (NSString *name in [[names allObjects] sortedArrayUsingSelector:@selector(compare:)]) {
		NSArray<MADStoreObject *> *mine = [actual objectsForEntity:name];
		NSArray<MADStoreObject *> *theirs = [expected objectsForEntity:name];
		if (mine.count != theirs.count) {
			XCTFail(@"%@ has %lu rows, expected %lu",
					name, (unsigned long)mine.count, (unsigned long)theirs.count);
			return;
		}
		for (NSUInteger index = 0; index < theirs.count; index++) {
			MADStoreObject *a = mine[index];
			MADStoreObject *b = theirs[index];
			if (a.identifier != b.identifier) {
				XCTFail(@"%@ row %lu is %lld, expected %lld", name, (unsigned long)index,
						(long long)a.identifier, (long long)b.identifier);
				return;
			}
			if (![a isEqualToObject:b]) {
				XCTFail(@"%@ %lld differs\n\tread: %@ %@ %@\n\twrote: %@ %@ %@",
						name, (long long)a.identifier, a.values, a.references, a.collections,
						b.values, b.references, b.collections);
				return;
			}
		}
	}
}

- (NSArray<NSManagedObject *> *)objectsForEntityNamed:(NSString *)name
											  context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:name];
	// The converter writes each row under its concrete kind, so a table-owning
	// entity's rows live under its subentity names (RptqDocumentElementLabel, not
	// RptqDocumentElement).  The reference must ask the question the plural store
	// lookup answers -- the base entity and its subclasses -- or both sides agree
	// at zero and a lookup regression passes unnoticed.
	NSEntityDescription *description = self.model.entitiesByName[name];
	request.includesSubentities = description.subentities.count > 0;
	NSError *error = nil;
	NSArray<NSManagedObject *> *objects = [context executeFetchRequest:request error:&error];
	XCTAssertNotNil(objects, @"fetching %@ failed: %@", name, error);
	return objects ?: @[];
}

// The exact count -- subentities NOT included -- so the total over all entities
// counts each row once, under its own kind.
- (NSUInteger)exactCountForEntityNamed:(NSString *)name
							   context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:name];
	request.includesSubentities = NO;
	NSError *error = nil;
	NSUInteger count = [context countForFetchRequest:request error:&error];
	XCTAssertNil(error, @"counting %@ failed: %@", name, error);
	return count;
}

#pragma mark - The acceptance test

- (void)testLondonConvertsAndReadsBackEqual {
	MADStoreGraph *written = nil;
	MADStoreGraph *read = nil;
	[self convertSample:@"London" written:&written read:&read];
	if (!written) return;

	// The reader hands back its canonical form, and the converter's graph has to be
	// put through the same pass before the two are comparable.
	[self assertGraph:[read graphByCompletingInverses]
		  equalsGraph:[written graphByCompletingInverses]];
	XCTAssertTrue([[read graphByCompletingInverses] isEqualToGraph:[written graphByCompletingInverses]]);
}

- (void)testMusicConvertsAndReadsBackEqual {
	MADStoreGraph *written = nil;
	MADStoreGraph *read = nil;
	[self convertSample:@"Music" written:&written read:&read];
	if (!written) return;

	[self assertGraph:[read graphByCompletingInverses]
		  equalsGraph:[written graphByCompletingInverses]];
	XCTAssertTrue([[read graphByCompletingInverses] isEqualToGraph:[written graphByCompletingInverses]]);
}

/// user_version, read straight from SQLite so nothing under test answers the
/// question.
static NSInteger SQLiteUserVersion(NSURL *url) {
	sqlite3 *database = NULL;
	if (sqlite3_open(url.path.fileSystemRepresentation, &database) != SQLITE_OK) return -1;
	sqlite3_stmt *statement = NULL;
	NSInteger version = 0;
	if (sqlite3_prepare_v2(database, "PRAGMA user_version;", -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) version = (NSInteger)sqlite3_column_int64(statement, 0);
	}
	sqlite3_finalize(statement);
	sqlite3_close(database);
	return version;
}

/// A converted document is born at the current store version: the converter's
/// creation path is -[MADStore openWithError:], the same fresh-store
/// initialization the migration tests pin.  (The literal is
/// MADStoreCurrentVersion once the constant exists.)
- (void)testConvertedStoreIsBornAtTheCurrentVersion {
	NSURL *storeURL = [self.directory URLByAppendingPathComponent:@"London.sqlite"];
	NSError *error = nil;
	MADStoreGraph *graph = [MADStoreConverter convertDocumentAtURL:[self sampleURLNamed:@"London"]
													  toStoreAtURL:storeURL
															 model:self.model
															 error:&error];
	XCTAssertNotNil(graph, @"converting London failed: %@", error);
	if (!graph) return;
	XCTAssertEqual(SQLiteUserVersion(storeURL), (NSInteger)2, @"the converted store is born at the current version");
}

#pragma mark - What the samples pin

/// Every row of the legacy document reaches the store, and no row arrives twice.
/// The counts come from Core Data itself, so a walk that quietly skips a
/// relationship -- or a row nothing points at -- shows up here rather than passing
/// because both sides of the comparison made the same omission.
- (void)testEveryLegacyRowIsWritten {
	for (NSString *sample in @[ @"London", @"Music" ]) {
		MADStoreGraph *written = nil;
		MADStoreGraph *read = nil;
		[self convertSample:sample written:&written read:&read];
		if (!written) continue;

		NSManagedObjectContext *context = [self legacyContextForSample:sample];
		MADStoreSchema *schema = [MADStoreSchema sharedSchema];
		NSUInteger total = 0;
		for (MADStoreEntity *entity in schema.entities) {
			NSUInteger expected = [self objectsForEntityNamed:entity.name context:context].count;
			NSUInteger actual = [read objectsForEntity:entity.name].count;
			XCTAssertEqual(actual, expected, @"%@ row count in %@", entity.name, sample);
			// The total must count each row once, under its own kind; the inclusive
			// fetch above already counts subclass rows under their table owner.
			total += [self exactCountForEntityNamed:entity.name context:context];
		}
		XCTAssertEqual(read.count, total, @"%@ has rows outside the entity list", sample);
		XCTAssertGreaterThan(total, (NSUInteger)400, @"%@ looks empty", sample);
	}
}

/// The order of an ordered to-many lives on the parent's edge list and in the
/// child's `position` column, so it is the thing most easily lost in a conversion.
/// Sections are the case that matters: their rows are ordered, and each row's
/// elements are ordered again inside it.
- (void)testSectionRowAndElementOrderSurviveTheConversion {
	MADStoreGraph *written = nil;
	MADStoreGraph *read = nil;
	[self convertSample:@"London" written:&written read:&read];
	if (!written) return;
	NSManagedObjectContext *context = [self legacyContextForSample:@"London"];

	NSArray<NSManagedObject *> *sections = [self objectsForEntityNamed:@"RptqDocumentSection" context:context];
	XCTAssertGreaterThan(sections.count, (NSUInteger)0);

	NSUInteger checked = 0;
	for (NSManagedObject *section in sections) {
		NSNumber *identifier = [section valueForKey:@"identifier"];

		// A section row has no model identifier to compare by, so its fingerprint is
		// the ordered elements it holds.
		NSMutableArray<NSArray<NSNumber *> *> *expected = [NSMutableArray array];
		for (NSManagedObject *row in [section valueForKey:@"hasRows"]) {
			NSMutableArray<NSNumber *> *elements = [NSMutableArray array];
			for (NSManagedObject *element in [row valueForKey:@"hasObjects"]) {
				[elements addObject:[element valueForKey:@"identifier"]];
			}
			[expected addObject:elements];
		}

		MADStoreObject *stored = [read objectForEntity:@"RptqDocumentSection" identifier:identifier.longLongValue];
		XCTAssertNotNil(stored, @"section %@ did not reach the store", identifier);
		NSArray<NSNumber *> *rowIdentifiers = [stored existingCollectionForName:@"hasRows"];
		XCTAssertEqual(rowIdentifiers.count, expected.count, @"section %@ row count", identifier);

		for (NSUInteger index = 0; index < rowIdentifiers.count; index++) {
			MADStoreObject *row = [read objectForEntity:@"RptqDocumentSectionRows"
											 identifier:rowIdentifiers[index].longLongValue];
			XCTAssertNotNil(row, @"section %@ row %lu did not reach the store",
							identifier, (unsigned long)index);
			// A row with nothing in it has no edge list on either side, and an empty
			// array and no array are the same thing to the model.
			NSArray<NSNumber *> *elements = [row existingCollectionForName:@"hasObjects"] ?: @[];
			XCTAssertEqualObjects(elements, expected[index],
								  @"section %@ row %lu element order", identifier, (unsigned long)index);
			checked++;
		}
	}
	XCTAssertGreaterThan(checked, (NSUInteger)0);
}

/// A schema table lists its fields in the order the user put them in, and a query
/// selects its fields in an order of its own; neither is the order Core Data
/// happens to hand them back in.
- (void)testSchemaFieldAndQueryFieldOrderSurviveTheConversion {
	MADStoreGraph *written = nil;
	MADStoreGraph *read = nil;
	[self convertSample:@"London" written:&written read:&read];
	if (!written) return;
	NSManagedObjectContext *context = [self legacyContextForSample:@"London"];

	NSUInteger checked = 0;
	for (NSManagedObject *table in [self objectsForEntityNamed:@"RptqDatabaseSchemaTable" context:context]) {
		NSNumber *identifier = [table valueForKey:@"identifier"];
		NSMutableArray<NSNumber *> *expected = [NSMutableArray array];
		for (NSManagedObject *field in [table valueForKey:@"hasFields"]) {
			[expected addObject:[field valueForKey:@"identifier"]];
		}

		MADStoreObject *stored = [read objectForEntity:@"RptqDatabaseSchemaTable" identifier:identifier.longLongValue];
		XCTAssertNotNil(stored, @"table %@ did not reach the store", identifier);
		XCTAssertEqualObjects([stored existingCollectionForName:@"hasFields"], expected,
							  @"table %@ field order", identifier);
		checked++;
	}
	XCTAssertGreaterThan(checked, (NSUInteger)0);

	// The query's selection is the one many-to-many, and it crosses the join table.
	for (NSManagedObject *query in [self objectsForEntityNamed:@"RptqQuery" context:context]) {
		NSNumber *identifier = [query valueForKey:@"identifier"];
		NSMutableArray<NSNumber *> *expected = [NSMutableArray array];
		for (NSManagedObject *field in [query valueForKey:@"hasFields"]) {
			[expected addObject:[field valueForKey:@"identifier"]];
		}
		if (expected.count == 0) continue;

		MADStoreObject *stored = [read objectForEntity:@"RptqQuery" identifier:identifier.longLongValue];
		XCTAssertNotNil(stored, @"query %@ did not reach the store", identifier);
		NSArray<NSNumber *> *selected = [stored existingCollectionForName:@"hasFields"];
		XCTAssertEqual(selected.count, expected.count, @"query %@ selection size", identifier);
		XCTAssertEqualObjects([NSSet setWithArray:selected], [NSSet setWithArray:expected],
							  @"query %@ selection", identifier);

		// And the far side of the join is filled in too.
		for (NSNumber *fieldIdentifier in expected) {
			MADStoreObject *field = [read objectForEntity:@"RptqDatabaseSchemaField"
											   identifier:fieldIdentifier.longLongValue];
			XCTAssertTrue([[field existingCollectionForName:@"inQuery"] containsObject:identifier],
						  @"field %@ does not name query %@", fieldIdentifier, identifier);
		}
	}
}

/// The nine value satellites and RptqDocumentSectionRows have no identifier in the
/// model, so each one has to be given one -- and has to stay reachable from the
/// element or section that owns it.
- (void)testSatelliteRowsGetIdentifiersAndStayReachable {
	MADStoreGraph *written = nil;
	MADStoreGraph *read = nil;
	[self convertSample:@"London" written:&written read:&read];
	if (!written) return;

	MADStoreSchema *schema = [MADStoreSchema sharedSchema];
	NSArray<NSString *> *satellites = @[ @"RptqAlignment", @"RptqBorder", @"RptqDirectionalAsymmetry",
										 @"RptqDirectionalProperty", @"RptqNumericFormat", @"RptqPoint",
										 @"RptqRect", @"RptqSize", @"RptqTextStyle", @"RptqDocumentSectionRows" ];
	for (NSString *name in satellites) {
		XCTAssertFalse([schema entityNamed:name].hasModelIdentifier, @"%@ is not a satellite", name);
		NSArray<MADStoreObject *> *rows = [read objectsForEntity:name];
		XCTAssertGreaterThan(rows.count, (NSUInteger)0, @"%@ has no rows", name);
		for (MADStoreObject *row in rows) {
			XCTAssertGreaterThan(row.identifier, (int64_t)0, @"%@ has a row with no identifier", name);
		}
	}

	// The element end of each satellite is a reference, and it has to point at a row
	// that actually arrived.  Elements are stored under their own kind, so the graph
	// is walked rather than asked for one name.
	NSUInteger referenced = 0;
	for (MADStoreObject *element in [read allObjects]) {
		MADStoreEntity *entity = [schema entityNamed:element.entity];
		if (![entity.table isEqualToString:@"RptqDocumentElement"]) continue;
		for (NSString *name in @[ @"rect", @"alignment", @"textStyle", @"numericFormat" ]) {
			NSNumber *target = [element referenceForName:name];
			if (!target) continue;
			MADStoreRelationship *relationship = [entity anyRelationshipNamed:name];
			XCTAssertNotNil([read objectForEntity:relationship.destination identifier:target.longLongValue],
							@"%@ %lld names a %@ that did not reach the store",
							element.entity, (long long)element.identifier, name);
			referenced++;
		}
	}
	XCTAssertGreaterThan(referenced, (NSUInteger)0);
}

/// The model calls the credential's key `dbkey` and the store calls it `key`.  If
/// the converter passed the model's name through, the schema would refuse the row
/// with MADStoreErrorUnknownAttribute -- so a successful conversion of a document
/// that has a credentials row is itself the assertion.
- (void)testCredentialsConvertUnderTheStoresNameForTheKey {
	MADStoreGraph *written = nil;
	MADStoreGraph *read = nil;
	[self convertSample:@"London" written:&written read:&read];
	if (!written) return;

	NSArray<MADStoreObject *> *credentials = [read objectsForEntity:@"RptqDatabaseCredentals"];
	XCTAssertEqual(credentials.count, (NSUInteger)1);
	MADStoreObject *row = credentials.firstObject;
	XCTAssertNil(row.values[@"dbkey"], @"the model's name for the key reached the store");
	MADStoreEntity *entity = [[MADStoreSchema sharedSchema] entityNamed:@"RptqDatabaseCredentals"];
	XCTAssertNotNil([entity attributeNamed:@"key"]);
	XCTAssertNil([entity attributeNamed:@"dbkey"]);

	// The values the sample does carry are the ones a reader needs to connect.
	XCTAssertEqualObjects(row.values[@"dbname"], @"chinook.sqlite3");
	XCTAssertEqualObjects(row.values[@"driverID"], @"Sqlite 3");
}

#pragma mark - Errors

- (void)testConvertingSomethingThatIsNotADocumentFails {
	NSURL *bogus = [self.directory URLByAppendingPathComponent:@"bogus.mad"];
	[[NSFileManager defaultManager] createFileAtPath:bogus.path
											contents:[@"not an archive" dataUsingEncoding:NSUTF8StringEncoding]
										attributes:nil];

	NSError *error = nil;
	MADStoreGraph *graph = [MADStoreConverter convertDocumentAtURL:bogus
													  toStoreAtURL:[self.directory URLByAppendingPathComponent:@"out.sqlite"]
															 model:self.model
															 error:&error];
	XCTAssertNil(graph);
	XCTAssertEqualObjects(error.domain, MADStoreConverterErrorDomain);
	XCTAssertEqual(error.code, MADStoreConverterErrorUnarchive);
}

#pragma mark - Transformables

/// Neither sample has a colour, an image or a locale set, so the one path the real
/// documents cannot pin is pinned here: a document built in memory, with all three
/// on it.  What lands in the store has to be four Real columns, PNG bytes and an
/// identifier string -- not an archive.
- (void)testTransformableValuesBecomePortableScalars {
	NSManagedObjectModel *model = [self.model copy];
	for (NSEntityDescription *entity in model.entities) {
		entity.managedObjectClassName = @"NSManagedObject";
	}
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	NSError *error = nil;
	XCTAssertNotNil([coordinator addPersistentStoreWithType:NSInMemoryStoreType
											  configuration:nil
														URL:nil
													options:nil
													  error:&error], @"in-memory store: %@", error);
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	context.persistentStoreCoordinator = coordinator;

	NSManagedObject *label = [NSEntityDescription insertNewObjectForEntityForName:@"RptqDocumentElementLabel"
														  inManagedObjectContext:context];
	[label setValue:@7 forKey:@"identifier"];
	[label setValue:[UIColor colorWithRed:0.25 green:0.5 blue:0.75 alpha:1.0] forKey:@"backgroundColor"];
	[label setValue:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5] forKey:@"foregroundColor"];

	// A one-pixel image, so the PNG bytes are a fixed, checkable thing.
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);
	[[UIColor redColor] setFill];
	UIRectFill(CGRectMake(0, 0, 1, 1));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	NSManagedObject *imageElement = [NSEntityDescription insertNewObjectForEntityForName:@"RptqDocumentElementImage"
																 inManagedObjectContext:context];
	[imageElement setValue:@8 forKey:@"identifier"];
	[imageElement setValue:image forKey:@"image"];

	NSManagedObject *format = [NSEntityDescription insertNewObjectForEntityForName:@"RptqNumericFormat"
														   inManagedObjectContext:context];
	[format setValue:[NSLocale localeWithLocaleIdentifier:@"en_US"] forKey:@"locale"];

	MADStoreGraph *graph = [MADStoreConverter graphForManagedObjectContext:context error:&error];
	XCTAssertNotNil(graph, @"serialising the context failed: %@", error);

	NSURL *storeURL = [self.directory URLByAppendingPathComponent:@"transformables.sqlite"];
	MADStore *store = [MADStore storeWithURL:storeURL];
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	XCTAssertTrue([store writeGraph:graph replacingAll:YES error:&error], @"write failed: %@", error);
	MADStoreGraph *read = [store allObjectsWithError:&error];
	[store close];

	MADStoreObject *storedLabel = [read objectForEntity:@"RptqDocumentElementLabel" identifier:7];
	XCTAssertEqualWithAccuracy([[storedLabel attributeValue:@"backgroundColorR"] doubleValue], 0.25, 0.001);
	XCTAssertEqualWithAccuracy([[storedLabel attributeValue:@"backgroundColorG"] doubleValue], 0.5, 0.001);
	XCTAssertEqualWithAccuracy([[storedLabel attributeValue:@"backgroundColorB"] doubleValue], 0.75, 0.001);
	XCTAssertEqualWithAccuracy([[storedLabel attributeValue:@"backgroundColorA"] doubleValue], 1.0, 0.001);
	XCTAssertEqualWithAccuracy([[storedLabel attributeValue:@"foregroundColorA"] doubleValue], 0.5, 0.001);

	MADStoreObject *storedImage = [read objectForEntity:@"RptqDocumentElementImage" identifier:8];
	NSData *png = [storedImage attributeValue:@"image"];
	XCTAssertTrue([png isKindOfClass:[NSData class]]);
	XCTAssertEqualObjects(png, UIImagePNGRepresentation(image), @"the image is not the PNG the model held");
	XCTAssertNotNil([UIImage imageWithData:png], @"the bytes are not a readable PNG");

	// RptqNumericFormat has no identifier in the model; the store mints one.  The
	// elements build their own satellites on insert, so the one locale is looked for
	// rather than assumed to be the only row.
	NSArray<MADStoreObject *> *formats = [read objectsForEntity:@"RptqNumericFormat"];
	XCTAssertGreaterThan(formats.count, (NSUInteger)0);
	NSMutableArray<NSString *> *locales = [NSMutableArray array];
	for (MADStoreObject *format in formats) {
		XCTAssertGreaterThan(format.identifier, (int64_t)0);
		NSString *locale = [format attributeValue:@"locale"];
		if (locale) [locales addObject:locale];
	}
	XCTAssertEqualObjects(locales, @[ @"en_US" ]);
}

@end
