//
//  MADMacDocument.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacDocument_h
#define MADMacDocument_h

#import <Cocoa/Cocoa.h>
#import <MAD/MAD.h>
#import "MADocumentDesignerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const MADMacDocumentDidMutateNotification;
extern NSNotificationName const MADMacDocumentDidRefreshNotification;

@class MADCredential, MADDatabaseConnection;

@interface MADMacDocument : NSDocument <MADocumentDesignerProtocol>

@property (nonatomic, strong, readonly, nullable) MADHeadlessDocument *headlessDocument;
@property (nonatomic, strong, readonly) MADDesignerLayout *designerLayout;
@property (nonatomic, strong, readonly, nullable) MADSectionsLayout *sectionsLayout;

@property (nonatomic, strong, readonly, nullable) RptqDocument *rptqDocument;
@property (nonatomic, strong, readonly, nullable) RptqDatabase *rptqDatabase;
@property (nonatomic, strong, readonly, nullable) RptqQuery *rptqQuery;

/// YES when the document carries a composition graph (an explicit root query).
@property (nonatomic, assign, readonly) BOOL isComposed;

/// The explicit composed root, or nil for an ordinary single-query document.
@property (nonatomic, strong, readonly, nullable) RptqQuery *rootQuery;

/// Every query in the document.  A composed document lists its root first, then its
/// source queries; an ordinary document lists its single query.
- (NSArray<RptqQuery *> *)allQueries;

/// The query the report layout and data resolve against: the root for a composed
/// document, otherwise the single query.
@property (nonatomic, strong, readonly, nullable) RptqQuery *reportQuery;

/// The query the query workspace edits.  Defaults to reportQuery.
@property (nonatomic, strong, nullable) RptqQuery *selectedQuery;

/// The database a query's own connection references (nil for the composed root's
/// placeholder database, which the refresh coordinator never reads).
- (nullable RptqDatabase *)databaseForQuery:(nullable RptqQuery *)query;

/// YES when the document should persist at store revision 3 (a root, more than one
/// query, or any named query).
- (BOOL)requiresComposedStore;

/// Adds a new source query: connects to `connection`, imports its schema as a new
/// database plus a named query, and returns the new query.
- (nullable RptqQuery *)addSourceQueryNamed:(NSString *)name
							 withConnection:(MADDatabaseConnection *)connection
								credentials:(nullable MADCredential *)credentials
									  error:(NSError * _Nullable __autoreleasing *)error;

/// Adds the explicit composed root query (empty; the author then adds upstream source
/// tables, joins, and outputs).
- (nullable RptqQuery *)addRootQueryNamed:(NSString *)name
									error:(NSError * _Nullable __autoreleasing *)error;

/// Renames a query.
- (void)renameQuery:(RptqQuery *)query to:(NSString *)name;

/// Imports the query graph of the `.mad` at `sourceURL` into this document as a new
/// child, remapping identifiers, and returns the imported root query (named `name`).
/// The source file is untouched.
- (nullable RptqQuery *)importChildFromURL:(NSURL *)sourceURL
									  name:(nullable NSString *)name
									  error:(NSError * _Nullable __autoreleasing *)error;

/// Converts this standard report into a one-child composition (engine
/// `convertToCompositionWithChildName:error:`), and marks the document mutated.
- (nullable RptqQuery *)convertToCompositionWithChildName:(nullable NSString *)childName
													 error:(NSError * _Nullable __autoreleasing *)error;

/// Adds `child` as a new input of this document's composed root (engine
/// `addChildQuery:error:`), and marks the document mutated.
- (nullable RptqQueryTable *)addChildQuery:(RptqQuery *)child
									  error:(NSError * _Nullable __autoreleasing *)error;

/// In-memory session credentials for the active document (used before or in addition to Keychain lookup).
@property (nonatomic, strong, nullable) MADCredential *sessionCredentials;

/// Adopts an already-created MADHeadlessDocument (e.g., from MADMacConnectionWindowController).
- (void)adoptHeadlessDocument:(MADHeadlessDocument *)headlessDocument;

/// Updates the document's database connection and credentials in both the Rptq store
/// and the active MADHeadlessDocument, optionally saving credentials to Keychain,
/// and marks the document dirty.
- (void)updateDatabaseConnection:(MADDatabaseConnection *)connection
					 credentials:(nullable MADCredential *)credentials
				  saveToKeychain:(BOOL)saveToKeychain;

/// Updates one query's own database connection (the source query's `inDatabase`), used
/// when reconnecting a composed source.  The active single-source path is untouched.
- (void)updateDatabaseConnection:(MADDatabaseConnection *)connection
						forQuery:(nullable RptqQuery *)query
					  credentials:(nullable MADCredential *)credentials
					saveToKeychain:(BOOL)saveToKeychain;

/// Resolves the best available credentials for `connection` (checking sessionCredentials,
/// then MADKeyChain under connection.connectionString, credRow.key, and connection.identifier).
- (nullable MADCredential *)resolvedCredentialsForDatabaseConnection:(nullable MADDatabaseConnection *)connection;

/// Rebuilds the MADSectionsLayout snapshot after query grouping or section edits.
- (void)rebuildSectionsLayout;

/// Marks the document dirty, invalidates cached query/model state, and broadcasts MADMacDocumentDidMutateNotification.
- (void)notifyDocumentMutated;

/// Returns all RptqDocumentSection objects in canonical report order:
/// Report Header, Page Header, Group Headers, Report Detail, Group Footers, Page Footer, Report Footer.
- (NSArray<RptqDocumentSection *> *)orderedSections;

/// Human-readable title for a section (including group field name for group headers/footers).
- (NSString *)displayTitleForSection:(RptqDocumentSection *)section;

/// Runs the MADOperationRefresh pipeline on a background queue and invokes completion on the main queue.
- (void)refreshDataWithPassword:(nullable NSString *)passwordOverride
					 completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/// Exports the report using MADReportExporterRegistry.
- (BOOL)exportToURL:(NSURL *)url
			 format:(NSString *)format
			  error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacDocument_h */
