 
 
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

#import <MADFoundation/MADDataProtocol.h>
#import <MADFoundation/MTCacheProtocol.h>

#import <MAD/MADSortOrder.h>
#import <MAD/MADPrintPageRendererDataSource.h>

#import "MADReportFormatterDataSourceProtocol.h"

@protocol MADActivityProtocol;
@protocol MADocumentDelegate;

@class NSManagedObjectID;
@class RptqDocument;

@class MADActivityIndicator;

@class MADocumentState;
@class MADSectionLayoutManager;
@class MTQueryFull;
@class MTDatabase;
@class MTReportFormatter;
@class MTDataTableFast;
@class MTPaper;
@class MADDatabaseConnection;

@class MADModelDocument;
@class MADModelDatabase;
@class MADModelQuery;
@class MADModelQueryTable;
@class MADModelQueryLink;
@class MADModelQueryField;

typedef NSMutableDictionary <NSManagedObjectID *, MADSectionLayoutManager *>
                                                        MADSectionLayoutManagerMutableMap;

extern NSString * const MADMimeType;
extern NSString * const MADDocumentInfoKeyThumbnail;

@protocol MADDocumentStatusProtocol <NSObject>
    - (void)setStatusText:(NSString *)statusText;
@end

@interface MADocument : UIManagedDocument
    <UIPrintInteractionControllerDelegate,
        MADDataProtocol,
        MTCacheProtocol,
        MTReportFormatterDataSource,
        MADPrintPageRendererDataSourceProtocol>

    @property (nonatomic, readwrite, weak)      id <MADActivityProtocol> activityDelegate;

    @property (nonatomic, readonly, strong)     MADModelDocument *documentModel;

    @property (nonatomic, weak)                 id <MADocumentDelegate> documentDelegate;
    @property (readonly)                        RptqDocument    *activeDocumentModel;

    @property (nonatomic, readwrite, strong)    MTReportFormatter *printingReportFormatter;

    @property (nonatomic, weak)                 NSObject <MADDocumentStatusProtocol> *documentStatusProtocol;
    @property (nonatomic, strong, readwrite)    MADocumentState         *documentStatus;

    @property (nonatomic, readonly, strong)     MADSectionLayoutManagerMutableMap *sectionLayoutManagers;

    @property (readonly)                        NSString        *filename;
    @property (nonatomic, strong, readwrite)    MTQueryFull     *mainQuery;

    @property (nonatomic, strong)               MTPaper         *paper;
    @property (nonatomic, readonly, copy)       NSURL           *urlDataTableCache;
    @property (nonatomic, assign)               BOOL            limitResultsDesignMode;


    + (instancetype)newManagedDocumentForURL:(NSURL *)url;
    - (instancetype)initWithFileURL:(NSURL *)url;
    - (instancetype)initWithFileURL:(NSURL *)url andDatabaseConnection:(MADDatabaseConnection *)databaseConnection;

    - (void)reportFormatterDidFormatPage:(NSNotification *)sender;

    - (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID
                           andSortOrder:(MNSSortOrder)sortOrder;

    - (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID;

    - (void)removeDocumentObjectWithObjectID:(NSManagedObjectID *)objectID;

    - (void)deleteDatafieldsRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                 inContent:(NSManagedObjectContext *)context;

    - (void)deleteAggregateFieldRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                     inContent:(NSManagedObjectContext *)context;

    - (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID
          fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (NSDictionary *)copyLayoutHeightsBySectionKey;

    + (void)close:(MADocument *)document
       completion:(void (^)(BOOL success, NSURL *fileURL, NSURL *cleanupURL))completion;

    - (void)archiveAndRemoveFileWrapper; //Cleans any cache that may exist.

    - (void)regenThumbnail;

    - (void)saveContext;
    - (void)prepareForQuery;
    - (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection;
    - (void)resetCache;
    - (void)resetMainQuery;
    - (void)resetSectionLayoutManagers;

@end

#endif
