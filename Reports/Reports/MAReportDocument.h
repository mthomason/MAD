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

extern const NSString *MTReportSectionType;
extern const NSString *MTReportSectionValues;
extern const NSString *MTReportGroupLevel;

extern const NSString *MTPageDetail;
extern const NSString *MTPageHeader;
extern const NSString *MTPageFooter;
extern const NSString *MTReportHeader;
extern const NSString *MTReportFooter;
extern const NSString *MTReportGroupHeader;
extern const NSString *MTReportGroupFooter;

@class MTQuery, MTReportFormatter;

@interface MAReportDocument : MADocument
    <MTDatabaseCacheProtocol>

@property (nonatomic, assign) id <MTDatabaseCacheProtocol> delegateCacheData;

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
                completion:(void(^)(BOOL success))completion;

+ (NSURL *)cachedDataFileUrlForFileUrl:(NSURL *)fileUrl;
- (NSURL *)cachedDataUrl;

- (MTQuery *)defaultQuery;

// Page caching
//- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize;
//- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage;

//- (NSInteger)numberOfPages; // Valid after caching.

@end

#endif
