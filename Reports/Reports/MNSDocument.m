//
//  MNSDocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDocument.h"

@interface MNSDocument ()

@end

@implementation MNSDocument

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
- (id)initFileWithName:(NSString *)name extension:(NSString *)extension
     managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success))completion {

    self = [super init];
    if (self) {
        
        NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:name withExtension:extension];
        
        id document = [[managedObjectType alloc] initWithFileURL:applicationFileUrlWithExtention];
        [self setManagedDocument:document];
        [document release];
        if (![[NSFileManager defaultManager] fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
            [[self managedDocument] saveToURL:applicationFileUrlWithExtention forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                completion(success);
            }];
        } else if ([[self managedDocument] documentState] == UIDocumentStateClosed) {
            [[self managedDocument] openWithCompletionHandler: ^(BOOL success) {
                completion(success);
            }];
        } else if ([[self managedDocument] documentState] == UIDocumentStateNormal) {
            completion(YES);
        }
    }
    return self;
}

/*
 This is to open an existing file.
 */
- (id)initFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success))completion {

    self = [super init];
    if (self) {
        id document = [[[self managedDocumentType] alloc] initWithFileURL:url];
        [self setManagedDocument: document];
        [document release];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            [[self managedDocument] openWithCompletionHandler:^(BOOL success) {
                completion(success);
            }];
        } else {
            [self save:^(BOOL success) {
                completion(success);
            }];
        }
    }
    return self;
}

- (void)save:(void (^)(BOOL success))completion {
    [self saveToUrl:[[self managedDocument] fileURL] completion:^(BOOL success) {
        completion(success);
    }];
}

- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion {
    BOOL fileExistAtUrl = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
    UIDocumentSaveOperation documentSaveOperation = fileExistAtUrl ? UIDocumentSaveForOverwriting : UIDocumentSaveForCreating;
    [[self managedDocument] saveToURL: url
                     forSaveOperation: documentSaveOperation
                    completionHandler:^(BOOL success) {
                        completion(success);
                    }];
}

@end