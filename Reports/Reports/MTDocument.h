//
//  MNSDocument.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

/*
 This class is not intended to be used directly.  It should generally be subclassed.
 */

#ifndef Reports_MTDocument_h
#define Reports_MTDocument_h

#import <Foundation/Foundation.h>
#import "MTManagedDocumentReport.h"
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "UIManagedDocument+FileOperations.h"
#import "NSError+UserInterface.h"

@interface MTDocument : NSObject

@property (assign) Class managedDocumentType;
@property (retain, nonatomic) id managedDocument;

//Create a new file
- (id)initNewFileWithName:(NSString *)name extension:(NSString *)extension
     managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success))completion;

//Open an existing file
- (id)initExistingFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success, id document))completion;
- (id)initExistingFileWithUrl:(NSURL *)url managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success, id document))completion;

- (id)document;

- (void)saveContext;

- (void)save:(void (^)(BOOL success))completion;
- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *) managedObjectContext;

@end

#endif
