//
//  MNSDocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDocument.h"

@interface MTDocument ()

@end

@implementation MTDocument

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSLog(@"Auto-Saving Document");
    id result = [super contentsForType:typeName error:outError];
    return result;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    NSLog(@"UIManagedDocument error: %@", error.localizedDescription);
    NSArray* errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(errors != nil && errors.count > 0) {
        for (NSError *error in errors) {
            NSLog(@"  Error: %@", error.userInfo);
        }
    } else {
        NSLog(@"  %@", error.userInfo);
    }
}

- (void)saveContext {
    NSError *error;
    if ([self managedObjectContext] != nil) {
        if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
            [error presentErrorToUserWithTryAgain:^(BOOL success) {
                [self saveContext];
            }];
        }
    }
}

- (void)save:(void (^)(BOOL success))completion {
    [self saveToUrl:[self fileURL] completion:^(BOOL success) {
        completion(success);
    }];
}

- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion {
    BOOL fileExistAtUrl = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
    UIDocumentSaveOperation documentSaveOperation = fileExistAtUrl ? UIDocumentSaveForOverwriting : UIDocumentSaveForCreating;
    [self saveToURL: url
   forSaveOperation: documentSaveOperation
  completionHandler:^(BOOL success) {
      completion(success);
  }];
}

- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[self fileURL] error:&error];
    BOOL success = error == nil;
    if (completion != nil) completion(success);
}

@end

/*

- (void)dealloc {
    [_managedDocument release];
    [super dealloc];
}

- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {

    }
    return self;
}

- (id)init {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Don't call %@ directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}
*/
/*
 Create a new file in standard file-directory paradigm.
- (id)initNewFileWithName:(NSString *)name extension:(NSString *)extension
     managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success))completion {

    self = [super init];
    if (self) {
        
        NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:name withExtension:extension];
        
        [UIManagedDocument openManagedDocumentAtUrl:applicationFileUrlWithExtention withWrapper:managedObjectType andCompletionHandler:^(id managedDocument, BOOL success) {
            if (success) {
                //[self setManagedDocumentType:[managedDocument class]];
                [self setManagedDocument:managedDocument];
            }
            completion(success);
        }];
    }
    return self;
}
 */

/*
 This is to open an existing file.
 */
/*
- (id)initExistingFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success, id document))completion {

    self = [super init];
    if (self) {

        [UIManagedDocument openManagedDocumentAtUrl:url withCompletionHandler:^(id managedDocument, BOOL success) {

            //[self setManagedDocumentType: [managedDocument class]];
            [self setManagedDocument: managedDocument];
            
            completion(success, self);
            
        }];
        
    }
    return self;
}

- (id)initExistingFileWithUrl:(NSURL *)url managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success, id document))completion {
    
    self = [super init];
    if (self) {
        
        [UIManagedDocument openManagedDocumentAtUrl:url withWrapper:managedObjectType andCompletionHandler:^(id managedDocument, BOOL success) {
            
            //[self setManagedDocumentType: managedObjectType];
            [self setManagedDocument: managedDocument];
            
            completion(success, self);
            
        }];
        
    }
    return self;
}


- (NSManagedObjectContext *) managedObjectContext {
    return [[self document] managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
    return [[self document] managedObjectModel];
}

- (id)document {
    return [self managedDocument];
}

- (void)saveContext {
    NSError *error;
    if ([self managedObjectContext] != nil) {
        if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
            [error presentErrorToUserWithTryAgain:^(BOOL success) {
                [self saveContext];
            }];
        }
    }
}

- (void)save:(void (^)(BOOL success))completion {
    [self saveToUrl:[[self document] fileURL] completion:^(BOOL success) {
        completion(success);
    }];
}

- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion {
    BOOL fileExistAtUrl = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
    UIDocumentSaveOperation documentSaveOperation = fileExistAtUrl ? UIDocumentSaveForOverwriting : UIDocumentSaveForCreating;
    [[self document] saveToURL: url
              forSaveOperation: documentSaveOperation
             completionHandler:^(BOOL success) {
                 completion(success);
             }];
}

- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[[self document] fileURL] error:&error];
    BOOL success = error == nil;
    if (completion != nil) completion(success);
}

@end
*/