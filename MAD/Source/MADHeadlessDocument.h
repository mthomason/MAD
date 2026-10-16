//
//  MADHeadlessDocument.h
//  MAD
//
//  A document with no interface and no UIDocument: it opens a .mad, reads its
//  definition out of the portable store, compiles the query and holds the row
//  table.  It is the same data half MADocument has, for a process that has no
//  window and no run loop to hand a UIDocument to -- the CLI's verbs on Linux, and
//  any other client that wants the document without the app (MAD_LINUX.md §9
//  Phase D; MAD_DATA_OBJECT.md §6's entry point).
//
//  It is not a second implementation of the refresh path: the chain
//  (MADOperationRefresh and its initializers) runs against
//  MADDocumentDataProtocol, which both this and MADocument conform to.  What it
//  does not have is everything render-side -- the report formatter, the section
//  layout managers, the thumbnail -- and it never saves: a .mad is the app's to
//  write.
//

#ifndef MAD_MADHeadlessDocument_h
#define MAD_MADHeadlessDocument_h

#import <Foundation/Foundation.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADDocumentStore.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>

@class MADDataTableFast, MADDatabase, MADQueryFull, RptqStoreContext;

NS_ASSUME_NONNULL_BEGIN

@interface MADHeadlessDocument : NSObject <MADDocumentDataProtocol, MADDataProtocol, MADCacheProtocol, MADDatabaseResultsProtocol>

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

@end

NS_ASSUME_NONNULL_END

#endif
