 
 
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
        MTCacheProtocol, MADDataProtocol>

    @property (nonatomic, strong)               MTReportFormatter *reportFormatter;

    @property (nonatomic, strong, readwrite)    MTDataTableFast *mainDataTable;
    @property (readwrite)                       MTDatabase *database;
    @property (nonatomic, strong)               MADActivityIndicator *statusLabel;

    @property (nonatomic, strong, readwrite)    MADocumentState *documentStatus;

    @property (nonatomic, weak)                 id <MADocumentDelegate> documentDelegate;

    @property (nonatomic, copy)                 NSManagedObjectID *documentObjectID;
    @property (readonly)                        RptqDocument *activeDocumentModel;

    @property (nonatomic, strong)               NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADSectionLayoutManager *> *sectionLayoutManagers;
    @property (readonly)                        NSString *filename;
    @property (nonatomic, strong, readwrite)    MTQueryFull *mainQuery;


    @property (nonatomic, weak)                 id <MADActivityProtocol> activityDelegate;
    @property (nonatomic, strong)               MTPaper *paper;
    @property (nonatomic, copy, readonly)       NSURL *urlDataTableCache;
    @property (nonatomic, assign)               BOOL limitResultsDesignMode;

    - (MTReportViewerPrintPageRenderer *)printerPrintPageRender;

    + (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
    + (BOOL)isRetnaDisplay;

    - (instancetype)initWithFileURL:(NSURL *)url;
    - (void)saveContext;
    - (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

    - (void)regenThumbnail;

    - (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion;

    - (UIImage *)fullyRenderedThumbnail;

    - (void)initalizeMainDataTable;
    - (void)initalizeMainQuery:(RptqDocument *)document;
    - (void)prepareForQuery;

    - (void)reportFormatterDidFormatPage:(NSNotification *)sender;
    - (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID andSortOrder:(MNSSortOrder)sortOrder;
    - (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID;

    - (void)removeDocumentObjectWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (void)deleteDatafieldsRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId inContent:(NSManagedObjectContext *)context;
    - (void)deleteAggregateFieldRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId inContent:(NSManagedObjectContext *)context;

    - (void)removeGroup:(RptqQueryGroup *)group fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (void)initalizeSectionLayoutManagers:(RptqDocument *)document;

    - (NSDictionary *)layoutHeightsBySectionKey;

    - (void)removeGuts; //Cleans any cache that may exist.

    - (NSString *)mimetype;

@end

#endif
