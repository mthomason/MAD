 
 
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
#import <MAD/MTReportFormatterDataSource.h>
#import <MADFoundation/MTCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MAD/MADSortOrder.h>

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

@class MADocumentState, NSManagedObjectID, UIImage, UIPrintPageRenderer, MTErrorContainer, MTDatabaseConnection, RptqDocument, MTReportFormatter,
        MTDataTableFast, MTQuery, MTActivityIndicator, RptqQueryGroup, RptqDatabaseSchemaTable,
        RptqDocumentSection, RptqDocumentObject, MTDatabase, MTPaper, MTReportViewerPrintPageRenderer;

@protocol MADActivityProtocol;

@interface MADocument : UIManagedDocument
    <UIPrintInteractionControllerDelegate, MTReportFormatterDataSource, MTCacheProtocol, MADDataProtocol>

@property (nonatomic, assign) BOOL limitResultsDesignMode;

@property (nonatomic, strong) MTReportFormatter *reportFormatter;

@property (nonatomic, strong, readonly) NSManagedObjectID *documentObjectID;

@property (nonatomic, strong, readonly) MTDataTableFast *mainDataTable;
@property (nonatomic, strong, readonly) MTQuery *mainQuery;
@property (nonatomic, strong, readonly) MTDatabase *mainDatabase;
@property (nonatomic, strong, readwrite) MADocumentState *documentStatus;

@property (nonatomic, strong) MTActivityIndicator *statusLabel;
@property (nonatomic, weak) id <MADActivityProtocol> activityDelegate;
@property (readonly) RptqDocument *activeDocumentModel;
@property (readonly) NSURL *cachedDataUrl;

@property (nonatomic, strong) NSMutableDictionary *sectionLayoutManagers;
@property (nonatomic, strong, readonly) MTPaper *paper;


- (MTReportViewerPrintPageRenderer *)printerPrintPageRender;

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
+ (BOOL)isRetnaDisplay;

- (instancetype)initWithFileURL:(NSURL *)url;
- (void)saveContext;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

- (void)refresh:(void (^)(BOOL success, NSError *error))completion;
- (void)addConnection:(MTDatabaseConnection *)connection status:(void (^)(NSString *status, float progress))status
           completion:(void(^)(BOOL success, MTErrorContainer *error))completion;

- (void)regenThumbnail;

- (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion;

- (UIImage *)fullyRenderedThumbnail;

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

@end

#endif
