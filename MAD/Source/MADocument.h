

//
//  MADocument.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADocument_h
#define Reports_MADocument_h

#import <MADFoundation/MADDataProtocol.h>
#import <MADFoundation/MADCacheProtocol.h>

#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADReportFormatterDataSourceProtocol.h>

#import <UIKit/UIDocument.h>
#import <UIKit/UIPrintInteractionController.h>

@protocol MADActivityProtocol, MADocumentDelegate;

@class MADDesignerQuery, MADDesignerLayout, MADDesignerViewer, RptqDocument, MADDatabaseConnection, MADModelDocument, MADocumentState, MADSectionLayoutManager, MADQueryFull, MTPaper, RptqQuery, RptqStoreContext;


extern NSString * const MADMimeType;
extern NSString * const MADDocumentInfoKeyThumbnail;

@protocol MADDocumentStatusProtocol <NSObject>
- (void)setStatusText:(NSString *)statusText;
@end

@interface MADocument : UIDocument <UIPrintInteractionControllerDelegate, MADDataProtocol, MADCacheProtocol, MADReportFormatterDataSource, MADPrintPageRendererDataSourceProtocol>

@property (nonatomic, readonly, strong) MADDesignerQuery *designerQuery;
@property (nonatomic, readonly, strong) MADDesignerLayout *designerLayout;
@property (nonatomic, readonly, strong) MADDesignerViewer *designerViewer;

@property (readonly, nonatomic, strong)     MADModelDocument *documentModel;
@property (readonly, nonatomic, strong)     RptqDocument *activeDocumentModel;
@property (readonly, nonatomic, strong)     RptqStoreContext *storeContext;
// The name the app and the formatter have always used for "the context that owns
// this document's objects".  Under Core Data it was inherited from UIManagedDocument;
// now it is the store context, and the same property.
@property (readonly, nonatomic, strong)     RptqStoreContext *managedObjectContext;
@property (readonly, nonatomic, strong)	 MTPaper *paper;
@property (readonly, nonatomic)             NSUInteger numberOfPages;
@property (readonly, nonatomic)             NSUInteger numberOfResults;
@property (readonly, nonatomic)             CGSize paperSize;

@property (readwrite, nonatomic, weak)      id <MADActivityProtocol> activityDelegate;
@property (readwrite, nonatomic, weak)      id <MADocumentDelegate> documentDelegate;
@property (readwrite, nonatomic, weak)      NSObject <MADDocumentStatusProtocol> *documentStatusProtocol;

@property (readwrite, nonatomic, strong)    MADocumentState *documentStatus;

@property (readonly, nonatomic, strong)     NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers;

@property (readonly, nonatomic, copy)       NSString *filename;
@property (readonly, nonatomic, strong)     MADQueryFull *mainQuery;

@property (readonly, nonatomic, copy)       NSURL *urlDataTableCache;

@property (readwrite, nonatomic, assign)    BOOL limitResultsDesignMode;
@property (readwrite, nonatomic, assign, getter=isAutosaveEnabled)    BOOL autosaveEnabled;

@property (nonatomic, readwrite, getter=didRefresh) BOOL refreshed;
@property (nonatomic, readwrite, getter=hasCachedData) BOOL cachedData;

+ (instancetype)newManagedDocumentForURL:(NSURL *)url;
- (instancetype)initWithFileURL:(NSURL *)url;
- (instancetype)initWithFileURL:(NSURL *)url
			 andDatabaseConnection:(MADDatabaseConnection *)databaseConnection;

- (void)format;
- (void)formatContentChange;

- (void)reportFormatterDidFormatPage:(NSNotification *)sender;

- (void)addQueryGroupWithQueryField:(int64_t)queryFieldObjectID
						  andSortOrder:(MADSortOrder)sortOrder;

- (void)removeDocumentObjectWithObjectID:(int64_t)objectID;

- (void)deleteDatafieldsRelatedToTable:(int64_t)deleatedTableObjectId
								inContent:(RptqStoreContext *)context;

- (void)deleteAggregateFieldRelatedToTable:(int64_t)deleatedTableObjectId
									inContent:(RptqStoreContext *)context;

- (void)removeGroupWitObjectID:(int64_t)groupID
		 fromManagedObjectContext:(RptqStoreContext *)managedObjectContext;

- (NSDictionary <NSNumber *, NSNumber *> *)layoutHeightsBySectionKey;

+ (void)close:(MADocument *)document
	  completion:(void (^)(BOOL success, NSURL *fileURL, NSURL *cleanupURL))completion;

- (void)archiveAndRemoveFileWrapper; //Cleans any cache that may exist.

- (NSURL *)thumbnailURL;

- (BOOL)dataTableMakeCache;
- (BOOL)dataTableMakeCache:(NSURL *)url;
- (void)dataTableSetDataDelegate:(id <MADDataProtocol>)delegage;
- (void)dataTableSort:(RptqQuery *)query;

- (void)saveContext;
- (void)prepareForQuery;
- (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection;
- (void)resetCache;
- (void)resetMainQuery;
- (void)resetSectionLayoutManagers;

@end

#endif
