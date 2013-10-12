 
 
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
#import "MTPaper.h"
#import "NSError+UserInterface.h"
//#import "MTReportViewerPrintPageRenderer.h"

extern NSString * const MTDocumentInfoKeyThumbnail;

@interface MADocument : UIManagedDocument

- (void)save:(void (^)(BOOL success))completion;
- (void)saveContext;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;
+ (void)deleteFromDisk:(NSURL *)fileUrl completion:(void (^)(BOOL success))completion;
+ (void)deleteFromDiskQuick:(MADocument *)documentReport completion:(void (^)(BOOL success))completion;
- (NSString *)name;
- (NSString *)fileName;
+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl;
+ (NSString *)thumbnailSaveName;

@property (nonatomic, retain) NSURL *thumbnailUrl;
@property (nonatomic, assign, getter = isSuspended) BOOL suspended;

@end
