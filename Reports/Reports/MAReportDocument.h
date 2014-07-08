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
#import "MTReportFormatter.h"

extern NSString * const MTReportSectionType;
extern NSString * const MTReportDetailRowId;
extern NSString * const MTReportGroupLevel;
extern NSString * const MTReportGroupLevelNumber;

@class MTQuery, MTReportFormatter, MTQueryFull;

@interface MAReportDocument : MADocument
    <MTReportFormatterDataSource>

@property (nonatomic, strong) MTReportFormatter *reportFormatter;
@property (nonatomic, strong, readonly) MTDataTable *mainDataTable;

- (id)initWithFileURL:(NSURL *)url;

- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success, NSError *error))completion;

- (void)refresh:(void (^)(BOOL success, NSError *error))completion;
- (void)sendTo;

+ (MAReportDocument *)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler;
+ (NSString *)fileType;
+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
+ (void)regenThumbnailForReport:(MAReportDocument *)reportdocument;
+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl;
+ (NSArray *)cachedFilesForDocumentWithHandle:(NSString *)handle;

- (void)regenThumbnail;
- (void)writeToPdf:(NSURL *)url;

- (RptqDocument *)activeDocument;

+ (void)initalSaveUsingUrl:(NSURL *)applicationFileUrlWithExtention
             andConnection:(MTDatabaseConnection *)databaseConnection
                completion:(void(^)(BOOL success, NSError *error))completion;

- (NSURL *)cachedDataUrl;

- (void)initalizeMainQuery;
- (void)prepareForQuery;
- (MTQuery *)defaultQuery;

@end

#endif
