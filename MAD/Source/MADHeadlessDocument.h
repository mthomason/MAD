//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADHeadlessDocument.h
//  MAD
//
//  A document with no interface and no UIDocument: it opens a .mad, reads its
//  definition out of the portable store, compiles the query, holds the row table and
//  lays the report out.  It is the same document MADocument is, for a process that
//  has no window and no run loop to hand a UIDocument to -- the CLI's verbs on Linux,
//  and any other client that wants the document without the app (MAD_LINUX.md §9
//  Phases D and E; MAD_DATA_OBJECT.md §6's entry point).
//
//  It is not a second implementation of anything.  The refresh chain
//  (MADOperationRefresh and its initializers) runs against
//  MADDocumentDataProtocol, and the render half -- MADReportFormatter, the page
//  walk, the section reads -- against MADDocumentRenderProtocol, both of which this
//  and MADocument conform to.  What it does not have is what only a windowed document
//  has: the designer's section layout managers, the thumbnail, the printing formatter.
//  What it writes is a copy: the guts directory it read, archived again with the v1
//  header (MAD_CLI.md's `mad write`), which is what makes a document writable on a
//  platform that has no app.
//

#ifndef MAD_MADHeadlessDocument_h
#define MAD_MADHeadlessDocument_h

#import <Foundation/Foundation.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADDocumentRenderProtocol.h>
#import <MAD/MADDocumentStore.h>
#import <MAD/MADSQLQueryCompiler.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>

@class MADDataTableFast, MADDatabase, MADQueryFull, MADReportFormatter, RptqStoreContext;

NS_ASSUME_NONNULL_BEGIN

@interface MADHeadlessDocument : NSObject <MADDocumentDataProtocol, MADDocumentRenderProtocol, MADDataProtocol, MADCacheProtocol, MADDatabaseResultsProtocol, MADSQLQueryDocument>

/// Opens `url`: unarchives the container, opens the portable store inside it
/// (converting a legacy store when that is all the document has) and leaves the
/// document ready to be queried.  Answers nil, with `error`, when it cannot.
+ (instancetype)documentWithContentsOfURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)error;

/// The same, without the open: the accessors read the store lazily.
- (instancetype)initWithFileURL:(NSURL *)url;

@property (readonly, nonatomic, copy) NSURL *fileURL;
@property (readonly, nonatomic, copy) NSString *filename;

/// Unarchive and open.  YES when the document's store is readable.
- (BOOL)readFromURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)error;

@property (readonly, nonatomic, strong) MADDocumentStore *documentStore;

/// Writes the document to `url`: the store as it stands, then the guts directory
/// archived over it with the v1 header.  MADocument's own save
/// (-writeStoreAndArchiveWithError:) without the parts only a UIDocument has -- the
/// metadata plist and the thumbnail ride in the guts as they were read rather than
/// being regenerated.  Fails when the document has not been opened.
///
/// `reproducible` pins what the clock and the filesystem would otherwise stamp into
/// the archive (MADArchiveManager.reproducible); it is the mode MAD_CLI.md's
/// byte-comparison uses.  The file the source was read from is never touched.
- (BOOL)writeToURL:(NSURL *)url
	  reproducible:(BOOL)reproducible
			 error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
