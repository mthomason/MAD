//
//  MADocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADocument.h"
#import <MAD/RptqStoreContext.h>
#import "MADModel.h"
#import "MADModelDocument.h"
#import "MADModelDatabase.h"
#import "MADImageThumbnail.h"
#import "MADArchiveManager.h"
#import "MADDocumentStore.h"
#import "RptqStoreContext.h"
#import "MADNotificationFileUpdate.h"
#import "RptqDataHelper.h"
#import "MADDesignerViewer.h"
#import "MADDesignerLayout.h"
#import "MADDesignerQuery.h"
#import "MADDocumentProtocol.h"
#import "MADocumentDesignerProtocol.h"
#import "MADSectionLayoutManager.h"
#import "MADQueryFull.h"
#import "MADConstants.h"
#import "MADocumentState.h"
#import "MADReportFormatter.h"
#import "MADDocumentRenderDataSource.h"
#import "MADNotificationDidFormatPage.h"
#import "RptqDocument.h"
#import "RptqBorder.h"
#import "RptqAlignment.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseCredentals.h"
#import "RptqDatabaseCredentals+Extras.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqTextStyle.h"
#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentSectionEnumerator.h"
#import "RptqDocumentSectionRows.h"
#import "MADParameters+QueryCacheAggregate.h"
#import "NSPredicate+Creators.h"
#import "MADDatabase+Constructor.h"
#import "MADQuery+Extras.h"
#import "miniz.h"
#import <MADFoundation/madlog.h>

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/MADStringUtilities.h>

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQueryType.h>
#import <MADAPI/MADAliases.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MADFileManager/MADFileUtilities.h>

#import <MADSqlite3/MADArrayCaching.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <Foundation/NSEnumerator.h>

#import <UIKit/UIPrintPaper.h>

#import <setjmp.h>

typedef void (^MTCompletionHandlerSuccess)(BOOL success);


NSString * const MADMimeType									= @"application/vnd.everydayapps.mad";
NSString * const MADDocumentInfoKeyThumbnail					= @"thumbnail";

static NSString * const MADDocumentInfoKeyVersion				= @"version";
static NSString * const MADDocumentInfoKeyGenerator				= @"generator";

static NSString * const MADDocumentTypeUtiMad					= @"com.everydayapps.productivity.mad";

void fail(char *, const char *, int);
void msg(const char *);
void madwarn(char *,  const char *);

void fail(char *__unused err, const char *__unused err2, int __unused n) { }
void msg(const char *__unused err) { }
void madwarn(char *__unused err,  const char *__unused err2) { }

@interface MADocument () <MADReportFormatterDataSource, MADCacheProtocol, MADDatabaseResultsProtocol, MADocumentDesignerProtocol>

@property (readwrite, nonatomic, strong) MADReportFormatter *printingReportFormatter;

// The render half's reads, held once and shared with MADHeadlessDocument.
@property (nonatomic, strong) MADDocumentRenderDataSource *renderDataSource;

@property (nonatomic, readwrite, strong) RptqDocument *activeDocumentModel;
@property (nonatomic, readwrite, strong) RptqStoreContext *storeContext;

@property (nonatomic, readwrite, strong) NSMutableDictionary *extraInformation;
@property (nonatomic, readwrite, strong) UIImage *thumbnail;

@property (nonatomic, readwrite, strong) MADDataTableFast *dataTable;
@property (nonatomic, readwrite, strong) MADDatabase *database;
@property (nonatomic, readwrite, strong) MADQueryFull *mainQuery;

@property (nonatomic, readwrite, strong) NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers;

@property (nonatomic, readwrite, strong) MADModelDocument *documentModel;
@property (nonatomic, readwrite, strong) MTPaper *paper;

@property (nonatomic, readwrite, copy) NSURL *urlDataTableCache;
// Where this document's files are (the guts, the store inside them, the cache): the
// same layout MADHeadlessDocument uses, stated once in MADDocumentStore.
@property (nonatomic, readwrite, strong) MADDocumentStore *documentStore;

@property (nonatomic, readwrite, strong) MADDesignerQuery *designerQuery;
@property (nonatomic, readwrite, strong) MADDesignerLayout *designerLayout;
@property (nonatomic, readwrite, strong) MADDesignerViewer *designerViewer;

@end

@implementation MADocument

@dynamic filename;
@dynamic refreshed;

@synthesize sectionLayoutManagers = _sectionLayoutManagers;
@synthesize database = _database;
@synthesize dataTable = _dataTable;
@synthesize reportFormatter = _reportFormatter;
@synthesize cachedData = _cachedData;

#pragma mark -
#pragma mark Adjust

- (NSUInteger)numberOfPages {
	return _reportFormatter != nil ? _reportFormatter.numberOfPages : 0;
}

- (NSUInteger)numberOfResults {
	return _dataTable != nil ? _dataTable.rowCounter : 0;
}

// -paper, not _paper.  The ivar stays nil until the lazy -paper accessor builds it from
// activeDocumentModel.paperType, so reading the ivar answered {0, 0} to whoever asked first.
// A zero layout size makes PrintableHeightForPage negative and the formatter starts a new
// page on every row -- 3503 rows produced 11602 pages for the CLI, which is the only caller
// that asks before something else has touched -paper.  See BUGS.md.
- (CGSize)paperSize {
	return self.paper.paperSize;
}

- (BOOL)didRefresh {
	return _reportFormatter.didRefresh;
}

- (void)setRefreshed:(BOOL)refreshed {
	os_log_debug(OS_LOG_DEFAULT, "%s: refreshed=%d formatter=%p",
				 __PRETTY_FUNCTION__, refreshed, _reportFormatter);
	_reportFormatter.didRefresh = refreshed;
}

- (void)formatContentChange {
	[self.reportFormatter format:self.paperSize contentChanged:YES];
}

- (void)format {
	[self.reportFormatter format:self.paperSize contentChanged:NO];
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	[RptqDataHelper cleanup];
	_thumbnail = nil;
}

- (void)resetCache {
	MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:self.filename.hash];
	datatable.cacheDelegate = self;
	NSError *error = nil;
	[datatable loadFromCacheWithUrl:self.urlDataTableCache error:&error];
	if (error != nil && error.code != -215) {
		os_log_error(GetMadLog(), "Error: %@", error);
	}
	self.dataTable = datatable;

}

- (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection {
	MADDatabase *database = [MADDatabase newDatabaseWithConnection:databaseConnection];
	self.database = database;
}

- (void)removeObservers {
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: RptqStoreContextObjectsDidChangeNotification
												  object: self.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: RptqStoreContextDidSaveNotification
												  object: self.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: RptqStoreContextWillSaveNotification
												  object: self];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIDocumentStateChangedNotification
												  object: self];
	
}

#pragma mark -
#pragma mark Initalization

+ (instancetype)newManagedDocumentForURL:(NSURL *)url {
	id document = [[self alloc] initWithFileURL:url];
	return document;
}

- (instancetype)initWithFileURL:(NSURL *)url {
	return [self initWithFileURL:url andDatabaseConnection:nil];
}

- (instancetype)initWithFileURL:(NSURL *)url andDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
	if (self = [super initWithFileURL:url]) {
		
		_autosaveEnabled = YES;
		_documentStore = [MADDocumentStore storeForDocumentURL: url];
		
		NSUInteger dataTableIdHash = self.fileURL.lastPathComponent.stringByDeletingPathExtension.hash;
		
		MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:dataTableIdHash];
		datatable.cacheDelegate = self;
		
		NSString *cacheName = [datatable newFilenameMDCache];
		NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
		self.urlDataTableCache = cacheUrl;
		
		NSError *error = nil;
		[datatable loadFromCacheWithUrl:cacheUrl error:&error];
		if (error != nil) {
			os_log_error(GetMadLog(), "Error: %@", error);
		}
		self.dataTable = datatable;
		
		MADocumentState *documentState = [[MADocumentState alloc] init];
		self.documentStatus = documentState;
		
		NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
		self.extraInformation = extraInfo;
		
		if (databaseConnection != nil) {
			_database = [MADDatabase newDatabaseWithConnection: databaseConnection];
		}
		_database.delegate = self;
		// These Core Data notifications are not posted by the portable store yet, and
		// `object:` used to name the managed-object context -- which opened the store
		// lazily during init, right before the create flow's cleanup deleted it out
		// from under the open handle.  Register against nil and let the handlers
		// filter on the document's own store context, so a Core Data context in
		// another part of the process (a legacy conversion, say) cannot mark this
		// document dirty.
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleManagedObjectContextDidChange:)
													 name: RptqStoreContextObjectsDidChangeNotification
												   object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleManagedObjectContextDidSave:)
													 name: RptqStoreContextDidSaveNotification
												   object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleManagedObjectContextWillSave:)
													 name: RptqStoreContextWillSaveNotification
												   object: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleDocumentStateChanged:)
													 name: UIDocumentStateChangedNotification
												   object: self];
	}
	return self;
}

- (MADDesignerQuery *)designerQuery {
	if (_designerQuery == nil) {
		MADDesignerQuery *designerQuery = [[MADDesignerQuery alloc] init];
		designerQuery.delegate = self;
		_designerQuery = designerQuery;
	}
	return _designerQuery;
}
- (MADDesignerLayout *)designerLayout {
	if (_designerLayout == nil) {
		MADDesignerLayout *designerLayout = [[MADDesignerLayout alloc] init];
		designerLayout.delegate = self;
		_designerLayout = designerLayout;
	}
	return _designerLayout;
}
- (MADDesignerViewer *)designerViewer {
	if (_designerViewer == nil) {
		MADDesignerViewer *designerViewer = [[MADDesignerViewer alloc] init];
		designerViewer.delegate = self;
		_designerViewer = designerViewer;
	}
	return _designerViewer;
}

#pragma mark -
#pragma mark Static Helpers

+ (void)close:(MADocument *)document
   completion:(void (^)(BOOL success, NSURL *fileURL, NSURL *cleanupURL))completion  {
	
	MADocument *strongDocument = document;
	
	[strongDocument removeObservers];
	
	NSURL *fileURL = strongDocument.fileURL.copy;
	NSURL *gutsUrl = strongDocument.urlGuts.copy;
	
	if (strongDocument != nil) {
		void (^finishClose)(BOOL) = ^(BOOL successClose) {
			if (completion != nil) {
				completion(successClose, fileURL, gutsUrl);
			}
		};
		if (![NSThread isMainThread]) {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[strongDocument closeWithCompletionHandler:^(BOOL successClose) {
					finishClose(successClose);
				}];
			}];
		} else {
			[strongDocument closeWithCompletionHandler:^(BOOL successClose) {
				finishClose(successClose);
			}];
		}
	} else {
		if (completion != nil) {
			completion(YES, fileURL, gutsUrl);
		}
	}
}

// Helpers

- (MADModelDocument *)documentModel {
	if (!_documentModel) {
		MADModelDocument *documentModel;
		documentModel = [[MADModelDocument alloc] initWithContext:self.storeContext];
		_documentModel = documentModel;
	}
	return _documentModel;
}

- (NSURL *)thumbnailURL {
	NSString *name = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
	return [MADURLFactory newURLThumbnailForHandle: name
								  andRetinaDisplay: YES];
}

- (NSURL *)urlDataTableCache {
	NSString *cacheName = [self.dataTable newFilenameMDCache];
	return [self newUrlCacheForFilename:cacheName];
}

- (NSURL *)newUrlCacheForFilename:(NSString *)filename {
	return [self.cachedFilesDirectory URLByAppendingPathComponent: filename
													  isDirectory: NO];
}

- (NSURL *)urlGuts {
	return self.documentStore.gutsURL;
}

- (NSURL *)urlMetaPlaylist {
	return self.documentStore.metadataURL;
}

#pragma mark -
#pragma mark MADCacheProtocol

- (NSURL *)cachedFilesDirectory {
	return self.documentStore.cacheDirectory;
}

#pragma mark -
#pragma mark UIDocument

- (NSDictionary <NSNumber *, NSNumber *> *)layoutHeightsBySectionKey {
	NSMutableDictionary *layoutHeights = [[NSMutableDictionary alloc] initWithCapacity:self.sectionLayoutManagers.count];
	[self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock: ^(NSNumber *key, MADSectionLayoutManager *manager, BOOL *__unused stop) {
		layoutHeights[key] = @(manager.size.height);
		
	}];
	return layoutHeights;
}

#pragma mark -
#pragma mark Reading

/// Reading MADocument has the following steps:
/// 1. Unarchive the MAD file; it's a bzip2 tar.
/// 2. Read the document definition: the portable store, converting a legacy Core Data
///    store on first open.
/// 3. Read the metadata beside it (meta.plist and the thumbnail).
///
/// UIDocument calls this from -openWithCompletionHandler:, which is how the app and
/// the CLI open a document.

- (BOOL)readFromURL:(NSURL *)url error:(NSError * __autoreleasing *)outError {

	BOOL success = NO;
	if ([url.pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument]) {
		MADArchiveManager *archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: self.urlGuts
																				   archiveURL: url];
		success = [archiveManager unarchive];
		if (!success) {
			os_log_error(GetMadLog(), "%s: Document unarchive failed.", __PRETTY_FUNCTION__);
		}
	}

	// The document definition lives in the portable store; a legacy document still holds
	// a Core Data store, which is converted to the portable form on first open.
	if (success) {
		NSError *error = nil;
		success = [self openPortableStoreWithError:&error];
		if (success) [self readDocumentMetadata];
		if (!success && error != nil && outError != NULL) {
			*outError = error;
		}
	}
	return success;
}

/// The metadata UIDocument does not know about: the thumbnail, and the small
/// version/generator plist UIManagedDocument used to read as "additional content".
- (void)readDocumentMetadata {

	NSData *imageData = nil;
	NSString *thumbnailPath = self.thumbnailURL.path;
	if (thumbnailPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
		imageData = [NSData dataWithContentsOfURL:self.thumbnailURL
										  options:NSDataReadingUncached
											error:NULL];
	}
	if (imageData != nil) {
		self.extraInformation[@"thumbnail@2x.png"] = [UIImage imageWithData:imageData];
	}

	NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfURL:self.urlMetaPlaylist];
	NSString *generator = metadata[MADDocumentInfoKeyGenerator];
	NSNumber *version = metadata[MADDocumentInfoKeyVersion];
	self.extraInformation[MADDocumentInfoKeyGenerator] = generator ?: @"MAD Designer";
	self.extraInformation[MADDocumentInfoKeyVersion] = version ?: @1.0;
}

- (BOOL)openPortableStoreWithError:(NSError * __autoreleasing *)error {
	return [self.documentStore openWithError: error];
}

#pragma mark -
#pragma mark Error handling

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
	[super handleError:error userInteractionPermitted:userInteractionPermitted];
	
	os_log_error(GetMadLog(), "MADocument Error (Show UI %s): %s\n\t%s", userInteractionPermitted ? "YES" : "NO", error.localizedFailureReason.UTF8String, error.localizedDescription.UTF8String);

	// NSDetailedErrorsKey is Core Data's; the framework no longer links it, and the
	// key is just this string.  Errors that do not carry it simply log nothing more.
	NSArray *detailErrors = [error.userInfo objectForKey:@"NSDetailedErrors"];
	if (detailErrors.count > 0) {
		for (NSError *detailError in detailErrors) {
			os_log_error(GetMadLog(), "  Error: %@\n\t%@", detailError.localizedFailureReason, detailError.localizedDescription);
		}
	}
}

#pragma mark -
#pragma mark Writing

// UIDocument's file-wrapper save is replaced by the store-and-archive path: the
// document definition lives in the portable store, and everything else in the guts
// directory.  `contents` is the file-wrapper contents UIDocument's machinery would
// carry, which the portable store does not have; it is ignored, and the store write
// below is the save.
- (BOOL)writeContents:(id)__unused contents
			  toURL:(NSURL *)absoluteURL
	forSaveOperation:(UIDocumentSaveOperation)__unused saveOperation
 originalContentsURL:(NSURL *)__unused absoluteOriginalContentsURL
			   error:(NSError * __autoreleasing *)outError {
	return [self writeStoreAndArchiveWithError:outError];
}

- (BOOL)writeContents:(id)__unused contents
		andAttributes:(NSDictionary *)__unused additionalFileAttributes
		  safelyToURL:(NSURL *)__unused url
	 forSaveOperation:(UIDocumentSaveOperation)__unused saveOperation
				error:(NSError * __autoreleasing *)outError {
	return [self writeStoreAndArchiveWithError:outError];
}

// UIDocument's save machinery is built around the file-wrapper model; the document's
// persistence is the portable store plus the archive, so the save is that, directly.
- (void)saveToURL:(NSURL *)__unused url
 forSaveOperation:(UIDocumentSaveOperation)__unused saveOperation
completionHandler:(void (^ __nullable)(BOOL))completionHandler {
	BOOL success = [self writeStoreAndArchiveWithError:NULL];
	if (success) {
		// UIDocument's own save machinery records the write this way; without the
		// modification date the document state stays Closed and the close flow
		// treats it as already closed, skipping its save.
		[self setFileModificationDate:[NSDate date]];
		[self updateChangeCount:UIDocumentChangeCleared];
	}
	if (completionHandler != nil) completionHandler(success);
}

// Closing is the final save (if anything changed), releasing the store, and then
// UIDocument's own bookkeeping: the state transitions, the autosave timer and the
// file presenter UIDocument registers while open.  The document's persistence is the
// portable store plus the archive, so the save is done here rather than through
// UIDocument's file-wrapper machinery.
- (void)closeWithCompletionHandler:(void (^ __nullable)(BOOL))completionHandler {
	BOOL success = YES;
	if (self.hasUnsavedChanges) {
		NSError *error = nil;
		success = [self writeStoreAndArchiveWithError:&error];
		if (!success) {
			os_log_error(GetMadLog(), "Error saving before close: %s", (error.localizedDescription ?: @"unknown error").UTF8String);
		} else {
			[self setFileModificationDate:[NSDate date]];
			[self updateChangeCount:UIDocumentChangeCleared];
		}
	}
	[self.documentStore close];

	// A document that was never opened through UIDocument (or is already closed) has
	// no file presenter to release and no state to move, and UIDocument's close
	// machinery does not call back for it.  Report the close directly; the state is
	// already Closed.
	if (self.documentState == UIDocumentStateClosed) {
		if (completionHandler != nil) completionHandler(success);
		return;
	}

	[super closeWithCompletionHandler:^(BOOL superSuccess) {
		if (completionHandler != nil) completionHandler(success && superSuccess);
	}];
}

/// The document's one write: save the store context, write the metadata plist, and
/// archive the guts directory over the document file.
- (BOOL)writeStoreAndArchiveWithError:(NSError * __autoreleasing *)outError {
	NSError *error = nil;
	if (![self.storeContext save:&error]) {
		if (outError != nil) {
			*outError = error.copy;
		}
		return NO;
	}

	[self writeDocumentMetadata];

	MADArchiveManager *archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL:self.urlGuts
																		   archiveURL:self.fileURL];
	archiveManager.checkpointed = YES;
	return [archiveManager archive:YES];
}

/// The version/generator plist that lives beside the store in the guts directory.
/// UIManagedDocument wrote this through -writeAdditionalContent:…; now the document
/// writes it as part of the save.  A failed write is logged and does not fail the
/// save, matching the old path's behaviour.
- (void)writeDocumentMetadata {

	if (self.extraInformation == nil) {
		self.extraInformation = [[NSMutableDictionary alloc] initWithCapacity:3];
	}
	NSNumber *version = self.extraInformation[MADDocumentInfoKeyVersion] ?: @1.0;
	NSString *generator = self.extraInformation[MADDocumentInfoKeyGenerator] ?: @"MAD Designer";
	self.extraInformation[MADDocumentInfoKeyVersion] = version;
	self.extraInformation[MADDocumentInfoKeyGenerator] = generator;

	NSDictionary<NSString *, id> *metadata = @{ MADDocumentInfoKeyVersion: version,
												MADDocumentInfoKeyGenerator: generator };
	if (![metadata writeToURL: self.urlMetaPlaylist atomically:NO]) {
		os_log_error(GetMadLog(), "Write to %@ failed", self.urlMetaPlaylist);
	}
}

- (NSDictionary *)fileAttributesToWriteToURL: (NSURL *)url
							forSaveOperation: (UIDocumentSaveOperation)saveOperation
									   error: (NSError * __autoreleasing *)outError {
	NSDictionary *fileAttributes;
	// The viewer's page view writes the thumbnail to the cache beside the
	// document; the Core Data-era -thumbnail property has no writer.  Read the
	// file when the property is empty so the Files app's icon is not always
	// blank.  The deprecated attribute keys stay behind the pragma below.
	UIImage *thumbnail = self.thumbnail;
	if (thumbnail == nil) {
		NSData *imageData = [NSData dataWithContentsOfURL:self.thumbnailURL
												  options:NSDataReadingUncached
													error:NULL];
		if (imageData != nil) thumbnail = [UIImage imageWithData:imageData];
	}
	if (thumbnail != nil) {
		thumbnail = thumbnail.copy;
		// NSThumbnail1024x1024SizeKey / NSURLThumbnailDictionaryKey are deprecated in
		// iOS 15; the replacement is a QuickLook thumbnail extension, which is a new
		// target rather than a substitution, so the attribute-based thumbnail is kept
		// for now.  See BUGS.md "The document thumbnail uses the deprecated QuickLook
		// file-attribute keys".
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		NSDictionary *thumbnails = [[NSDictionary alloc] initWithObjectsAndKeys:
									thumbnail, NSThumbnail1024x1024SizeKey, nil];
		thumbnail = nil;

		fileAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								thumbnails, NSURLThumbnailDictionaryKey, nil];
#pragma clang diagnostic pop
	} else {
		fileAttributes = @{};
	}
	
	
	return fileAttributes;
}


- (NSString *)fileNameExtensionForType: (NSString *)typeName
						 saveOperation: (UIDocumentSaveOperation)saveOperation {
	return MADFileExtentionMobleApplicationDocument;
}

- (void)autosaveWithCompletionHandler:(void (^ __nullable)(BOOL success))completion {

	if (self.isAutosaveEnabled) {
		[super autosaveWithCompletionHandler:completion];
	} else {
		completion(NO);
	}
	
}

#pragma mark -
#pragma mark MADocument Overrides

- (void)setDatabase:(MADDatabase *)database {
	if (_database != database) {
		_database = database;
		_database.delegate = self;
	}
}

#pragma mark -
#pragma mark UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController *)ic { }
- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController *)ic { }
- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)ic { }
- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)ic { }

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)controller {
	self.printingReportFormatter.dataDelegate = self;
	self.printingReportFormatter.layoutSize = controller.printPaper.paperSize;
	self.printingReportFormatter.marginUsingPrintableRect = controller.printPaper.printableRect;
	self.printingReportFormatter.didRefresh = YES;
	[self.printingReportFormatter format: controller.printPaper.paperSize
						  contentChanged: NO];
}

- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)controller {
	self.printingReportFormatter = nil;
}

- (void)updatePrintingReportFormatter {
	MADReportFormatter *reportFormatter = [MADReportFormatter newReportFormatterWithLayout: self
																				   options: MADReportFormatterOptionsMargin];
	reportFormatter.overrideIdentifier = @"madprinter";
	self.printingReportFormatter = reportFormatter;
}

#pragma mark -
#pragma mark Query Building

- (void)addQueryGroupWithQueryField: (int64_t)queryFieldObjectID
					   andSortOrder: (MADSortOrder)sortOrder; {

	RptqStoreContext *context = self.storeContext;
		
		RptqQueryField *queryField = (RptqQueryField *)[context objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:queryFieldObjectID];
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: context];
		
		
		RptqQueryGroup *queryGroup = [RptqQueryGroup newQueryGroupQueryWithSortOrder: sortOrder
															 andManagedObjectContext: context];
		
		queryGroup.hasField = queryField;   //Retain cycle
		
		//Create group header (contains a retain cycle)
		RptqDocumentSection *headerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupHeader
																   forManagedObjectContext: context];

		RptqDocumentSectionRows *headerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:context];
		headerSectionRow.inSection = headerSection;
		
		NSMutableOrderedSet *headerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: headerSectionRow];
		headerSection.hasRows = headerSectionRows;
		
		[queryGroup addHasSectionObject:headerSection];
		
		//Create group footer (contains a retain cycle)
		RptqDocumentSection *footerSection;
		footerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupFooter
											  forManagedObjectContext: context];
		RptqDocumentSectionRows *footerSectionRow;
		footerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext: context];
		footerSectionRow.inSection = footerSection;
		
		NSMutableOrderedSet *footerSectionRows;
		footerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: footerSectionRow];
		footerSection.hasRows = footerSectionRows;
		
		[queryGroup addHasSectionObject:footerSection];
		
		
		MADSectionLayoutManager *layoutManagerHeader;
		layoutManagerHeader = [[MADSectionLayoutManager alloc] initWithDocumentSection:headerSection];
		NSNumber *key = @(headerSection.identifier);
		self.sectionLayoutManagers[key] = layoutManagerHeader;
		
		MADSectionLayoutManager *layoutManagerFooter;
		layoutManagerFooter = [[MADSectionLayoutManager alloc] initWithDocumentSection:footerSection];
		key = @(footerSection.identifier);
		self.sectionLayoutManagers[key] = layoutManagerFooter;


		RptqDatabase *database = rptqDocument.hasDatabaseSchemas.anyObject;
		RptqQuery *query = database.hasQueries.anyObject;
		[query addHasQueryGroupsObject: queryGroup];

		NSError *error = NULL;
		BOOL saved = [context save:&error];
		if (!saved && error != nil) {
			os_log_error(GetMadLog(), "Error saving managed object: %@", error);
		}
		
	[self updateChangeCount: UIDocumentChangeDone];
	[self autosaveWithCompletionHandler:^(BOOL __unused success) { }];
}

#pragma mark -
#pragma mark Store Context Notifications

- (void)handleManagedObjectContextDidChange:(NSNotification *)notification {
	if (notification.object != self.storeContext) return;
	self.documentStatus.needsSave = YES;
	self.documentStatus.contextChagned = YES;
}

- (void)handleManagedObjectContextDidSave:(NSNotification *)notification {
	if (notification.object != self.storeContext) return;
	self.documentStatus.saveInProgress = NO;
	self.documentStatus.needsSave = NO;
}

- (void)handleManagedObjectContextWillSave:(NSNotification *)notification {
	if (notification.object != self.storeContext) return;
	self.documentStatus.saveInProgress = YES;
}

#pragma mark - UIDocument Notifications

- (void)handleDocumentStateChanged:(NSNotification *)notification {
	if (notification.object != nil) {
		switch (((MADocument *)notification.object).documentState) {
			case UIDocumentStateClosed:
				os_log_debug(GetMadLog(), "Document state closed.");
				break;
			case UIDocumentStateEditingDisabled:
				os_log_debug(GetMadLog(), "Document state editing disabled.");
				break;
			case UIDocumentStateInConflict:
				os_log_debug(GetMadLog(), "Document state in conflict.");
				break;
			case UIDocumentStateNormal:
				os_log_debug(GetMadLog(), "Document state normal.");
				break;
			case UIDocumentStateSavingError:
				os_log_debug(GetMadLog(), "Document state saving error.");
				break;
			case UIDocumentStateProgressAvailable:
				os_log_debug(GetMadLog(), "Document progress: %@", notification);
				break;
			default:
				break;
		}
	}
}

#pragma mark - Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
	NSDictionary *parameters = sender.userInfo;
	NSNumber *pageNumber = parameters[MTDatabaseNumberOfPagesFormattedKey];
	
	NSString *decimalString = [NSNumberFormatter localizedStringFromNumber: pageNumber
															   numberStyle: NSNumberFormatterDecimalStyle];
	NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
	NSString *readRecords = [[NSString alloc] initWithFormat: formatString, decimalString];
	[self.documentStatusProtocol performSelectorOnMainThread: @selector(setStatusText:)
												  withObject: readRecords
											   waitUntilDone: NO];
}

#pragma mark -
#pragma mark MADDatabaseResultsProtocol

- (MADCredential *)getCredentialsForKey:(NSString *)key {
	MADCredential *credentials = [self.documentDelegate getCredentialsForKey:key];
	return credentials;
}

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
	if ([query isKindOfClass:[MADQueryFull class]]) {
		self.dataTable.dataDelegate = self;
		return self.dataTable;
	} else {
		return nil;	// ! nil returned from a method that is expected to return a non-null value
	}
}

#pragma mark -
#pragma mark The render half's reads

// Every read the renderer, the element references and the formatter's data source ask
// for is MADDocumentRenderDataSource's, one implementation shared with the headless
// document (MAD_LINUX.md §9 Phase E).  These forward, so the app's callers keep asking
// the document and the answers stay exactly what they were.

- (MADDocumentRenderDataSource *)renderDataSource {
	if (_renderDataSource == nil) {
		_renderDataSource = [[MADDocumentRenderDataSource alloc] initWithDocument: self];
	}
	return _renderDataSource;
}

#pragma mark MADReportFormatterDataSource Protocol

- (NSEnumerator *)enumeratorForReportData { return [self.renderDataSource enumeratorForReportData]; }

- (BOOL)cacheExist { return [self.renderDataSource cacheExist]; }

- (NSDictionary *)dataForRow:(NSUInteger)rowID { return [self.renderDataSource dataForRow: rowID]; }

- (NSDictionary *)dataForRow:(NSUInteger)rowID error:(NSError *__autoreleasing *)outError {
	return [self.renderDataSource dataForRow: rowID error: outError];
}

#pragma mark MADPrintPageRendererDataSourceProtocol

// -database, -dataTable and -reportFormatter are the document's own state (they are
// what the shared reads ask it for), so they stay where they were.

- (NSDictionary *)dataForRow:(NSUInteger)rowID
					  column:(NSString *)columnKey
					   error:(NSError * __autoreleasing *)error {
	return [self.renderDataSource dataForRow: rowID column: columnKey error: error];
}

- (NSArray <NSString *> *)groupLevelKeyNames { return [self.renderDataSource groupLevelKeyNames]; }

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID { return [self.renderDataSource groupLevelKeys: rowID]; }

- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber {
	return [self.renderDataSource groupKeys: rowID groupNumber: groupNumber];
}

- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys groupID:(int64_t)groupID {
	return [self.renderDataSource dataForGroups: groupKeys groupID: groupID];
}

- (MADResult *)dataForRows:(NSArray *)rowIDs column:(NSString *)columnKey groups:(NSArray *)groupKeys
				  function:(MTAggregateFunctionType)function groupBy:(MTAggregateGroupByType)groupBy {
	return [self.renderDataSource dataForRows: rowIDs column: columnKey groups: groupKeys function: function groupBy: groupBy];
}

- (NSUInteger)rowIDFirstOfReport { return [self.renderDataSource rowIDFirstOfReport]; }

- (NSUInteger)rowIDLastOfReport { return [self.renderDataSource rowIDLastOfReport]; }

- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page { return [self.renderDataSource rowIDFirstOfPage: page]; }

- (NSUInteger)rowIDLastOfPage:(NSUInteger)page { return [self.renderDataSource rowIDLastOfPage: page]; }

- (NSDictionary *)dataForRowReportFirst { return [self.renderDataSource dataForRowReportFirst]; }

- (NSDictionary *)dataForRowReportLast { return [self.renderDataSource dataForRowReportLast]; }

- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex { return [self.renderDataSource dataForRowPageFirst: pageIndex]; }

- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex { return [self.renderDataSource dataForRowPageLast: pageIndex]; }

- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex { return [self.renderDataSource rowIDsForPage: pageIndex]; }

#pragma mark -
#pragma mark Helpers

- (void)dataTableSetDataDelegate:(id <MADDataProtocol>)delegage {
	self.dataTable.dataDelegate = delegage;
}

- (BOOL)dataTableMakeCache {
	return [self dataTableMakeCache:self.urlDataTableCache];
}

- (BOOL)dataTableMakeCache:(NSURL *)url {
	NSError *error = nil;
	BOOL result = [self.dataTable cacheWithUrl:url error:&error];
	if (error != nil) {
		os_log_error(GetMadLog(), "Error: %@", error);
	}
	return result;
}

- (void)dataTableSort:(RptqQuery *)query {
	NSArray *sortDescriptors = [query sortDescriptorsForDatabase:self.database];
	[self.dataTable sortUsingDescriptors:sortDescriptors];
}

- (BOOL)hasCachedData {
	return _cachedData;
}

- (void)setCachedData:(BOOL)cachedData {
	_cachedData = cachedData;
}

- (void)saveContext {
	NSError *error = nil;
	if (self.storeContext != nil && ![self.storeContext save:&error]) {
		os_log_error(GetMadLog(), "Error saving the portable store: %s", error.localizedDescription.UTF8String);
	}
}

- (MTPaper *)paper {
	if (_paper == nil) {
		RptqDocument *document = [self activeDocumentModel];
		MTPaper *paper = [[MTPaper alloc] initWithType: document.paperType];
		self.paper = paper;
	}
	return _paper;
}

- (void)resetPaper {
	self.paper = nil;
}

- (NSURL *)portableStoreURL {
	return self.documentStore.portableStoreURL;
}

- (RptqStoreContext *)storeContext {
	// UIDocument's save machinery and the create chain both reach this from
	// background threads, and a new document has no guts directory until the store
	// creates one -- MADDocumentStore owns both of those facts.
	[self.documentStore openWithError: NULL];
	return self.documentStore.context;
}

/// The context is MADDocumentStore's.  A caller that hands one over -- the test
/// harness injects one, nothing in the app does -- replaces it wholesale, which is
/// what the KVC this responds to has always meant.
- (void)setStoreContext:(RptqStoreContext *)storeContext {
	self.documentStore.context = storeContext;
}

- (RptqStoreContext *)managedObjectContext {
	return self.storeContext;
}

// UIDocument's save machinery asks for the file wrapper here, and UIManagedDocument's
// implementation walks a Core Data stack that no longer exists.  The portable store
// is written by writeContents:andAttributes:safelyToURL:..., so there is nothing to
// hand back.
- (id)contentsForType:(NSString *)typeName error:(NSError * __autoreleasing *)outError {
	return nil;
}

// UIDocument's undoManager is nil until someone sets one; the designer registers
// every edit against it, so hand back a live manager and keep it across saves.
- (NSUndoManager *)undoManager {
	NSUndoManager *undoManager = [super undoManager];
	if (undoManager == nil) {
		undoManager = [[NSUndoManager alloc] init];
		[super setUndoManager:undoManager];
	}
	return undoManager;
}

- (RptqDocument *)activeDocumentModel {

	if (_activeDocumentModel == nil) {

		RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: self.storeContext];

		[self resetPaper];
		[self resetMainQuery];
		[self resetSectionLayoutManagers];
		[self resetReportFormatter];

		_activeDocumentModel = document;

	}
	return _activeDocumentModel;
}

- (NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *)sectionLayoutManagers {
	if (_sectionLayoutManagers.count == 0) {
		NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers = [[NSMutableDictionary alloc] init];
		RptqDocumentSectionEnumerator *sections = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.activeDocumentModel];
		for (RptqDocumentSection *reportSection in sections) {
			MADSectionLayoutManager *layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
			sectionLayoutManagers[@(reportSection.identifier)] = layoutManager;
		}
		_sectionLayoutManagers = sectionLayoutManagers;
	}
	return _sectionLayoutManagers;
}

- (void)resetSectionLayoutManagers {
	[_sectionLayoutManagers removeAllObjects];
}

- (void)removeDocumentObjectWithObjectID:(int64_t)objectID {

	RptqStoreContext *context = self.storeContext;
	RptqDocumentElement *element;
	element = [RptqDocumentElement newDocumentElementWithIdentifier:objectID
												  fromObjectContext:context];
	RptqDocumentSection *parentSection = element.inSectionRow.inSection;
	MADSectionLayoutManager *layoutManager;
	NSNumber *key = @(parentSection.identifier);
	layoutManager = self.sectionLayoutManagers[key];
	[RptqDocumentElement removeDocumentObject: element
							fromParentSection: parentSection
							withLayoutManager: layoutManager];

	NSError *error = NULL;
	BOOL saved = [context save:&error];
	if (!saved && error != nil) {
		os_log_error(GetMadLog(), "Error saving managed object: %@", error);
	}
	[self updateChangeCount: UIDocumentChangeDone];

}

- (void)deleteAggregateFieldRelatedToTable: (int64_t)deleatedTableObjectID
								 inContent: (RptqStoreContext *)managedObjectContext {
	NSArray *objectsToDelete = [managedObjectContext objectsForEntity:NSStringFromClass([RptqDocumentElement class])];
	for (RptqDocumentElement *documentObject in objectsToDelete) {
		if (![documentObject isKindOfClass:[RptqDocumentElementAggregate class]]) continue;
		if (((RptqDocumentElementAggregate *)documentObject).aggregateField.inQueryTable.identifier != deleatedTableObjectID) continue;
		RptqDocumentSection *parentSection = documentObject.inSectionRow.inSection;
		MADSectionLayoutManager *layoutManager = self.sectionLayoutManagers[@(parentSection.identifier)];
		[RptqDocumentElement removeDocumentObject:documentObject
								fromParentSection:parentSection
								withLayoutManager:layoutManager];
		[managedObjectContext deleteObject:documentObject error:NULL];
	}
}

- (void)deleteDatafieldsRelatedToTable: (int64_t)deleatedTableObjectID
							 inContent: (RptqStoreContext *)managedObjectContext {
	NSArray *objectsToDelete = [managedObjectContext objectsForEntity:NSStringFromClass([RptqDocumentElement class])];
	for (RptqDocumentElement *documentObject in objectsToDelete) {
		if (![documentObject isKindOfClass:[RptqDocumentElementLabelDataField class]]) continue;
		if (((RptqDocumentElementLabelDataField *)documentObject).referencesQueryField.inQueryTable.identifier != deleatedTableObjectID) continue;
		RptqDocumentSection *parentSection = documentObject.inSectionRow.inSection;
		MADSectionLayoutManager *layoutManager = self.sectionLayoutManagers[@(parentSection.identifier)];
		[RptqDocumentElement removeDocumentObject: documentObject
								fromParentSection: parentSection
								withLayoutManager: layoutManager];
		[managedObjectContext deleteObject:documentObject error:NULL];
	}
}

- (void)removeGroupWitObjectID:(int64_t)groupID
	  fromManagedObjectContext:(RptqStoreContext *)managedObjectContext {
	
	
	
	RptqQueryGroup *group = (RptqQueryGroup *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryGroup class]) identifier:groupID];
	if (group != nil) {
		RptqQuery *query = group.inQuery;
		
		NSArray *sections = group.hasSection.allObjects;
		NSAssert(sections.count == 2, @"Expecting a header and footer.");
		
		RptqDocumentSection *section0 = sections[0];
		RptqDocumentSection *section1 = sections[1];
		[self.sectionLayoutManagers removeObjectForKey:@(section0.identifier)];
		[self.sectionLayoutManagers removeObjectForKey:@(section1.identifier)];
		
		[group removeHasSectionObject: section0];
		[group removeHasSectionObject: section1];
		
		[query.storeContext deleteObject: group error:NULL];
		[query removeHasQueryGroupsObject: group];
		
		NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(weight))
															   ascending: YES];
		
		NSArray <RptqQueryGroup *> *sortedGroups = [query.hasQueryGroups sortedArrayUsingDescriptors:@[sort]];
		
		int16_t counter = 0;
		for (RptqQueryGroup *sortedGroup in sortedGroups) {
			sortedGroup.weight = counter;
			counter++;
		}
		
	}
		
	NSError *error = NULL;
	BOOL saved = [managedObjectContext save:&error];
	if (!saved && error != nil) {
		os_log_error(GetMadLog(), "Error saving managed object: %@", error);
	}
}

- (MADQuery *)mainQuery {
	if (!_mainQuery) {
		RptqDocument *document = [self activeDocumentModel];
		RptqDatabase *database = document.defaultDatabase;
		if (database) {
			
			RptqQuery *rquery = database.defaultQuery;
			MADQueryFull *mainQuery;
			mainQuery = [[MADQueryFull alloc] initWithQuery: rquery
											 andQueryLimit: self.limitResultsDesignMode ?
																	50 : NSUIntegerMax];
			mainQuery.dataDelegate = self;
			
			NSArray *sortDescriptors = [self readCurrentSortDescriptors];
			[self.dataTable sortUsingDescriptors:sortDescriptors];
			
			_mainQuery = mainQuery;
		}
	}
	return _mainQuery;
}

- (void)resetMainQuery {
	self.mainQuery = nil;
}

- (MADReportFormatter *)reportFormatter {
	if (!_reportFormatter) {
		MADReportFormatter *formatter = [[MADReportFormatter alloc] initWithDocument: self
																			 options: MADReportFormatterOptionsNone];
		_reportFormatter = formatter;
	}
	return _reportFormatter;
}

- (void)resetReportFormatter {
	self.reportFormatter = nil;
}

- (MADDatabase *)database {
	if (!_database) {
		RptqDocument *document = [self activeDocumentModel];
		[self initializeMainDatabase:document];
	}
	return _database;
}

- (void)initializeMainDatabase:(RptqDocument *)document {
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: database.ownedByUser];
	MADDatabase *db = [MADDatabase newDatabaseWithConnection:connection];
	db.delegate = self;
	self.database = db;
}

- (void)prepareForQuery {
	NSArray *sortDescriptors = [self readCurrentSortDescriptors];
	[self.dataTable sortUsingDescriptors:sortDescriptors];
}

- (void)notifyThumbnailUpdated {
	MADNotificationFileUpdate *fileUpdate = [[MADNotificationFileUpdate alloc] initWithURL:self.thumbnailURL];
	[fileUpdate notify];
}

- (NSArray *)sortDescriptors{
	return [self readCurrentSortDescriptors];
}

- (NSArray *)readCurrentSortDescriptors {
	RptqDocument *document = self.activeDocumentModel;
	if (self.database == nil) {
		[self initializeMainDatabase:document];        // FIXME: I doubt this ever runs.
	}
	return [document.defaultDatabase.defaultQuery sortDescriptorsForDatabase:self.database];
}

- (NSURL *)copyPersistentStoreURL {
	return self.portableStoreURL;
}

#pragma mark -
#pragma mark Public

- (void)archiveAndRemoveFileWrapper {
	// The store may already be open -- the observers registered in -init reach the
	// store context lazily -- so close it before the removal; deleting a live
	// database out from under an open sqlite handle makes every later save fail
	// with SQLITE_READONLY.  The removal itself must be synchronous: the
	// file-coordinated variant deletes on a coordination queue, and the create flow
	// reopens the store immediately after this call, racing that queue's delete.
	[self.documentStore close];
	// The synchronous, uncoordinated delete: the file-coordinated variant runs on a
	// coordination queue and would race the store reopen the create flow performs
	// right after this call.
	[[NSFileManager defaultManager] removeItemAtURL:self.urlGuts error:NULL];
}

#pragma mark -
#pragma mark Helper

- (NSString *)filename {
	NSString *filename = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
	return filename;
}

#pragma mark -
#pragma mark Debugging

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	[debug appendString:@"-------------------------------\n"];
	[debug appendFormat:@"Class %@", NSStringFromClass(self.class)];
	[debug appendFormat:@"Filename:\t%@\n", [self filename]];
	[debug appendFormat:@"Status:\t%@\n", [self documentStatus]];
	[debug appendFormat:@"State:\t%lu\n", (unsigned long)[self documentState]];
	[debug appendFormat:@"Delegate:\t%@\n", [self documentDelegate]];
	[debug appendString:@"-------------------------------\n"];
	return debug;
}

@end
