//
//  MADAtomicStore.h
//  MAD
//
//  Created by Michael on 4/22/19.
//  Copyright © 2019 Michael Thomason. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface MADAtomicStore : NSAtomicStore {
	NSString *store_identifier;
	NSSet *temp_objects;
	BOOL removeStub;
}

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL*)url options:(NSDictionary *)options;

// Required overrides from NSPersistentStore

+ (NSDictionary *)metadataForPersistentStoreWithURL:(NSURL*)url error:(NSError * __autoreleasing *)error;

- (NSString *)type;
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)identifier;

// Required overrides from NSAtomicStore

- (BOOL)load:(NSError * __autoreleasing *)error;
- (BOOL)save:(NSError * __autoreleasing *)error;

- (id)newReferenceObjectForManagedObject:(NSManagedObject*)managedObject;
- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject;
- (void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject;

// Overrides for retain cycle breaking and cleanup
- (void)willRemoveCacheNodes:(NSSet *)cacheNodes;
- (void)willRemoveFromPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

// Utility methods factored for size

- (BOOL)createStubAndGenerateMetadata;
- (BOOL)readFile;
- (BOOL)processObjects:(NSError * __autoreleasing *)error;
- (NSSet *)getExternalRepresentations;
- (NSDictionary *)getPropertyCacheDataForKVCCompliantObject:(id)somethingRespondingToValueForKey;

@end
