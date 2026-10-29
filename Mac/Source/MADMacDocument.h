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

@interface MADMacDocument : NSDocument <MADocumentDesignerProtocol>

@property (nonatomic, strong, readonly, nullable) MADHeadlessDocument *headlessDocument;
@property (nonatomic, strong, readonly) MADDesignerLayout *designerLayout;
@property (nonatomic, strong, readonly, nullable) MADSectionsLayout *sectionsLayout;

@property (nonatomic, strong, readonly, nullable) RptqDocument *rptqDocument;
@property (nonatomic, strong, readonly, nullable) RptqDatabase *rptqDatabase;
@property (nonatomic, strong, readonly, nullable) RptqQuery *rptqQuery;

/// Adopts an already-created MADHeadlessDocument (e.g., from MADMacConnectionWindowController).
- (void)adoptHeadlessDocument:(MADHeadlessDocument *)headlessDocument;

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
