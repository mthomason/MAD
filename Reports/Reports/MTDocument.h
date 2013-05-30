 
 
//
//  MNSDocument.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSError+UserInterface.h"

@interface MTDocument : UIManagedDocument

- (void)saveContext;
- (void)save:(void (^)(BOOL success))completion;
- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

@end

/*

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
 
#ifndef Reports_MTDocument_h
#define Reports_MTDocument_h

#import <Foundation/Foundation.h>
#import "MTManagedDocumentReport.h"
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "UIManagedDocument+FileOperations.h"
#import "NSError+UserInterface.h"

@interface MTDocument : UIManagedDocument

@property (assign) Class managedDocumentType;
@property (retain, nonatomic) id managedDocument;

//Create a new file
//- (id)initNewFileWithName:(NSString *)name extension:(NSString *)extension
//     managedObjectType:(Class)managedObjectType completi;n:(void (^)(BOOL success))completion;

//Open an existing file
- (id)initExistingFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success, id document))completion;
- (id)initExistingFileWithUrl:(NSURL *)url managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success, id document))completion;

- (id)document;

- (void)saveContext;

- (void)save:(void (^)(BOOL success))completion;
- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *) managedObjectContext;

@end

#endif
*/