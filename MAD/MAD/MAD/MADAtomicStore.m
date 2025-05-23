//
//  MADAtomicStore.m
//  MAD
//
//  Created by Michael on 4/22/19.
//  Copyright © 2019 Michael Thomason. All rights reserved.
//

#import "MADAtomicStore.h"

@implementation MADAtomicStore

NSString *MyAtomicStoreSubclassDomain = @"MADAtomicStore"; //__nameof(MADAtomic);

- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL *)url options:(NSDictionary *)options {
	if (self = [super initWithPersistentStoreCoordinator:coordinator configurationName:configurationName URL:url options:options]) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *filePath = [url path];
		BOOL isDirectory;
		if (![fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
			// no file, create one
			if (![self createStubAndGenerateMetadata]) {
				// can only get here if we can't create the stub
				return nil;
			}
		} else if (isDirectory) {
			// directories aren't my type of store
			return nil;
		} else {
			if (![self readFile]) {
				// can only get here if we can't read the file, so it isn't a store, or we can't read it, or something
				return nil;
			}
		}
	}
	return self;
}

/*
 * createStubAndGenerateMetadata
 
 Called from initWithPersistentStoreCoordinator:configurationName:URL:options:
 Creates a stub file to reserve the store's future location on disk;
 return NO (don't initialize) if we can't create the file
 */
- (BOOL)createStubAndGenerateMetadata {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *fileURL = [self URL];
	NSString *filePath = [fileURL path];
	
	BOOL success = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
	if (!success) {
		return NO;
	}
	
	[self setMetadata: [NSDictionary dictionaryWithObject: [NSNumber numberWithInteger: 0]
												   forKey: @"lastReferenceObject"]];
	removeStub = YES;
	return YES;
}

- (BOOL)readFile {
	NSData *storeContents = nil;
	
	@try {
		storeContents = [NSKeyedUnarchiver unarchiveObjectWithData: [NSData dataWithContentsOfURL:[self URL]]];
	} @catch (NSException *ex) {
		// bad archive
		return NO;
	}
	
	if (nil == storeContents) {
		return NO;
	} else {
		if (![storeContents isKindOfClass: [NSDictionary class]])  {
			// didn't get what we were expecting
			return NO;
		}
		NSDictionary *storeMetadata = [storeContents valueForKey:@"Metadata"];
		NSArray *storedObjects = [storeContents valueForKey:@ "Objects"];
		if (nil == storeMetadata || nil == storedObjects) {
			// not my store
			return NO;
		} else {
			[self setMetadata: storeMetadata];
			temp_objects = storedObjects;
		}
	}
	return YES;
}

+ (NSDictionary *)metadataForPersistentStoreWithURL:(NSURL*)url error:(NSError **)error {
	NSData *storeContents = nil;
	
	@try {
		storeContents = [NSKeyedUnarchiver unarchiveObjectWithData: [NSData dataWithContentsOfURL:url]];
	} @catch (NSException *ex) {
		*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:1 userInfo:nil];
		return NO;
	}
	
	if (nil == storeContents) {
		if (nil != error) {
			*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:2 userInfo:nil];
		}
		return nil;
	} else {
		if (! [storeContents isKindOfClass: [NSDictionary class]])  {
			if (nil != error) {
				*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:3 userInfo:nil];
			}
			return nil;
		}
		NSDictionary *storeMetadata = [storeContents valueForKey:@"Metadata"];
		NSDictionary *storedObjects = [storeContents valueForKey:@ "Objects"];
		if (nil == storeMetadata || nil == storedObjects) {
			if (nil != error) {
				*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:4 userInfo:nil];
			}
			return nil;
		} else {
			return storeMetadata;
		}
	}
}

/*
 * setMetadata:forPersistentStoreWithURL:error:
 
 Try to set metadata
 */
+ (BOOL)setMetadata:(NSDictionary *)metadata forPersistentStoreWithURL:(NSURL*)url error:(NSError **)error {
	NSData *storeContents = nil;
	
	@try {
		storeContents = [NSKeyedUnarchiver unarchiveObjectWithData: [NSData dataWithContentsOfURL:url]];
	} @catch (NSException *ex) {
		*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:11 userInfo:nil];
		return NO;
	}
	
	if (nil == storeContents) {
		if (nil != error) {
			*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:12 userInfo:nil];
		}
		return NO;
	} else {
		if (! [storeContents isKindOfClass: [NSDictionary class]])  {
			if (nil != error) {
				*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:13 userInfo:nil];
			}
			return NO;
		}
		NSDictionary *storeMetadata = [storeContents valueForKey:@"Metadata"];
		NSDictionary *storedObjects = [storeContents valueForKey:@ "Objects"];
		if (nil == storeMetadata || nil == storedObjects) {
			if (nil != error) {
				*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:14 userInfo:nil];
			}
			return NO;
		} else {
			NSString *storeIdentifier = [storeMetadata valueForKey: NSStoreUUIDKey];
			NSString *storeType = [storeMetadata valueForKey: NSStoreTypeKey];
			if (nil == storeIdentifier || nil == storeType) {
				if (nil != error) {
					*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:15 userInfo:nil];
				}
				return NO;
			}
			NSMutableDictionary *newStoreContents = [NSMutableDictionary dictionary];
			NSMutableDictionary *newMetadata = [metadata mutableCopy];
			
			
			if ([newMetadata objectForKey:@"NSStoreModelVersionHashesVersion"] == nil) {
				[newMetadata setObject:[storeMetadata objectForKey:@"NSStoreModelVersionHashesVersion"] forKey: @"NSStoreModelVersionHashesVersion"];
			}
			if ([newMetadata objectForKey:NSStoreModelVersionHashesKey] == nil) {
				[newMetadata setObject:[storeMetadata objectForKey:NSStoreModelVersionHashesKey] forKey: NSStoreModelVersionHashesKey];
			}
			if ([newMetadata objectForKey:NSStoreModelVersionIdentifiersKey] == nil) {
				[newMetadata setObject:[storeMetadata objectForKey:NSStoreModelVersionIdentifiersKey] forKey: NSStoreModelVersionIdentifiersKey];
			}
			if ([newMetadata objectForKey:NSStoreTypeKey] == nil) {
				[newMetadata setObject:[storeMetadata objectForKey:NSStoreTypeKey] forKey: NSStoreTypeKey];
			}
			if ([newMetadata objectForKey:NSStoreUUIDKey] == nil) {
				[newMetadata setObject:[storeMetadata objectForKey:NSStoreUUIDKey] forKey: NSStoreUUIDKey];
			}
			[newStoreContents setValue: newMetadata forKey: @"Metadata"];
			[newStoreContents setValue: storedObjects forKey: @"Objects"];
			NSData *newData = [NSKeyedArchiver archivedDataWithRootObject:newStoreContents];
			[newData writeToURL:url atomically:YES];
		}
	}
	return YES;
}

/*
 * type:
 
 Return a type for this store
 */
- (NSString *)type {
	return @"MyAtomicStoreSubclass";
}

/*
 * identifier:
 
 Return the identifier for this store
 */
- (NSString *)identifier {
	return store_identifier;
}

/*
 * setIdentifier:
 
 Set the identifier for this store
 */
- (void)setIdentifier:(NSString *)identifier {
	if (identifier != store_identifier) {
		//identifier;
		//store_identifier;
		store_identifier = (NSString *)identifier.copy;
	}
}

#pragma - NSAtomicStore required overrides

/*
 * load:
 
 Load the objects; the metadata was loaded earlier
 */
- (BOOL)load:(NSError **)error {
	if (nil != temp_objects) {
		NSError *localError = nil;
		BOOL success = [self processObjects:&localError];
		if (success) {
			return YES;
		}
		if (nil != error) {
			*error = localError;
		}
	} else {
		return YES;
	}
	return NO;
}


/*
 save:
 
 use standard archiving to save the metadata and the external representations
 of the objects to disk
 */
- (BOOL)save:(NSError **)error {
	if ([self isReadOnly]) {
		if (nil != error) {
			*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:31 userInfo:nil];
		}
	}
	NSMutableDictionary *dictionaryToSave = [NSMutableDictionary dictionary];
	
	[dictionaryToSave setValue: [self metadata] forKey:@"Metadata"];
	
	[dictionaryToSave setValue: [self getExternalRepresentations] forKey:@"Objects"];
	
	NSData *encodedStore = [NSKeyedArchiver archivedDataWithRootObject:dictionaryToSave];
	
	if (!encodedStore) {
		if (nil != error) {
			*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:32 userInfo:nil];
			return NO;
		}
	}
	BOOL success = [encodedStore writeToURL:[self URL] atomically:YES];
	if (!success) {
		*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:33 userInfo:nil];
	}
	removeStub = NO;
	return success;
}

/*
 * newReferenceObjectForManagedObject:
 
 Reference objectIDs are constructed using a monotonically increasing number
 across all object types; this ensures uniqueness within inheritance hierarchies
 */
- (id)newReferenceObjectForManagedObject:(NSManagedObject*)managedObject {
	NSDictionary *metadata = [self metadata];
	long nextKey = 0;
	NSNumber *lastReferenceObject = [metadata valueForKey:@"lastReferenceObject"];
	if (nil == lastReferenceObject) {
		nextKey = 1;
	} else {
		nextKey = [lastReferenceObject longValue];
		nextKey++;
	}
	NSNumber *newReferenceObject = [NSNumber numberWithLong: nextKey];
	
	NSMutableDictionary *newMetadata = [[self metadata] mutableCopy];
	[newMetadata setValue: newReferenceObject forKey: @"lastReferenceObject"];
	[self setMetadata: newMetadata];
	newMetadata;
	
	return newReferenceObject;
	
}

/*
 * newCacheNodeForManagedObject:
 
 Create and populate a new cache node by reusing the mechanism that unpacks the
 external representation of the object
 */
- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject {
	AtomicStoreCacheNodeSubclass *newNode = [[AtomicStoreCacheNodeSubclass alloc] initWithObjectID: [managedObject objectID]];
	[newNode setPropertyCacheData: [self getPropertyCacheDataForKVCCompliantObject: managedObject]];
	return newNode;
}

/*
 * updateCacheNode:
 
 Update the cache node by reusing the mechanism that unpacks the
 external representation of the object
 */
- (void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject {
	[(AtomicStoreCacheNodeSubclass *)node setPropertyCache: nil];
	[(AtomicStoreCacheNodeSubclass *)node setPropertyCacheData: [self getPropertyCacheDataForKVCCompliantObject: managedObject]];
}

#pragma - graph management overrides

/*
 * willRemoveCacheNodes:
 
 The nodes are being removed, so break any retain cycles that may have been created
 between them by removing the property cache
 */
- (void)willRemoveCacheNodes:(NSSet *)cacheNodes {
	for (NSAtomicStoreCacheNode *node in cacheNodes) {
		[node setPropertyCache: nil];
	}
}

/*
 * processObjects:
 
 Go through the external representation array and create cache nodes for the
 represented objects
 */
- (BOOL)processObjects:(NSError **)error {
	if (nil == temp_objects) {
		// This is a new store
		return YES;
	}
	
	NSMutableSet *cacheNodes = [NSMutableSet set];
	NSDictionary *entities = [[[self persistentStoreCoordinator] managedObjectModel] entitiesByName];
	
	for (NSDictionary *externalRepresentation in temp_objects) {
		NSNumber *idReferenceData = [externalRepresentation valueForKey: @"idReferenceData"];
		NSString *entityName = [externalRepresentation valueForKey:@"entityName"];
		
		if (nil == idReferenceData) {
			*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:51 userInfo:nil];
			return NO;
		}
		if (nil == entityName) {
			*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:52 userInfo:nil];
			return NO;
		}
		
		NSEntityDescription *entity = [entities valueForKey:entityName];
		if (nil == entity) {
			// should only end up here if the metadata lied about what was in the store
			*error = [NSError errorWithDomain:MyAtomicStoreSubclassDomain code:53 userInfo:nil];
			return NO;
		}
		
		NSManagedObjectID *objectID = [self objectIDForEntity: entity referenceObject:idReferenceData];
		AtomicStoreCacheNodeSubclass *newNode = [[AtomicStoreCacheNodeSubclass alloc] initWithObjectID:objectID];
		
		[newNode setPropertyCacheData: [externalRepresentation valueForKey:@"propertyData"]];
		[cacheNodes addObject: newNode];
	}
	
	[self addCacheNodes: cacheNodes];
	
	NSError *localError = nil;
	for (AtomicStoreCacheNodeSubclass *node in cacheNodes) {
		[node resolvePropertyValues: &localError];
		if (nil != localError) {
			*error = localError;
			return NO;
		}
	}
	
	[temp_objects release];
	temp_objects = nil;
	return YES;
}

/* Gather up all the external representations of the objects in the cache nodes in
 * preparation for saving
 */
- (NSSet *)getExternalRepresentations {
	NSSet *cacheNodes = [self cacheNodes];
	NSMutableSet *externalRepresentations = [NSMutableSet set];
	
	for (AtomicStoreCacheNodeSubclass *node in cacheNodes) {
		NSMutableDictionary *externalRepresentation  = [NSMutableDictionary dictionary];
		
		[externalRepresentation setValue: [[node entity] name] forKey: @"entityName"];
		[externalRepresentation setValue: [self referenceObjectForObjectID: [node objectID]] forKey:@"idReferenceData"];
		[externalRepresentation setValue: [self getPropertyCacheDataForKVCCompliantObject:node] forKey: @"propertyData"];
		
		[externalRepresentations addObject: externalRepresentation];
	}
	
	return externalRepresentations;
}

- (NSDictionary *)getPropertyCacheDataForKVCCompliantObject:(id)somethingRespondingToValueForKey {
	NSMutableDictionary *newValues = [NSMutableDictionary dictionary];
	
	NSDictionary *attributeDescriptions = [[somethingRespondingToValueForKey entity] attributesByName];
	
	for (NSString *attributeName in attributeDescriptions) {
		NSAttributeDescription *attributeDescription = [attributeDescriptions valueForKey: attributeName];
		id attributeValue = [somethingRespondingToValueForKey valueForKey: attributeName];
		if (NSTransformableAttributeType == [attributeDescription attributeType]) {
			NSString *transformerName = [attributeDescription valueTransformerName];
			attributeValue = (nil == transformerName) ? [[NSValueTransformer valueTransformerForName: NSKeyedUnarchiveFromDataTransformerName] reverseTransformedValue: attributeValue] : [[NSValueTransformer valueTransformerForName: transformerName] transformedValue: attributeValue];
		}
		[newValues setValue: attributeValue forKey: attributeName];
	}
	
	NSDictionary *relationshipDescriptions = [[somethingRespondingToValueForKey entity] relationshipsByName];
	for (NSString *relationshipName in relationshipDescriptions) {
		NSRelationshipDescription *relationshipDescription = [relationshipDescriptions valueForKey: relationshipName];
		NSMutableSet *destinationInfos = [NSMutableSet set];
		
		if (![relationshipDescription isToMany]) {
			id destinationObject = [somethingRespondingToValueForKey valueForKey: relationshipName];
			if (nil != destinationObject) {
				[destinationInfos addObject: [NSArray arrayWithObjects: [[destinationObject entity] name], [self referenceObjectForObjectID: [destinationObject objectID]], nil]];
			}
		} else {
			for (NSManagedObject *destinationObject in [somethingRespondingToValueForKey valueForKey: relationshipName]) {
				[destinationInfos addObject: [NSArray arrayWithObjects: [[destinationObject entity] name], [self referenceObjectForObjectID: [destinationObject objectID]], nil]];
			}
		}
		
		[newValues setValue: destinationInfos forKey: relationshipName];
	}
	
	return newValues;
}

// Utility method with implementation provided by NSAtomicStore
- (NSSet<__kindof NSAtomicStoreCacheNode *> *)cacheNodes {
	
}

// Utility method with implementation provided by NSAtomicStore
- (void)addCacheNodes:(NSSet<__kindof NSAtomicStoreCacheNode *> *)cacheNodes {
	
}

// Utility method with implementation provided by NSAtomicStore
- (nullable NSAtomicStoreCacheNode *)cacheNodeForObjectID:(NSManagedObjectID *)objectID {
	
}

// Utility method with implementation provided by NSAtomicStore
- (NSManagedObjectID *)objectIDForEntity:(NSEntityDescription *)entity referenceObject:(id)data {
	
}

// Utility method with implementation provided by NSAtomicStore
- (id)referenceObjectForObjectID:(NSManagedObjectID *)objectID {
	
}

@end
