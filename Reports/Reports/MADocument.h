 
 
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
#import "MTReportFormatterDataSource.h"
#import "MTCacheProtocol.h"
#import "MADDataProtocol.h"
#import "MADActivityProtocol.h"
#import "MADSortOrder.h"

typedef NS_ENUM(NSUInteger, MTQuerySections) {
    MTQuerySectionsDocumentGroups = 0,
    MTQuerySectionsDatasource = 1,
    MTQuerySectionsTables = 2,
    MTQuerySectionsLinks = 3,
    MTQuerySectionsGroups = 4,
    MTQuerySectionsPredicate = 5,
    MTQuerySectionsSql = 6
};

extern NSString * const MADMimeType;
extern NSString * const MTReportSectionType;
extern NSString * const MTReportDetailRowId;
extern NSString * const MTReportGroupLevel;
extern NSString * const MTDocumentInfoKeyThumbnail;
extern NSString * const MADTrademark;
extern NSString * const MTDocumentExtentionPoratableNetworkGraphic;

@class MADocumentState, MTErrorContainer, MTDatabaseConnection, RptqDocument, MTReportFormatter,
        MTDataTable, MTQuery, MTActivityIndicator, RptqQueryGroup, RptqDatabaseSchemaTable,
        NSManagedObjectID;

@interface MADocument : UIManagedDocument
<MTReportFormatterDataSource,
    MTCacheProtocol,
    MADDataProtocol,
    UIPrintInteractionControllerDelegate>

@property (nonatomic, strong) MTReportFormatter *reportFormatter;
@property (nonatomic, strong, readonly) RptqDocument *document;

@property (nonatomic, strong, readonly) MTDataTable *mainDataTable;
@property (nonatomic, strong, readonly) MTQuery *mainQuery;
@property (nonatomic, strong, readonly) MTDatabase *mainDatabase;
@property (nonatomic, strong, readwrite) MADocumentState *documentStatus;

@property (nonatomic, strong, readonly) NSURL *urlGuts;
@property (nonatomic, strong, readonly) NSString *fileName;

@property (nonatomic, strong) MTActivityIndicator *statusLabel;
@property (nonatomic, weak) id <MADActivityProtocol> activityDelegate;

@property (nonatomic, strong) NSMutableDictionary *sectionLayoutManagers;

- (instancetype)initWithFileURL:(NSURL *)url;
- (void)saveContext;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

- (void)refresh:(void (^)(BOOL success, NSError *error))completion;
- (void)addConnection:(MTDatabaseConnection *)connection
               status:(void (^)(NSString *status, CGFloat progress))status
           completion:(void(^)(BOOL success, MTErrorContainer *error))completion;

- (void)regenThumbnailWithTraits:(UITraitCollection *)traits;

- (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion;

- (UIPrintPageRenderer *)printerPrintPageRender;
- (RptqDocument *)activeDocumentModel;

- (NSURL *)cachedDataUrl;

- (UIImage *)fullyRenderedThumbnail;

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl;
+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl;
+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename;
+ (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl;

- (void)initalizeMainQuery;
- (void)prepareForQuery;

- (void)reportFormatterDidFormatPage:(NSNotification *)sender;

- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID
                       andSortOrder:(MNSSortOrder)sortOrder;
- (void)addQuerySelectSchemeTable:(RptqDatabaseSchemaTable *)schemaTable;
- (NSManagedObjectID *)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination
                                          toSectionWithID:(NSManagedObjectID *)objectID;
- (void)removeDocumentObject:(NSManagedObjectID *)objectID
                 fromSection:(NSManagedObjectID *)sectionID;
- (void)removeGroup:(RptqQueryGroup *)groupToRemove;

- (NSDictionary *)layoutHeightsBySectionKey;

@end

#endif
