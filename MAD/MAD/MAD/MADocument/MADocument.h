 
 
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

extern NSString * const MADMimeType;
extern NSString * const MADDocumentInfoKeyThumbnail;
extern NSString * const MTDocumentExtentionPoratableNetworkGraphic;

@protocol MADActivityProtocol;

@class NSManagedObjectID;
@class UIImage;
@class UIPrintPageRenderer;
@class MADErrorContainer;
@class RptqDocument;
@class RptqQueryGroup;
@class RptqDatabaseSchemaTable;
@class RptqDocumentSection;
@class RptqDocumentObject;
@class MADCredential;
@class MADocumentState;
@class MADSectionLayoutManager;
@class MADActivityIndicator;
@class MADocument;
@class MTDatabaseConnection;
@class MTReportFormatter;
@class MTDataTableFast;
@class MTQuery;
@class MTQueryFull;
@class MTDatabase;
@class MTPaper;
@class MTReportViewerPrintPageRenderer;

typedef NSMutableDictionary <NSManagedObjectID *, MADSectionLayoutManager *>
                                                        MADSectionLayoutManagerMutableMap;

@protocol MADocumentDelegate
  @required
  @optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
@end

@interface MADocument : UIManagedDocument
    <UIPrintInteractionControllerDelegate,
        MTReportFormatterDataSource,
        MTDatabaseProtocol,
        MTCacheProtocol,
        MADDataProtocol>

    @property (nonatomic, strong)               MTReportFormatter *reportFormatter;
    @property (nonatomic, strong, readwrite)    MTDataTableFast *mainDataTable;
    @property (nonatomic, strong, readwrite)    MTDatabase *database;

    // Set and used by export operations
    @property (nonatomic, weak)                 MADActivityIndicator *statusLabel;
    @property (nonatomic, strong, readwrite)    MADocumentState *documentStatus;

    @property (nonatomic, weak)                 id <MADocumentDelegate> documentDelegate;

    @property (nonatomic, copy)                 NSManagedObjectID *documentObjectID;

    @property (nonatomic, strong)               MADSectionLayoutManagerMutableMap *sectionLayoutManagers;

    @property (readonly)                        RptqDocument *activeDocumentModel;
    @property (readonly)                        NSString *filename;
    @property (nonatomic, strong, readwrite)    MTQueryFull *mainQuery;


    @property (nonatomic, weak)                 id <MADActivityProtocol> activityDelegate;
    @property (nonatomic, strong)               MTPaper *paper;
    @property (nonatomic, copy, readonly)       NSURL *urlDataTableCache;
    @property (nonatomic, assign)               BOOL limitResultsDesignMode;

    + (instancetype)newManagedDocumentForURL:(NSURL *)url;

    - (instancetype)initWithFileURL:(NSURL *)url;

    - (MTReportViewerPrintPageRenderer *)newPrinterPrintPageRender;

    + (NSURL *)newThumbnailUrlForMadUrl:(NSURL *)madUrl;
    + (BOOL)isRetnaDisplay;

    - (NSString *)mimetype;

    - (void)saveContext;

    - (void)regenThumbnail;

    - (void)initalizeSectionLayoutManagers:(RptqDocument *)document;
    - (void)initalizeMainDataTable;
    - (void)initalizeMainQuery:(RptqDocument *)document;

    - (void)prepareForQuery;

    - (void)reportFormatterDidFormatPage:(NSNotification *)sender;

    - (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID
                           andSortOrder:(MNSSortOrder)sortOrder;

    - (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID;

    - (void)removeDocumentObjectWithObjectID:(NSManagedObjectID *)objectID
                        managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (void)deleteDatafieldsRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                 inContent:(NSManagedObjectContext *)context;

    - (void)deleteAggregateFieldRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                     inContent:(NSManagedObjectContext *)context;

    - (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID
          fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (NSDictionary *)copyLayoutHeightsBySectionKey;

    + (void)close:(MADocument *)document completion:(void (^)(BOOL success))completion;

    - (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion;
    - (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;
    - (void)removeGuts; //Cleans any cache that may exist.

@end

#endif
