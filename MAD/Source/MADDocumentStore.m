//
//  MADDocumentStore.m
//  MAD
//
//  See MADDocumentStore.h.  The code here is MADocument's, moved: the document's
//  init built these URLs, -openPortableStoreWithError: opened the store and
//  -cachedFilesDirectory named the cache, and the headless document needs all three
//  to be the same three.
//

#import "MADDocumentStore.h"

#import "MADStore.h"
#import "RptqStoreContext.h"
#import "MADLegacyStoreConversion.h"
#import "MADConstants.h"

#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/madlog.h>

#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>

static NSString * const MADDocumentStoreContentDirectory	= @"StoreContent";
static NSString * const MADDocumentStoreFileName			= @"store.sqlite";

@interface MADDocumentStore ()
@property (nonatomic, copy, readwrite) NSURL *documentURL;
@property (nonatomic, copy, readwrite) NSURL *gutsURL;
@property (nonatomic, copy, readwrite) NSURL *metadataURL;
@property (nonatomic, strong, readwrite) RptqStoreContext *context;
@end

@implementation MADDocumentStore

+ (instancetype)storeForDocumentURL:(NSURL *)documentURL {
	MADDocumentStore *store = [[self alloc] init];
	store.documentURL = documentURL;
	store.gutsURL = [MADURLFactory newURLDocumentArchiveForFileURL: documentURL
														 extension: MADFileExtentionMobleApplicationDocumentArchive];
	store.metadataURL = [store.gutsURL URLByAppendingPathComponent: @"meta.plist"];
	return store;
}

- (NSURL *)portableStoreURL {
	return [[self.gutsURL URLByAppendingPathComponent: MADDocumentStoreContentDirectory isDirectory: YES]
			URLByAppendingPathComponent: MADDocumentStoreFileName];
}

- (NSURL *)cacheDirectory {
	NSString *filename = self.documentURL.lastPathComponent.stringByDeletingPathExtension;
	return [MADURLFactory newURLCacheFilesDirectoryForFilename: filename];
}

#pragma mark - Opening

- (BOOL)openWithError:(NSError * __autoreleasing *)error {

	// UIDocument's save machinery and the create chain both reach a document as it
	// opens, and so do the CLI's verbs; one open per document.
	@synchronized (self) {

		if (self.context != nil) {
			return YES;
		}

		NSURL *storeURL = [self portableStoreURL];
		NSFileManager *fileManager = [NSFileManager defaultManager];

		// A new document has no guts directory yet; UIManagedDocument used to create
		// its StoreContent directory when the persistent store came up, so the
		// portable store creates its own before opening.
		NSError *directoryError = nil;
		if (![fileManager createDirectoryAtURL: [storeURL URLByDeletingLastPathComponent]
				   withIntermediateDirectories: YES
									attributes: nil
										 error: &directoryError]) {
			os_log_error(GetMadLog(), "Error creating the portable store directory: %s",
						 directoryError.localizedDescription.UTF8String);
			if (error != NULL) *error = directoryError;
			return NO;
		}

		// A document written before the portable store still holds a Core Data store,
		// which is converted on first open.  Conversion needs Core Data, which this
		// framework does not link -- the converter is supplied from outside and
		// reached through the registry (MAD_LegacyStoreConversion.h), so a build with
		// no converter reports that plainly.
		NSURL *legacyStoreURL = [[self.gutsURL URLByAppendingPathComponent: MADLegacyStoreDirectory isDirectory: YES]
								 URLByAppendingPathComponent: MADLegacyStoreName];
		if (![fileManager fileExistsAtPath: storeURL.path] &&
			[fileManager fileExistsAtPath: legacyStoreURL.path]) {
			if (![self convertLegacyStoreAtURL: legacyStoreURL toStoreAtURL: storeURL error: error]) {
				return NO;
			}
		}

		MADStore *store = [MADStore storeWithURL: storeURL];
		if (![store openWithError: error]) return NO;

		RptqStoreContext *context = [RptqStoreContext contextWithStore: store];
		if (![context loadAllWithError: error]) return NO;

		self.context = context;
		return YES;
	}
}

- (BOOL)convertLegacyStoreAtURL:(NSURL *)legacyStoreURL
				   toStoreAtURL:(NSURL *)storeURL
						  error:(NSError * __autoreleasing *)error {

	id<MADDocumentLegacyStoreConverting> converter = [MADLegacyStoreConversion converter];
	if (converter == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: MADLegacyStoreConversionErrorDomain
										 code: MADLegacyStoreConversionErrorConverterUnavailable
									 userInfo: @{ NSLocalizedDescriptionKey:
						 @"This document was written before the portable store and no legacy converter is available in this build." }];
		}
		return NO;
	}
	if (![converter convertLegacyStoreAtURL: legacyStoreURL toStoreAtURL: storeURL error: error]) {
		return NO;
	}
	[self removeLegacyStoreFilesAtURL: legacyStoreURL];
	return YES;
}

/// The legacy store's SQLite file and its journal siblings.  The directory itself is
/// left in place; it is the same StoreContent directory the portable store lives in.
- (void)removeLegacyStoreFilesAtURL:(NSURL *)legacyStoreURL {
	NSString *storePath = legacyStoreURL.path;
	if (storePath == nil) return;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray <NSString *> *paths = @[ storePath,
									 [storePath stringByAppendingString: @"-wal"],
									 [storePath stringByAppendingString: @"-shm"] ];
	for (NSString *path in paths) {
		if ([fileManager fileExistsAtPath: path]) {
			[fileManager removeItemAtPath: path error: NULL];
		}
	}
}

@end
