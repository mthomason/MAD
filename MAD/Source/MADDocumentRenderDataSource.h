//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDocumentRenderDataSource.h
//  MAD
//
//  The render half's reads, over a document.  MADPrintPageRendererDataSourceProtocol
//  and MADReportFormatterDataSource were implemented on MADocument itself, which is
//  fine while MADocument is the only document that renders -- and is not fine now
//  that a headless document renders too (docs/developers/build/linux.md §9 Phase E): two copies of
//  "the row for this group", "the rows for this page", "the last row of the report"
//  would drift apart, and the data half's history says they would.
//
//  So the reads live here once.  MADocument and MADHeadlessDocument both conform to
//  MADDocumentRenderProtocol and both answer its page-data-source members by asking
//  one of these, which in turn asks the document for its rows, its formatter and its
//  database.  It holds the document weakly: it is a view of the document, not an
//  owner of it.
//

#ifndef MAD_MADDocumentRenderDataSource_h
#define MAD_MADDocumentRenderDataSource_h

#import <Foundation/Foundation.h>

#import <MAD/MADDocumentRenderProtocol.h>
#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/MADReportFormatterDataSourceProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADDocumentRenderDataSource : NSObject
	<MADPrintPageRendererDataSourceProtocol, MADReportFormatterDataSource>

- (instancetype)initWithDocument:(id <MADDocumentRenderProtocol>)document NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, weak, readonly, nullable) id <MADDocumentRenderProtocol> document;

/// The generation this data source reads from.  The formatter pins it to the
/// document's `currentResult` at the start of a render, so every row, column,
/// group and aggregate read in that operation sees one result even if a refresh
/// publishes another while it runs.  nil reads the document's current table, as
/// before publication existed.
@property (nonatomic, strong, nullable) MADDataResult *result;

/// YES when an export pinned `result` explicitly and a following format must keep
/// it, rather than re-pinning to the live current result.
@property (nonatomic, readonly) BOOL resultPinnedExplicitly;

/// Pin to a specific result.  `explicitly` YES marks an export's pin; NO is the
/// formatter's own pin-to-current.
- (void)pinResult:(nullable MADDataResult *)result explicitly:(BOOL)explicitly;

@end

NS_ASSUME_NONNULL_END

#endif
