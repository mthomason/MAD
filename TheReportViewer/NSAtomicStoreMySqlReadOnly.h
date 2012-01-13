//
//  NSAtomicStoreMySqlReadOnly.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSAtomicStoreMySqlReadOnly : NSAtomicStore

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL*)url options:(NSDictionary *)options;

// Required overrides from NSPersistentStore

+ (NSDictionary *)metadataForPersistentStoreWithURL:(NSURL*)url error:(NSError **)error;

- (NSString *)type;
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)identifier;

// Required overrides from NSAtomicStore

- (BOOL)load:(NSError **)error;	
- (BOOL)save:(NSError **)error;		

+ (BOOL)setMetadata:(NSDictionary *)metadata forPersistentStoreWithURL:(NSURL *)url error:(NSError **)error;

- (id)newReferenceObjectForManagedObject:(NSManagedObject*)managedObject;	
- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject;	
- (void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject;		

// Overrides for retain cycle breaking and cleanup
- (void)willRemoveCacheNodes:(NSSet *)cacheNodes;
- (void)willRemoveFromPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

@end