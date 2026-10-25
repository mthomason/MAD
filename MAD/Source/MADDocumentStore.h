//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDocumentStore.h
//  MAD
//
//  Where a .mad document's definition lives, and how it is opened: the guts
//  directory the archive unpacks into, the metadata plist beside the store, the
//  portable store itself -- converting a legacy Core Data store on first open
//  through the registry -- and the directory the row cache goes in.
//
//  MADocument and MADHeadlessDocument each hold one, so the two cannot disagree
//  about the document's own layout.  That layout is the format (docs/project/MAD_FORMAT.md §2),
//  which is why it is stated once rather than twice.
//

#ifndef MAD_MADDocumentStore_h
#define MAD_MADDocumentStore_h

#import <Foundation/Foundation.h>

@class RptqStoreContext;

NS_ASSUME_NONNULL_BEGIN

@interface MADDocumentStore : NSObject

/// The layout of `documentURL`; nothing is read or created until -openWithError:.
+ (instancetype)storeForDocumentURL:(NSURL *)documentURL;

@property (readonly, nonatomic, copy) NSURL *documentURL;

/// The directory the container unpacks into: a document's guts, on disk.
@property (readonly, nonatomic, copy) NSURL *gutsURL;

/// `guts/meta.plist` -- the generator and version the document was written with.
@property (readonly, nonatomic, copy) NSURL *metadataURL;

/// Guts/StoreContent/store.sqlite.  A document written before the portable store
/// holds a Core Data store named `analyitics` in the same directory instead; the
/// misspelling is on disk in every document ever written and is load-bearing.
@property (readonly, nonatomic, copy) NSURL *portableStoreURL;

/// Where this document's derived files go -- the row cache, the rendered-page
/// cache.  Named for the document, via MADURLFactory, as the app has always named it.
@property (readonly, nonatomic, copy) NSURL *cacheDirectory;

/// The opened store, nil until -openWithError: has answered YES.  Settable so a
/// caller that already has one -- the tests, which inject a context instead of
/// unarchiving a document -- can hand it over; the app always lets -openWithError:
/// do it.
@property (nonatomic, strong, nullable) RptqStoreContext *context;

/// Creates the store directory, converts a legacy store when the portable one is
/// absent and a legacy one is present, opens the portable store and loads its
/// object graph.  Idempotent: a second call answers the first call's result.
- (BOOL)openWithError:(NSError * _Nullable __autoreleasing *)error;

/// Closes the store and drops the context; the next -openWithError: opens it again.
- (void)close;

@end

NS_ASSUME_NONNULL_END

#endif
