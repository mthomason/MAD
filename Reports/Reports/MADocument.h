 
 
//
//  MNSDocument.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADocument_h
#define Reports_MADocument_h

#import <Foundation/Foundation.h>
#import "MTCacheProtocol.h"
#import "Constants.h"
#import "MADocument.h"
#import "MTDatabase.h"
#import "MTDatabaseConnection.h"
#import "MTReportFormatter.h"
#import "MADDataProtocol.h"
#import "MADActivityProtocol.h"

extern NSString * const MADUtiType;
extern NSString * const MADMimeType;
extern NSString * const MTReportSectionType;
extern NSString * const MTReportDetailRowId;
extern NSString * const MTReportGroupLevel;
extern NSString * const MTDocumentInfoKeyThumbnail;

@class MADocumentState, MTErrorContainer;

@interface MADocument : UIManagedDocument
<MTReportFormatterDataSource,
    MTCacheProtocol,
    MADDataProtocol,
    UIPrintInteractionControllerDelegate>

@property (nonatomic, strong) MTReportFormatter *reportFormatter;
@property (nonatomic, strong, readonly) MTDataTable *mainDataTable;
@property (nonatomic, strong, readonly) MTDatabase *mainDatabase;
@property (nonatomic, weak) id <MADActivityProtocol> activityDelegate;
@property (nonatomic, strong, readwrite) MADocumentState *documentStatus;
@property (nonatomic, strong, readonly) NSURL *urlGuts;

- (instancetype)initWithFileURL:(NSURL *)url;
- (void)quickSave;
- (void)saveContext;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

- (void)refresh:(void (^)(BOOL success, NSError *error))completion;
- (void)addConnection:(MTDatabaseConnection *)connection
               status:(void (^)(NSString *status, CGFloat progress))status
           completion:(void(^)(BOOL success, MTErrorContainer *error))completion;
- (void)regenThumbnail;
- (void)writeToPdf:(NSURL *)filepath withViewController:(UIViewController *)window;

- (void)close:(void(^)(BOOL success, NSError *error))completion;
- (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion;

- (UIPrintPageRenderer *)printerPrintPageRender;

- (RptqDocument *)activeDocumentModel;
+ (NSString *)fileType;

- (NSString *)name;
- (NSString *)fileName;
+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl;
+ (NSString *)thumbnailSaveName;

- (NSURL *)urlThumbnail;

+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename;
- (void)wrapFileOverwrite:(BOOL)overwrite;

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl;

- (NSURL *)cachedDataUrl;
- (void)initalizeMainQuery;
- (void)prepareForQuery;
- (MTQuery *)defaultQuery;

@end

#endif
