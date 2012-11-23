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

#import <Foundation/Foundation.h>
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"

@interface MNSDocument : NSObject

@property (assign) Class managedDocumentType;
@property (retain, nonatomic) id managedDocument;

//Create a new file
- (id)initFileWithName:(NSString *)name extension:(NSString *)extension
     managedObjectType:(Class)managedObjectType completion:(void (^)(BOOL success))completion;

//Open an existing file
- (id)initFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success))completion;

- (void)save:(void (^)(BOOL success))completion;

- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion;

@end