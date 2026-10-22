//
//  MADStoreConverter.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "MADStoreConverter.h"
#import <MAD/MADStore.h>
#import <MAD/MADStoreSchema.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/MADStoreObject.h>
#import <MAD/MADLegacyStoreConversion.h>
#import <MAD/MADArchiveManager.h>

#import <MAD/MADConstants.h>

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <string.h>

NSString * const MADStoreConverterErrorDomain = @"MADStoreConverterErrorDomain";

static NSError *MADStoreConverterError(MADStoreConverterErrorCode code, NSString *message) {
	return [NSError errorWithDomain:MADStoreConverterErrorDomain
							   code:code
						   userInfo:@{ NSLocalizedDescriptionKey: message }];
}

#pragma mark - Values

/// The one attribute the store names differently.  The schema follows the Rptq
/// header, which calls it `key`; the model still calls it `dbkey`.
static NSDictionary<NSString *, NSString *> *MADStoreAttributeRenames(void) {
	return @{ @"dbkey": @"key" };
}

/// The colours are the two transformables the store spreads over four Real columns
/// each; their names are the model's, with the component letter appended.
static BOOL MADStoreIsColorAttribute(NSString *name) {
	return [name isEqualToString:@"backgroundColor"] || [name isEqualToString:@"foregroundColor"];
}

/// A transformable's value as Core Data hands it back: the object itself when the
/// value transformer is registered, and otherwise the archived bytes it would have
/// read.  The converter works either way rather than depending on which bundle
/// happened to register the transformer.
static UIColor *MADStoreColor(id value) {
	if ([value isKindOfClass:[UIColor class]]) return value;
	if ([value isKindOfClass:[NSData class]]) {
		return [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:value error:NULL];
	}
	return nil;
}

static NSData *MADStorePNGData(id value) {
	if ([value isKindOfClass:[UIImage class]]) return UIImagePNGRepresentation((UIImage *)value);
	// MADPngImageTransformer stores PNG bytes in the first place, so raw data is
	// already the portable form.
	if ([value isKindOfClass:[NSData class]]) return value;
	return nil;
}

static NSString *MADStoreLocaleIdentifier(id value) {
	if ([value isKindOfClass:[NSString class]]) return value;
	if ([value isKindOfClass:[NSLocale class]]) return ((NSLocale *)value).localeIdentifier;
	if ([value isKindOfClass:[NSData class]]) {
		NSLocale *locale = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSLocale class] fromData:value error:NULL];
		return locale.localeIdentifier;
	}
	return nil;
}

/// RGBA in sRGB.  A colour UIKit cannot describe in RGB at all -- a pattern, or an
/// extended range -- is converted into the space the report renders in.
static BOOL MADStoreColorComponents(UIColor *color, CGFloat *components) {
	if ([color getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]]) return YES;

	CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
	CGColorRef converted = CGColorCreateCopyByMatchingToColorSpace(space, kCGRenderingIntentDefault, color.CGColor, NULL);
	CGColorSpaceRelease(space);
	if (!converted) return NO;
	UIColor *srgb = [UIColor colorWithCGColor:converted];
	CGColorRelease(converted);
	return [srgb getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
}

static void MADStoreWriteColor(id value, NSString *name, MADStoreObject *row) {
	UIColor *color = MADStoreColor(value);
	if (!color) return;
	CGFloat components[4] = { 0, 0, 0, 0 };
	if (!MADStoreColorComponents(color, components)) return;
	[row setAttributeValue:@(components[0]) forName:[name stringByAppendingString:@"R"]];
	[row setAttributeValue:@(components[1]) forName:[name stringByAppendingString:@"G"]];
	[row setAttributeValue:@(components[2]) forName:[name stringByAppendingString:@"B"]];
	[row setAttributeValue:@(components[3]) forName:[name stringByAppendingString:@"A"]];
}

static void MADStoreWriteAttributes(NSManagedObject *object, MADStoreObject *row) {
	NSDictionary<NSString *, NSString *> *renames = MADStoreAttributeRenames();
	for (NSAttributeDescription *attribute in object.entity.attributesByName.allValues) {
		NSString *name = attribute.name;
		// The model's `identifier` is the row key, and the store keeps it once.
		if ([name isEqualToString:@"identifier"]) continue;
		if (MADStoreIsColorAttribute(name)) {
			MADStoreWriteColor([object valueForKey:name], name, row);
			continue;
		}
		id value = [object valueForKey:name];
		if ([name isEqualToString:@"image"]) value = MADStorePNGData(value);
		if ([name isEqualToString:@"locale"]) value = MADStoreLocaleIdentifier(value);
		if (!value) continue;
		[row setAttributeValue:value forName:renames[name] ?: name];
	}
}

#pragma mark - Edges

static NSArray<NSManagedObject *> *MADStoreMembers(id value) {
	if ([value isKindOfClass:[NSOrderedSet class]]) return ((NSOrderedSet *)value).array;
	if ([value isKindOfClass:[NSSet class]]) return ((NSSet *)value).allObjects;
	if ([value isKindOfClass:[NSArray class]]) return value;
	return @[];
}

static void MADStoreWriteRelationships(NSManagedObject *object,
									   MADStoreObject *row,
									   MADStoreEntity *entity,
									   NSDictionary<NSManagedObjectID *, NSNumber *> *identifiers) {
	for (MADStoreRelationship *relationship in entity.allRelationships) {
		id value = [object valueForKey:relationship.name];

		if (!relationship.isToMany) {
			if (![value isKindOfClass:[NSManagedObject class]]) continue;
			NSNumber *identifier = identifiers[((NSManagedObject *)value).objectID];
			if (identifier) [row setReference:identifier forName:relationship.name];	// Converting a pointer value of type 'NSNumber *' to a primitive boolean value; instead, either compare the pointer to nil or call -boolValue
			continue;
		}

		NSArray<NSManagedObject *> *members = MADStoreMembers(value);
		if (!relationship.isOrdered) {
			// The reader rebuilds an unordered to-many by walking rows in
			// (entity, identifier) order.  Writing it in that order too means the
			// round trip lands back on the same array.
			members = [members sortedArrayUsingComparator:^NSComparisonResult(NSManagedObject *a, NSManagedObject *b) {
				NSComparisonResult byEntity = [(a.entity.name ?: @"") compare:(b.entity.name ?: @"")];
				if (byEntity != NSOrderedSame) return byEntity;
				return [(identifiers[a.objectID] ?: @0) compare:(identifiers[b.objectID] ?: @0)];
			}];
		}
		// An edge with no members is no edge: the reader leaves the collection out
		// rather than carrying an empty array, and the two graphs have to agree.
		NSMutableArray<NSNumber *> *collection = nil;
		for (NSManagedObject *member in members) {
			NSNumber *identifier = identifiers[member.objectID];
			if (!identifier) continue;	// Converting a pointer value of type 'NSNumber *' to a primitive boolean value; instead, either compare the pointer to nil or call -boolValue
			if (!collection) collection = [row collectionForName:relationship.name];
			[collection addObject:identifier];
		}
	}
}

#pragma mark - Identifiers

/// Every row's identifier, minting one for the entities the model does not give one
/// to.  Minting starts past the highest identifier the entity already uses, so a
/// minted value can never collide with a real one.
static NSDictionary<NSManagedObjectID *, NSNumber *> *
MADStoreIdentifiersForRows(NSArray<NSManagedObject *> *rows, MADStoreSchema *schema) {
	NSMutableDictionary<NSString *, NSNumber *> *highest = [NSMutableDictionary dictionary];
	for (NSManagedObject *object in rows) {
		MADStoreEntity *entity = [schema entityNamed:object.entity.name];
		if (!entity.hasModelIdentifier) continue;
		NSNumber *identifier = [object valueForKey:@"identifier"];
		NSNumber *known = highest[entity.name];
		if (!known || identifier.longLongValue > known.longLongValue) highest[entity.name] = identifier;	// Converting a pointer value of type 'NSNumber *' to a primitive boolean value; instead, either compare the pointer to nil or call -boolValue
	}

	NSMutableDictionary<NSManagedObjectID *, NSNumber *> *identifiers =
		[NSMutableDictionary dictionaryWithCapacity:rows.count];
	for (NSManagedObject *object in rows) {
		MADStoreEntity *entity = [schema entityNamed:object.entity.name];
		NSNumber *identifier = entity.hasModelIdentifier ? [object valueForKey:@"identifier"] : nil;
		if (!identifier || identifier.longLongValue == 0) {	// Converting a pointer value of type 'NSNumber *' to a primitive boolean value; instead, either compare the pointer to nil or call -boolValue
			identifier = @((highest[entity.name] ?: @0).longLongValue + 1);
			highest[entity.name] = identifier;
		}
		identifiers[object.objectID] = identifier;
	}
	return identifiers;
}

#pragma mark -

@implementation MADStoreConverter

+ (MADStoreGraph *)graphForManagedObjectContext:(NSManagedObjectContext *)context error:(NSError * __autoreleasing *)error {
	MADStoreSchema *schema = [MADStoreSchema sharedSchema];

	// One fetch per table.  Fetching a table owner returns its subentities' rows as
	// well, so every row of the document is seen exactly once -- including a row no
	// relationship reaches, which a walk from the document would leave behind and
	// the store would then hand back on the way in.
	NSMutableArray<NSManagedObject *> *rows = [NSMutableArray array];
	for (MADStoreEntity *table in schema.tables) {
		NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:table.name];
		request.includesSubentities = YES;
		NSError *fetchError = nil;
		NSArray<NSManagedObject *> *objects = [context executeFetchRequest:request error:&fetchError];
		if (!objects) {
			if (error) *error = fetchError;
			return nil;
		}
		[rows addObjectsFromArray:objects];
	}

	NSDictionary<NSManagedObjectID *, NSNumber *> *identifiers = MADStoreIdentifiersForRows(rows, schema);

	MADStoreGraph *graph = [MADStoreGraph new];
	for (NSManagedObject *object in rows) {
		MADStoreEntity *entity = [schema entityNamed:object.entity.name];
		if (!entity) {
			if (error) {
				*error = MADStoreConverterError(MADStoreConverterErrorUnknownEntity,
												[[NSString alloc] initWithFormat:@"the store has no entity %@", object.entity.name]);
			}
			return nil;
		}
		MADStoreObject *row = [MADStoreObject objectWithEntity:entity.name
													identifier:identifiers[object.objectID].longLongValue];
		MADStoreWriteAttributes(object, row);
		MADStoreWriteRelationships(object, row, entity, identifiers);
		[graph addObject:row];
	}
	return graph;
}

/// Whether the file opens the way a document does: either the v1 header, or -- for
/// everything written before it -- the bzip2 stream underneath.  The extractor
/// asserts rather than returning on anything else, and a file that is not a document
/// is an error the caller should get back, not a crash.
static BOOL MADStoreLooksLikeADocument(NSURL *url) {
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:(NSString *)url.path];
	NSData *head = [handle readDataOfLength:MADFileFormatHeaderLength];
	[handle closeFile];
	if (head.length >= 8 && memcmp(head.bytes, MADFileFormatMagic, 8) == 0) return YES;
	const uint8_t *bytes = head.bytes;
	return head.length >= 3 && bytes[0] == 'B' && bytes[1] == 'Z' && bytes[2] == 'h';
}

+ (NSURL *)legacyStoreURLForDocumentAtURL:(NSURL *)documentURL
							  extractedTo:(NSURL *)directory
									error:(NSError * __autoreleasing *)error {
	if (!MADStoreLooksLikeADocument(documentURL)) {
		if (error) {
			*error = MADStoreConverterError(MADStoreConverterErrorUnarchive,
											[[NSString alloc] initWithFormat:@"%@ is not a document",
											 documentURL.lastPathComponent]);
		}
		return nil;
	}

	// The extractor chdirs into its destination and does not come back, so put the
	// working directory back before anything else can notice.
	NSString *workingDirectory = [NSFileManager defaultManager].currentDirectoryPath;
	MADArchiveManager *archive = [[MADArchiveManager alloc] initWithFileWrapperURL:directory archiveURL:documentURL];
	BOOL unarchived = [archive unarchive];
	if (workingDirectory) [[NSFileManager defaultManager] changeCurrentDirectoryPath:workingDirectory];

	if (!unarchived) {
		if (error) {
			*error = MADStoreConverterError(MADStoreConverterErrorUnarchive,
											[[NSString alloc] initWithFormat:@"could not unarchive %@", documentURL.lastPathComponent]);
		}
		return nil;
	}

	NSURL *storeFile = [[directory URLByAppendingPathComponent:MADLegacyStoreDirectory isDirectory:YES]
						URLByAppendingPathComponent:MADLegacyStoreName isDirectory:NO];
	if (![[NSFileManager defaultManager] fileExistsAtPath:(NSString *)storeFile.path]) {
		if (error) {
			*error = MADStoreConverterError(MADStoreConverterErrorStoreFileMissing,
											[[NSString alloc] initWithFormat:@"%@ has no %@/%@",
											 documentURL.lastPathComponent, MADLegacyStoreDirectory, MADLegacyStoreName]);
		}
		return nil;
	}
	return storeFile;
}

/// The momd version whose hashes match the store's metadata.  A legacy store is
/// opened with the model it was written against, never migrated: Core Data cannot
/// infer a mapping for this model family (the barcode element's `barcodeBorderType`
/// carries `elementID="type"`, clashing with the inherited `type` on every entity
/// mapping -- BUGS.md), and every version a document in the wild can carry is in
/// the momd.
+ (NSManagedObjectModel *)modelInMomdMatchingStoreAtURL:(NSURL *)storeURL
												  error:(NSError * __autoreleasing *)error {
	NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
																						URL:storeURL
																					options:@{}
																					  error:error];
	if (!metadata) return nil;

	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD" withExtension:@"momd"];
	if (!momdURL) {
		if (error) {
			*error = [NSError errorWithDomain:MADStoreConverterErrorDomain
										 code:MADStoreConverterErrorModelMissing
									 userInfo:@{ NSLocalizedDescriptionKey: @"MAD.momd was not found in the bundle." }];
		}
		return nil;
	}
	NSArray<NSURL *> *momURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:momdURL
										includingPropertiesForKeys:nil
														   options:NSDirectoryEnumerationSkipsHiddenFiles
															 error:NULL];
	for (NSURL *momURL in momURLs) {
		if (![momURL.pathExtension isEqualToString:@"mom"]) continue;
		NSManagedObjectModel *candidate = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
		if (!candidate) continue;
		if ([candidate isConfiguration:nil compatibleWithStoreMetadata:metadata]) return candidate;
	}
	if (error) {
		*error = [NSError errorWithDomain:MADStoreConverterErrorDomain
									 code:MADStoreConverterErrorModelMissing
								 userInfo:@{ NSLocalizedDescriptionKey: @"No model version in MAD.momd matches the legacy store." }];
	}
	return nil;
}

/// Open the legacy store at `storeURL` as a context of plain NSManagedObjects.
///
/// The converter reads rows through NSManagedObject, not the Rptq subclasses: the
/// swap off NSManagedObject has already happened, and Core Data refuses to
/// instantiate an entity whose class is no longer an NSManagedObject subclass.
/// A compiled .momd is immutable, so work on a mutable copy before pointing every
/// entity at the generic class.
+ (NSManagedObjectContext *)legacyContextForStoreAtURL:(NSURL *)storeURL
												 model:(NSManagedObjectModel *)model
												 error:(NSError * __autoreleasing *)error {
	// The caller hands over the momd's current version.  A store written against an
	// older version is opened with that version instead, so the two never have to
	// migrate; a store the given model cannot be checked against (no metadata) is
	// opened with the given model, exactly as before.
	NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
																						URL:storeURL
																					options:@{}
																					  error:NULL];
	if (metadata != nil && ![model isConfiguration:nil compatibleWithStoreMetadata:metadata]) {
		model = [self modelInMomdMatchingStoreAtURL:storeURL error:error];
		if (model == nil) return nil;
	}

	NSManagedObjectModel *mutableModel = [model copy];
	for (NSEntityDescription *entity in mutableModel.entities) {
		entity.managedObjectClassName = @"NSManagedObject";
	}

	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mutableModel];
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType
								   configuration:nil
											 URL:storeURL
										 options:@{ NSMigratePersistentStoresAutomaticallyOption: @YES,
													NSInferMappingModelAutomaticallyOption: @YES }
										   error:error]) {
		return nil;
	}

	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	context.persistentStoreCoordinator = coordinator;
	return context;
}

+ (NSManagedObjectContext *)legacyContextForDocumentAtURL:(NSURL *)documentURL
											 extractedTo:(NSURL *)directory
												   model:(NSManagedObjectModel *)model
												   error:(NSError * __autoreleasing *)error {
	NSURL *storeFile = [self legacyStoreURLForDocumentAtURL:documentURL
												extractedTo:directory
													  error:error];
	if (!storeFile) return nil;
	return [self legacyContextForStoreAtURL:storeFile model:model error:error];
}

+ (MADStoreGraph *)convertLegacyStoreAtURL:(NSURL *)legacyStoreURL
							  toStoreAtURL:(NSURL *)storeURL
									 model:(NSManagedObjectModel *)model
									 error:(NSError * __autoreleasing *)error {
	NSManagedObjectContext *context = [self legacyContextForStoreAtURL:legacyStoreURL model:model error:error];
	if (!context) return nil;

	MADStoreGraph *graph = [self graphForManagedObjectContext:context error:error];

	// Let go of the legacy store before writing the portable one: the two never need
	// to be open at the same time, and closing releases the journal files.
	NSPersistentStore *legacyStore = context.persistentStoreCoordinator.persistentStores.firstObject;
	if (legacyStore != nil) {
		[context.persistentStoreCoordinator removePersistentStore:legacyStore error:NULL];
	}
	context.persistentStoreCoordinator = nil;
	if (!graph) return nil;

	MADStore *store = [MADStore storeWithURL:storeURL];
	if (![store openWithError:error]) return nil;
	if (![store writeGraph:graph replacingAll:YES error:error]) return nil;
	[store close];
	return graph;
}

+ (MADStoreGraph *)convertDocumentAtURL:(NSURL *)documentURL
						   toStoreAtURL:(NSURL *)storeURL
								  model:(NSManagedObjectModel *)model
								  error:(NSError * __autoreleasing *)error {
	NSURL *guts = [NSURL fileURLWithPath:
		[NSTemporaryDirectory() stringByAppendingPathComponent:
			[[NSString alloc] initWithFormat:@"mad-convert-%@", NSUUID.UUID.UUIDString]]
				   isDirectory:YES];

	NSURL *storeFile = [self legacyStoreURLForDocumentAtURL:documentURL
												extractedTo:guts
													  error:error];
	MADStoreGraph *graph = storeFile ? [self convertLegacyStoreAtURL:storeFile
														 toStoreAtURL:storeURL
																model:model
																error:error] : nil;
	[[NSFileManager defaultManager] removeItemAtURL:guts error:NULL];
	return graph;
}

@end
