//
//  NSAtomicStoreMySqlReadOnly.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSAtomicStoreMySqlReadOnly.h"
#import "Constants.h"

@implementation NSAtomicStoreMySqlReadOnly

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options {
    
    BOOL isDirectory;
	BOOL storeExists = [[NSFileManager defaultManager] fileExistsAtPath: [url path]
                                                            isDirectory: &isDirectory];
	if (![url isFileURL] || (!isDirectory && storeExists)) {
		[self release];
		self = nil;
	} else {
        self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options];
        if (self) {
            // Initialization code here.
            
            //Open MySql Database
            [options valueForKey:@"username"];
            [options valueForKey:@"password"];
            [options valueForKey:@"server"];
            [options valueForKey:@"database"];
            [options valueForKey:@"host"];
            [options valueForKey:@"port"];
            
            NSError *error;
            [NSAtomicStoreMySqlReadOnly setMetadata: options
                          forPersistentStoreWithURL: url
                                              error: &error];
            
        }
    }
    return self;
}

#pragma mark - NSAtomicStore OverRides

- (BOOL)load:(NSError **)error {
    
}

- (id)newReferenceObjectForManagedObject:(NSManagedObject *)managedObject {
    
}

- (BOOL)save:(NSError **)error {
    
}

#pragma mark - NSPersistentStore Overrides

- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject {
	
}

- (void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject {
    
}

- (NSString *)type {
    return PRESISTENT_STORE_TYPE_MYSQL;
}

- (NSString *)identifier {
    
}

- (void)setIdentifier:(NSString *)identifier {
    
}

- (NSDictionary *)metadata {
    
}

+ (NSDictionary *)metadataForPersistentStoreWithURL:(NSURL*)url error:(NSError **)error {
    
}

+ (BOOL)setMetadata:(NSDictionary *)metadata forPersistentStoreWithURL:(NSURL *)url error:(NSError **)error {
    return NO;
}

@end