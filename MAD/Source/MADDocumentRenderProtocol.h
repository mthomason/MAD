//
//  MADDocumentRenderProtocol.h
//  MAD
//
//  The render half of a document: what a format that lays pages out needs on top of
//  MADDocumentDataProtocol's data -- the formatter, and the sequence the application
//  runs before a render (sort the rows, then format).  MADocument conforms;
//  MADHeadlessDocument does not, which is exactly what makes a format like
//  json-report register everywhere and report why it cannot run where this half is
//  absent (MAD_LINUX.md §9 Phase E).
//
//  The split is the same one Phase D made for the data half: a protocol the renderers
//  take, so a document that can render is a thing rather than a class, and the render
//  half's move to Linux -- the HTML step -- is a second conformance, not a fork.
//

#ifndef MAD_MADDocumentRenderProtocol_h
#define MAD_MADDocumentRenderProtocol_h

#import <Foundation/Foundation.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADPrintPageRendererDataSource.h>

@class MADReportFormatter;

@protocol MADDocumentRenderProtocol <MADDocumentDataProtocol, MADPrintPageRendererDataSourceProtocol>
@required

/// Ready the rows for the report: what the viewer's reload runs and MADCLIDocument
/// runs before a PDF.  Idempotent.
- (void)prepareForQuery;

/// Lay the report out.  After it, -reportFormatter knows its pages.
- (void)format;

/// The formatter the page renderer draws from and the page count comes from -- the
/// renderer data source's own property, named here because a format reads it.
@property (readwrite, nonatomic, strong) MADReportFormatter *reportFormatter;

@end

#endif
