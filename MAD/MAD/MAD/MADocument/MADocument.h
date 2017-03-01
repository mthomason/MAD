 
 
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
#import <MADFoundation/MADCacheProtocol.h>

#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/MADSortOrder.h>

#import "MADReportFormatterDataSourceProtocol.h"

@protocol MADActivityProtocol, MADocumentDelegate;

@class NSManagedObjectID, RptqDocument, MADDatabaseConnection, MADModelDocument, MADocumentState,
        MADSectionLayoutManager, MTQueryFull, MTPaper;


extern NSString * const MADMimeType;
extern NSString * const MADDocumentInfoKeyThumbnail;

@protocol MADDocumentStatusProtocol <NSObject>
    - (void)setStatusText:(NSString *)statusText;
@end

@interface MADocument : UIManagedDocument
    <UIPrintInteractionControllerDelegate,
        MADDataProtocol,
        MADCacheProtocol,
        MADReportFormatterDataSource,
        MADPrintPageRendererDataSourceProtocol>

    @property (readwrite, nonatomic, weak)      id <MADActivityProtocol> activityDelegate;
    @property (readwrite, nonatomic, weak)      id <MADocumentDelegate> documentDelegate;
    @property (readwrite, nonatomic, weak)      NSObject <MADDocumentStatusProtocol> *documentStatusProtocol;

    @property (readonly, nonatomic, strong)     MADModelDocument *documentModel;

    @property (readonly, nonatomic, strong)     RptqDocument *activeDocumentModel;

    @property (readwrite, nonatomic, strong)    MADReportFormatter *printingReportFormatter;

    @property (readwrite, nonatomic, strong)    MADocumentState *documentStatus;

    @property (readonly, nonatomic, strong)     NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers;

    @property (readonly, nonatomic, copy)       NSString *filename;
    @property (readonly, nonatomic, strong)     MTQueryFull *mainQuery;

    @property (readonly, nonatomic, strong)     MTPaper *paper;
    @property (readonly, nonatomic, copy)       NSURL *urlDataTableCache;

    @property (readwrite, nonatomic, assign)    BOOL limitResultsDesignMode;

    + (instancetype)newManagedDocumentForURL:(NSURL *)url;
    - (instancetype)initWithFileURL:(NSURL *)url;
    - (instancetype)initWithFileURL:(NSURL *)url
              andDatabaseConnection:(MADDatabaseConnection *)databaseConnection;

    - (void)reportFormatterDidFormatPage:(NSNotification *)sender;

    - (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID
                           andSortOrder:(MADSortOrder)sortOrder;

    - (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID;

    - (void)removeDocumentObjectWithObjectID:(int64_t)objectID;

    - (void)deleteDatafieldsRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                 inContent:(NSManagedObjectContext *)context;

    - (void)deleteAggregateFieldRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId
                                     inContent:(NSManagedObjectContext *)context;

    - (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID
          fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (NSDictionary <NSNumber *, NSNumber *> *)layoutHeightsBySectionKey;

    + (void)close:(MADocument *)document
       completion:(void (^)(BOOL success, NSURL *fileURL, NSURL *cleanupURL))completion;

    - (void)archiveAndRemoveFileWrapper; //Cleans any cache that may exist.

    - (NSURL *)thumbnailURL;

    - (void)saveContext;
    - (void)prepareForQuery;
    - (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection;
    - (void)resetCache;
    - (void)resetMainQuery;
    - (void)resetSectionLayoutManagers;

@end

#endif
