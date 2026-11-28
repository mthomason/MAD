//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDocumentDataProtocol.h
//  MAD
//
//  The data half of a document: the definition's store, the query it compiles to,
//  the database that query runs against and the table the rows land in.  It is what
//  the refresh chain works through (MADOperationRefresh and its two initializers),
//  and what the CLI's verbs read.
//
//  MADocument conforms -- every member here is one of its own accessors -- and so
//  does MADHeadlessDocument, which is the same half of a document with no
//  UIDocument underneath it and nothing to render (docs/developers/build/linux.md §9 Phase D).  The
//  point of the protocol is that the refresh chain runs against either, on one
//  implementation: docs/developers/cli.md §5.2 forbids a second refresh path.
//
//  Everything render-side -- the report formatter, the section layout managers,
//  the thumbnail -- is deliberately absent; those live on MADocument.
//

#ifndef MAD_MADDocumentDataProtocol_h
#define MAD_MADDocumentDataProtocol_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MADDataTableFast, MADDataColumn, MADDatabase, MADDatabaseConnection, MADQueryFull;
@class RptqDocument, RptqQuery, RptqStoreContext;

@protocol MADDataProtocol;

/// One complete refresh result: the generation token, the row table (its rows and
/// its column map), the row database file, and the column map file.  A consumer
/// that holds one keeps reading the same generation even after a later refresh
/// publishes another.
@interface MADDataResult : NSObject

@property (readonly, nonatomic, copy) NSString *identifier;
@property (readonly, nonatomic, strong) MADDataTableFast *dataTable;
/// The `.maddb` file: the rows and the physical columns.
@property (readonly, nonatomic, copy) NSURL *rowDatabaseURL;
/// The `.mdcache` file: the column map that points at the row database.
@property (readonly, nonatomic, copy) NSURL *columnMapURL;
/// The logical field keys, in projection order.
@property (readonly, nonatomic, copy) NSArray<NSString *> *columnKeys;
/// The columns keyed by their logical field key.
@property (readonly, nonatomic, copy) NSDictionary<NSString *, MADDataColumn *> *columns;
@property (readonly, nonatomic) NSUInteger numberOfRows;

- (instancetype)initWithIdentifier:(NSString *)identifier
                         dataTable:(MADDataTableFast *)dataTable
                    rowDatabaseURL:(NSURL *)rowDatabaseURL
                      columnMapURL:(NSURL *)columnMapURL;

/// A result for a table loaded from an existing cache.  The identifier is the row
/// file's generation token, which is the file's name.
+ (nullable instancetype)resultWithDataTable:(MADDataTableFast *)dataTable
                                columnMapURL:(NSURL *)columnMapURL;

@end

@protocol MADDocumentDataProtocol <NSObject>
@required

/// The portable store, opened: every Rptq object hangs off this.
@property (readonly, nonatomic, strong) RptqStoreContext *storeContext;

/// The document definition read out of that store.
@property (readonly, nonatomic, strong) RptqDocument *activeDocumentModel;

/// The document's main query, compiled from the definition.
@property (readonly, nonatomic, strong) MADQueryFull *mainQuery;

/// The driver-backed connection the query runs against, built from the stored
/// credentials through the driver registry (MADDatabaseDriverRegistry.h).
@property (readonly, nonatomic, strong) MADDatabase *database;

/// The rows: the .maddb table the refresh fills.
@property (readonly, nonatomic, strong) MADDataTableFast *dataTable;

/// The cache file the row table is written to; derived, and outside the document.
@property (readonly, nonatomic, copy) NSURL *urlDataTableCache;

/// The last successfully published result.  nil until a refresh, or the existing
/// cache at open, produces one.  This is the generation a consumer should read.
@property (readonly, nonatomic, strong, nullable) MADDataResult *currentResult;

/// The result a refresh is building, if one is in flight.  nil otherwise.
@property (readonly, nonatomic, strong, nullable) MADDataResult *pendingResult;

/// The per-node results of the last composed refresh, keyed by query identifier.
/// The root is not here (it is `currentResult`); these are the leaves and any
/// intermediate composers.  Empty until a composed refresh publishes them.
@property (readonly, nonatomic, copy) NSDictionary<NSNumber *, MADDataResult *> *nodeResults;

/// Replace the per-node results atomically, on the same refresh-completion path that
/// publishes `currentResult`.  Superseded results are not deleted here (they follow the
/// root's P4 discipline); their tables close once no reader still pins them.
- (void)setNodeResults:(NSDictionary<NSNumber *, MADDataResult *> *)results;

/// Stage a new generation without touching the current result.
- (nullable MADDataResult *)beginRefreshResultWithError:(NSError * _Nullable __autoreleasing *)error;

/// Publish the staged result.  The current result changes only when this succeeds.
- (BOOL)publishPendingResultWithError:(NSError * _Nullable __autoreleasing *)error;

/// Drop the staged result after a failed refresh; the current result is untouched.
- (void)discardPendingResult;

/// How many rows the table holds.
@property (readonly, nonatomic) NSUInteger numberOfResults;

/// Set by a refresh that finished, cleared by an edit that invalidates it.  The
/// getter is spelled -didRefresh because that is what the app asks.
@property (nonatomic, readwrite, getter=didRefresh) BOOL refreshed;

/// The app caps a designer's query so the editor shows a preview of the data; a
/// headless caller has no editor, but the cap is the query's LIMIT and nothing
/// else, so the flag means the same thing to either.
@property (nonatomic, readwrite) BOOL limitResultsDesignMode;

/// Connects to a different source database.
- (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection;

/// Empty the row table and load whatever cache exists for it.
- (void)resetCache;

/// Hand the row table the object the database reports rows to.
- (void)dataTableSetDataDelegate:(id <MADDataProtocol>)delegate;

/// Order the rows by the query's sort descriptors -- groupings are indexes over
/// this order, so it runs before an aggregate reads anything.
- (void)dataTableSort:(RptqQuery *)query;

/// Write the row table to urlDataTableCache.  The refresh's last step.
- (BOOL)dataTableMakeCache;

@end

NS_ASSUME_NONNULL_END

#endif
