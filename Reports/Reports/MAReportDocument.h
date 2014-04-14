//
//  MNSDocumentReport.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDocument_h
#define Reports_MTReportDocument_h

#import <Foundation/Foundation.h>
#import "MADocument.h"
#import "MTDatabase.h"
#import "MTDatabaseConnection.h"

extern NSString * const MTReportSectionType;
extern NSString * const MTReportSectionValues;
extern NSString * const MTReportGroupLevel;

extern NSString * const MTPageDetail;
extern NSString * const MTPageHeader;
extern NSString * const MTPageFooter;
extern NSString * const MTReportHeader;
extern NSString * const MTReportFooter;
extern NSString * const MTReportGroupHeader;
extern NSString * const MTReportGroupFooter;

@class MTQuery, MTReportFormatter, MTQueryFull;

@interface MAReportDocument : MADocument

@property (nonatomic, retain) MTReportFormatter *reportFormatter;

- (id)initWithFileURL:(NSURL *)url;

- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success, NSError *error))completion;

- (void)refresh:(void (^)(BOOL success, NSError *error))completion;
- (void)sendTo;

+ (void)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler;
+ (NSString *)fileType;
+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl;

- (void)regenThumbnail;
- (RptqDocument *)activeDocument;

+ (void)initalSaveUsingUrl:(NSURL *)applicationFileUrlWithExtention
             andConnection:(MTDatabaseConnection *)databaseConnection
                completion:(void(^)(BOOL success, NSError *error))completion;

- (NSURL *)cachedDataUrl;

- (MTQuery *)defaultQuery;

@end

#endif
