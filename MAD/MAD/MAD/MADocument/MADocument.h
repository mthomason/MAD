 
 
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

@class NSManagedObjectID, RptqDocument, MADDatabaseConnection, MADModelDocument, MADocumentState,
        MADSectionLayoutManager, MTQueryFull, MTPaper;


typedef NSMutableDictionary <NSNumber *, MADSectionLayoutManager *>
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
        MADReportFormatterDataSource,
        MADPrintPageRendererDataSourceProtocol>

    @property (readwrite, nonatomic, weak)      id <MADActivityProtocol> activityDelegate;
    @property (readwrite, nonatomic, weak)      id <MADocumentDelegate> documentDelegate;

    @property (readonly, nonatomic, strong)     MADModelDocument *documentModel;

    @property (readonly, nonatomic, strong)     RptqDocument *activeDocumentModel;

    @property (readwrite, nonatomic, strong)    MADReportFormatter *printingReportFormatter;

    @property (nonatomic, weak)                 NSObject <MADDocumentStatusProtocol> *documentStatusProtocol;
    @property (readwrite, nonatomic, strong)    MADocumentState *documentStatus;

    @property (nonatomic, readonly, strong)     MADSectionLayoutManagerMutableMap *sectionLayoutManagers;

    @property (readonly, nonatomic, copy)       NSString *filename;
    @property (readonly, nonatomic, strong)     MTQueryFull *mainQuery;

    @property (readonly, nonatomic, strong)     MTPaper *paper;
    @property (readonly, nonatomic, copy)       NSURL *urlDataTableCache;

    @property (nonatomic, assign)               BOOL limitResultsDesignMode;


    + (instancetype)newManagedDocumentForURL:(NSURL *)url;
    - (instancetype)initWithFileURL:(NSURL *)url;
    - (instancetype)initWithFileURL:(NSURL *)url andDatabaseConnection:(MADDatabaseConnection *)databaseConnection;

    - (void)reportFormatterDidFormatPage:(NSNotification *)sender;

    - (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID
                           andSortOrder:(MNSSortOrder)sortOrder;

    - (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID;

    - (void)removeDocumentObjectWithObjectID:(int64_t)objectID;

    - (void)deleteDatafieldsRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                 inContent:(NSManagedObjectContext *)context;

    - (void)deleteAggregateFieldRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                     inContent:(NSManagedObjectContext *)context;

    - (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID
          fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (NSDictionary *)layoutHeightsBySectionKey;

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
