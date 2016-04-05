 
 
//
//  MADocument.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADocument_h
#define Reports_MADocument_h

#import <UIKit/UIManagedDocument.h>
#import <UIKit/UIPrintInteractionController.h>
#import <MAD/MTReportFormatter.h>
#import <MAD/MTDatabase.h>
#import <MADFoundation/MTCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MTQueryFull.h>
#import <MAD/MADSectionLayoutManager.h>

typedef NS_ENUM(NSUInteger, MTQuerySections) {
    MTQuerySectionsDocumentGroups = 0,
    MTQuerySectionsDatasource = 1,
    MTQuerySectionsTables = 2,
    MTQuerySectionsLinks = 3,
    MTQuerySectionsGroups = 4,
    MTQuerySectionsPredicate = 5,
    MTQuerySectionsSql = 6,
    MTQuerySectionsNumberOfQueryResults = 7
};

extern NSString * const MADMimeType;
extern NSString * const MTDocumentInfoKeyThumbnail;
extern NSString * const MTDocumentExtentionPoratableNetworkGraphic;

@class NSManagedObjectID, UIImage, UIPrintPageRenderer, MADErrorContainer;
@class MTDatabaseConnection, RptqDocument, MTReportFormatter, MTDataTableFast, MTQuery;
@class MADActivityIndicator, RptqQueryGroup, RptqDatabaseSchemaTable, MADocument;
@class RptqDocumentSection, RptqDocumentObject, MTDatabase, MTPaper;
@class MTReportViewerPrintPageRenderer, MADCredential, MADocumentState;

@protocol MADActivityProtocol;

@protocol MADocumentDelegate
@required
@optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
@end

@interface MADocument : UIManagedDocument
    <UIPrintInteractionControllerDelegate,
        MTReportFormatterDataSource, MTDatabaseProtocol,
        MTCacheProtocol, MADDataProtocol, MADReportDesignerSectionElementLayoutManagerDelegate>

    @property (nonatomic, assign) BOOL limitResultsDesignMode;

    @property (nonatomic, weak) id <MADocumentDelegate> documentDelegate;

    @property (nonatomic, strong) MTReportFormatter *reportFormatter;

    @property (nonatomic, copy) NSManagedObjectID *documentObjectID;
    @property (readonly) RptqDocument *activeDocumentModel;

    @property (nonatomic, strong) NSMutableDictionary *sectionLayoutManagers;

    @property (nonatomic, strong, readwrite)    MTDataTableFast *mainDataTable;

    @property (nonatomic, strong, readonly)     NSString *fileName;
    @property (nonatomic, strong, readwrite)    MTQueryFull *mainQuery;
    @property (readwrite)     MTDatabase *database;

    @property (nonatomic, strong, readwrite)    MADocumentState *documentStatus;

    @property (nonatomic, strong) MADActivityIndicator *statusLabel;

    @property (nonatomic, weak) id <MADActivityProtocol> activityDelegate;

    @property (nonatomic, strong) MTPaper *paper;

    @property (nonatomic, copy, readwrite)      NSURL *urlDataTableCache;

    - (MTReportViewerPrintPageRenderer *)printerPrintPageRender;

    + (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
    + (BOOL)isRetnaDisplay;

    - (instancetype)initWithFileURL:(NSURL *)url;
    - (void)saveContext;
    - (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

    - (void)regenThumbnail;

    - (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion;

    - (UIImage *)fullyRenderedThumbnail;

    - (void)prepairForRefresh;
    - (void)finishRefresh:(bool)success;

    - (void)initalizeMainDataTable;
    - (void)initalizeMainQuery:(RptqDocument *)document;
    - (void)prepareForQuery;

    - (void)reportFormatterDidFormatPage:(NSNotification *)sender;
    - (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID andSortOrder:(MNSSortOrder)sortOrder;
    - (void)addQuerySelectSchemeTable:(RptqDatabaseSchemaTable *)schemaTable;
    - (void)removeDocumentObject:(NSManagedObjectID *)objectID fromSection:(NSManagedObjectID *)sectionID;
    - (void)removeGroup:(RptqQueryGroup *)groupToRemove;

    - (void)initalizeSectionLayoutManagers:(RptqDocument *)document;

    - (NSDictionary *)layoutHeightsBySectionKey;

    - (void)removeGuts; //Cleans any cache that may exist.

    - (NSString *)mimetype;
    - (NSURL *)cacheUrlForFilename:(NSString *)filename;

@end

#endif
