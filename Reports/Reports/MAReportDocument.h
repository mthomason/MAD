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
#import "MTCacheProtocol.h"
#import "MADDataProtocol.h"
#import "MADActivityProtocol.h"

extern NSString * const MTReportSectionType;
extern NSString * const MTReportDetailRowId;
extern NSString * const MTReportGroupLevel;

@class MTQuery, MTReportFormatter, MTQueryFull;


@interface MAReportDocument : MADocument
    <MTReportFormatterDataSource,
        MTCacheProtocol,
        MADDataProtocol,
        UIPrintInteractionControllerDelegate>

@property (nonatomic, strong) MTReportFormatter *reportFormatter;
@property (nonatomic, strong, readonly) MTDataTable *mainDataTable;
@property (nonatomic, strong, readonly) MTDatabase *mainDatabase;

@property (nonatomic, weak) id <MADActivityProtocol> activityDelegate;

- (id)initWithFileURL:(NSURL *)url;
- (void)refresh:(void (^)(BOOL success, NSError *error))completion;
- (void)regenThumbnail;
- (void)writeToPdf:(NSURL *)filepath withViewController:(UIViewController *)window;
- (void)addDatabaseConnection:(MTDatabaseConnection *)connection completion:(void(^)(BOOL success, NSError *error))completion;

- (UIPrintPageRenderer *)printerPrintPageRender;
- (RptqDocument *)activeDocument;
- (void)open:(void (^)(id, BOOL))completionHandler;

+ (NSString *)fileType;
+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl;
- (NSURL *)cachedDataUrl;

- (void)initalizeMainQuery;
- (void)prepareForQuery;
- (MTQuery *)defaultQuery;

@end

#endif
