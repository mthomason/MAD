//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDocumentRenderProtocol.h
//  MAD
//
//  The render half of a document: what a format that lays pages out needs on top of
//  MADDocumentDataProtocol's data -- the formatter, the sequence the application runs
//  before a render (sort the rows, then format), and the page data source the walk
//  reads every element through.  MADocument conforms, and so does
//  MADHeadlessDocument, which is the same document with no UIDocument underneath:
//  the render half's move off Apple (docs/project/MAD_LINUX.md §9 Phase E) is a conformance, not
//  a fork, so `mad export --format json-report` runs where the data half does.
//
//  The split is the same one Phase D made for the data half: a protocol the renderers
//  take, so a document that can render is a thing rather than a class.  The members
//  are the ones MADReportFormatter and the page walk actually ask for -- the
//  formatter reads `filename`, `storeContext`, `database` and the row table, and
//  hands itself to the document as its data, cache and report data source.
//

#ifndef MAD_MADDocumentRenderProtocol_h
#define MAD_MADDocumentRenderProtocol_h

#import <Foundation/Foundation.h>

#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/MADReportFormatterDataSourceProtocol.h>

@class MADReportFormatter;

@protocol MADDocumentRenderProtocol <MADDocumentDataProtocol, MADDataProtocol, MADCacheProtocol,
									  MADPrintPageRendererDataSourceProtocol, MADReportFormatterDataSource>
@required

/// Ready the rows for the report: sort them the way the query's groupings expect.
/// What the viewer's reload runs and MADCLIDocument runs before a render.  Idempotent.
- (void)prepareForQuery;

/// Lay the report out.  After it, -reportFormatter knows its pages.
- (void)format;

/// The formatter the page renderer draws from and the page count comes from -- the
/// renderer data source's own property, named here because a format reads it.
@property (readwrite, nonatomic, strong) MADReportFormatter *reportFormatter;

/// The document's name, which the formatter carries into its cache identifiers.
@property (readonly, nonatomic, copy) NSString *filename;

/// Drop whatever the designer cached per section, so a re-pagination cannot be drawn
/// from a stale layout.  A document with no designer -- the headless one -- answers
/// with nothing, and the formatter calls it either way (MADReportFormatter
/// -formatDocument).
- (void)resetSectionLayoutManagers;

@end

#endif
