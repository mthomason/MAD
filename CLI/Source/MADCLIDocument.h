//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIDocument.h
//  MAD Designer
//
//  Opens a document and refreshes it, with no interface.  The work is the
//  application's own: the same MADOperationRefresh chain.  What is left out is only
//  what needs a window -- the share sheet, the spinner, the print dialog.  The
//  rendering is the export seam's (MADReportExporting), including PDF's.
//
//  The document underneath is a MADocument on Apple, where the app's document class
//  exists, and a MADHeadlessDocument everywhere else (docs/developers/build/linux.md §9 Phase D); both
//  are read through MADDocumentDataProtocol, which is what the refresh chain takes
//  too, so the verbs above this file are the same on both.
//

#import <Foundation/Foundation.h>

#import <MAD/MADDocumentDataProtocol.h>

@class MADCredential;

NS_ASSUME_NONNULL_BEGIN

@interface MADCLIDocument : NSObject

/// Opens the document and waits for it to load.  On Apple that is a UIDocument,
/// which opens asynchronously on the main queue; headless it is a plain read.
+ (instancetype)documentWithURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)error;

/// Wraps an already-created document (e.g. `createDocumentAtURL:`'s result) so the
/// serve session can adopt it without re-reading the file it just wrote.
- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document;

@property (readonly, nonatomic, strong) id <MADDocumentDataProtocol> document;

/// The application's refresh chain, without the credentials fetch and without the
/// interface reload: initialize the data table, initialize the database and report
/// formatter, then execute the query into the row cache.
- (BOOL)refreshWithCredentials:(MADCredential *)credentials error:(NSError * _Nullable __autoreleasing *)error;

/// The same refresh, with per-source credentials for a composed document.  The map
/// is keyed by `RptqQuery.identifier`; each named source resolves its own credential
/// and `credentials` remains the fallback for a source the map does not name.  A
/// Standard Report ignores the map and uses `credentials` as before.
- (BOOL)refreshWithCredentials:(MADCredential *)credentials
			sourceCredentials:(NSDictionary<NSNumber *, MADCredential *> *)sourceCredentials
						 error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
