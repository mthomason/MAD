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

- (void)dealloc {
    [_managedDocument release];
    [super dealloc];
}

/*
 Don't call this directly.
 */
- (id)init {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Don't call %@ directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

/*
 Create a new file in standard file-directory paradigm.
 */
- (id)initNewFileWithName:(NSString *)name extension:(NSString *)extension
     managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success))completion {

    self = [super init];
    if (self) {
        
        NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:name withExtension:extension];
        
        [UIManagedDocument openManagedDocumentAtUrl:applicationFileUrlWithExtention withWrapper:managedObjectType andCompletionHandler:^(id managedDocument, BOOL success) {
            if (success) {
                [self setManagedDocumentType:[managedDocument class]];
                [self setManagedDocument:managedDocument];
            }
            completion(success);
        }];
    }
    return self;
}

/*
 This is to open an existing file.
 */
- (id)initExistingFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success, id document))completion {

    self = [super init];
    if (self) {

        [UIManagedDocument openManagedDocumentAtUrl:url withCompletionHandler:^(id managedDocument, BOOL success) {

            [self setManagedDocumentType: [managedDocument class]];
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
            
            [self setManagedDocumentType: managedObjectType];
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

@end
