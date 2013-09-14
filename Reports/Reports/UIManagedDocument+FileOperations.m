//
//  UIManagedDocument+FileOperations.m
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIManagedDocument+FileOperations.h"

@implementation UIManagedDocument (FileOperations)

+ (void)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id managedDocument, BOOL success))completionHandler {

    id managedDocumentAtUrl = [[UIManagedDocument alloc] initWithFileURL:url];

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                                NSInferMappingModelAutomaticallyOption : @YES};

    [managedDocumentAtUrl setPersistentStoreOptions: options];

    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
    if (fileExist) {
        [managedDocumentAtUrl openWithCompletionHandler:^(BOOL success) {
            completionHandler(managedDocumentAtUrl, success);
        }];
    } else {
        [managedDocumentAtUrl saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            completionHandler(managedDocumentAtUrl, success);
        }];
    }
    [managedDocumentAtUrl release];
}

+ (void)openManagedDocumentAtUrl:(NSURL *)url withWrapper:(Class)managedObjectType andCompletionHandler:(void (^)(id, BOOL))completionHandler {
    
    id managedDocumentAtUrl = [[managedObjectType alloc] initWithFileURL:url];
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES};
    
    [managedDocumentAtUrl setPersistentStoreOptions: options];
    
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];

    if (fileExist) {
        [managedDocumentAtUrl openWithCompletionHandler:^(BOOL success) {
            completionHandler(managedDocumentAtUrl, success);
        }];
    } else {
        [managedDocumentAtUrl saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            completionHandler(managedDocumentAtUrl, success);
        }];
    }
    [managedDocumentAtUrl release];
}

@end