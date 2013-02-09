//
//  UIManagedDocument+FileOperations.h
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MTManagedDocumentReport.h"

@interface UIManagedDocument (FileOperations)

+ (void)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id managedDocument, BOOL success))completionHandler;

+ (void)openManagedDocumentAtUrl:(NSURL *)url withWrapper:(Class)managedObjectType andCompletionHandler:(void (^)(id managedDocument, BOOL success))completionHandler;


@end