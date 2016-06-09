 
 
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
#import <MADFoundation/MADDataProtocol.h>
#import "MADReportFormatterDataSourceProtocol.h"
#import <MADFoundation/MTCacheProtocol.h>
#import <MAD/MADSortOrder.h>

@protocol MADActivityProtocol;
@protocol MADocumentDelegate;

@class NSManagedObjectID;
@class UIImage;
@class UIPrintPageRenderer;
@class RptqDocument;
@class RptqQueryGroup;
@class RptqDatabaseSchemaTable;
@class RptqDocumentSection;
@class RptqDocumentObject;
@class MADErrorContainer;
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

extern NSString * const MADMimeType;
extern NSString * const MADDocumentInfoKeyThumbnail;

@interface MADocument : UIManagedDocument
    <MADDataProtocol,
        MTCacheProtocol,
        MTReportFormatterDataSource>
    
    @property (nonatomic, weak)                 id <MADActivityProtocol> activityDelegate;

    @property (nonatomic, strong)               MTReportFormatter *reportFormatter;
    @property (nonatomic, readwrite, strong)    MTReportFormatter *printingReportFormatter;
    @property (nonatomic, readwrite, strong)    MTDataTableFast *mainDataTable;
    @property (nonatomic, readwrite, strong)    MTDatabase *database;

    // Set and used by export operations
    @property (nonatomic, weak)                 MADActivityIndicator *statusLabel;
    @property (nonatomic, strong, readwrite)    MADocumentState *documentStatus;

    @property (nonatomic, weak)                 id <MADocumentDelegate> documentDelegate;

    @property (nonatomic, copy)                 NSManagedObjectID *documentObjectID;

    @property (nonatomic, strong)               MADSectionLayoutManagerMutableMap *sectionLayoutManagers;

    @property (readonly)                        RptqDocument *activeDocumentModel;
    @property (readonly)                        NSString *filename;
    @property (nonatomic, strong, readwrite)    MTQueryFull *mainQuery;

    @property (nonatomic, strong)               MTPaper *paper;
    @property (nonatomic, readonly, copy)       NSURL *urlDataTableCache;
    @property (nonatomic, assign)               BOOL limitResultsDesignMode;

    + (instancetype)newManagedDocumentForURL:(NSURL *)url;

    - (instancetype)initWithFileURL:(NSURL *)url;

    - (NSString *)mimetype;

    - (void)saveContext;

    - (void)initializeSectionLayoutManagers:(RptqDocument *)document;
//    - (void)initializeMainDataTable;
    - (void)initializeMainQuery:(RptqDocument *)document;

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
