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
#import "MADModel.h"
#import "MADModelDocument.h"
#import "MADModelDatabase.h"
#import "MADPrintPageRenderer.h"
#import "MADPathUtilities.h"
#import "MADImageThumbnail.h"
#import "MADArchiveManager.h"
#import "MADNotificationFileUpdate.h"
#import "RptqDataHelper.h"
#import "MADDocumentObjectDataReference.h"
#import "MADDesignerViewer.h"
#import "MADDesignerLayout.h"
#import "MADDesignerQuery.h"
#import "MADDocumentProtocol.h"
#import "MADocumentDesignerProtocol.h"
#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionType.h"
#import "MADSortOrder.h"
#import "MADConstants.h"
#import "MADSectionLayoutManager.h"
#import "MADQueryFull.h"
#import "MADConstants.h"
#import "MADActivityIndicator.h"
#import "MADocumentState.h"
#import "MADReportFormatter.h"
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
#import "RptqRect.h"
#import "RptqSize.h"
#import "RptqDirectionalAsymmetry.h"
#import "MADDataTable+Constructor.h"
#import "MADParameters+QueryCacheAggregate.h"
#import "NSPredicate+Creators.h"
#import "MADDatabase+Constructor.h"
#import "MADQuery+Extras.h"
#import "miniz.h"
#import "madlog.h"

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

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <Foundation/NSEnumerator.h>
#import <CoreData/NSManagedObjectModel.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSPersistentStoreCoordinator.h>
#import <CoreData/CoreDataErrors.h>
#import <CoreData/NSManagedObjectID.h>

#import <UIKit/UIScreen.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIPrintPaper.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIPrintInteractionController.h>

#import <os/log.h>
#import <setjmp.h>
#import <asl.h>
#import <mach/machine/vm_param.h>

typedef void (^MTCompletionHandlerSuccess)(BOOL success);

/*
 {
	additionalContent =     {
		generator = "MAD Designer";
		"thumbnail.png" = "<UIImage: 0x1fea0b10>";
		version = 1;
	};
	fileType = "com.everydayapps.productivity.mad";
	parentContext = "<NSManagedObjectContext: 0xffffffff>";
 }
 */

NSString * const MADMimeType									= @"application/vnd.everydayapps.mad";
NSString * const MADDocumentInfoKeyThumbnail					= @"thumbnail";

static NSString * const MTDocumentAdditionalContentKey			= @"additionalContent";
static NSString * const MTDocumentFileTypeKey					= @"fileType";
static NSString * const MTDocumentParentContextKey				= @"parentContext";

static NSString * const MADDocumentInfoKeyThumbnailStandard		= @"thumbnail.png";
static NSString * const MADDocumentInfoKeyThumbnailRetna		= @"thumbnail@2x.png";
static NSString * const MADDocumentInfoKeyMeta					= @"meta.plist";
static NSString * const MADDocumentInfoKeyVersion				= @"version";
static NSString * const MADDocumentInfoKeyGenerator				= @"generator";

static NSString * const MADFileNameMetaPlist					= @"meta.plist";

static NSString * const MADPersistentStoreAliasMad				= @"analyitics";
static NSString * const MADDocumentTypeUtiMad					= @"com.everydayapps.productivity.mad";

static NSString * const MNSInterfaceMessageErrorFailedToCreateReport	= @"Failed to create report document.";
static NSString * const MNSInterfaceTitleProblem						= @"Problem";

static NSString * const MADManagedObjectModelName						= @"MAD";
static NSString * const MADManagedObjectModelExtention					= @"momd";

#if MAD_DESIGNER == 1 || MAD_TEST == 1
  NSString * const MADUbiquitousPeerToken = @"MADDESIGNER";
#elif MAD_VIEWER == 1
  NSString * const MADUbiquitousPeerToken = "MADVIEWER";
#endif

static inline NSRange MADRangeToGroup(int64_t);
void fail(char *, const char *, int);
void msg(const char *);
void madwarn(char *,  const char *);

static inline NSRange MADRangeToGroup(int64_t groupNumber) {
	return NSMakeRange(0, (NSUInteger)groupNumber + 1);
}

void fail(char *err, const char *err2, int n) { }
void msg(const char *err) { }
void madwarn(char *err,  const char *err2) { }

@interface MADocument () <MADReportFormatterDataSource, MADCacheProtocol, MADDatabaseResultsProtocol, MADocumentDesignerProtocol>

@property (readwrite, nonatomic, strong) MADReportFormatter *printingReportFormatter;

@property (nonatomic, readwrite, strong) RptqDocument *activeDocumentModel;
@property (nonatomic, readwrite, strong) NSManagedObjectModel *madManagedObjectModel;

@property (nonatomic, readwrite, strong) NSMutableDictionary *extraInformation;
@property (nonatomic, readwrite, strong) UIImage *thumbnail;

@property (nonatomic, readwrite, strong) MADDataTableFast *dataTable;
@property (nonatomic, readwrite, strong) MADDatabase *database;
@property (nonatomic, readwrite, strong) MADQueryFull *mainQuery;

@property (nonatomic, readwrite, strong) NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers;

@property (nonatomic, readwrite, strong) MADModelDocument *documentModel;
@property (nonatomic, readwrite, strong) MTPaper *paper;

@property (nonatomic, readwrite, copy) NSURL *urlDataTableCache;
@property (nonatomic, readwrite, copy) NSURL *urlGuts;
@property (nonatomic, readwrite, copy) NSURL *urlMetaPlaylist;

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

- (CGSize)paperSize {
	return _paper.paperSize;
}

- (BOOL)didRefresh {
	return _reportFormatter.didRefresh;
}

- (void)setRefreshed:(BOOL)refreshed {
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
	_madManagedObjectModel = nil;
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
													name: NSManagedObjectContextObjectsDidChangeNotification
												  object: self.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSManagedObjectContextDidSaveNotification
												  object: self.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSManagedObjectContextWillSaveNotification
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
		_urlGuts = [MADURLFactory newURLDocumentArchiveForFileURL: url
														extension: MADFileExtentionMobleApplicationDocumentArchive];
		_urlMetaPlaylist = [_urlGuts URLByAppendingPathComponent: MADFileNameMetaPlist];
		
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
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleManagedObjectContextDidChange:)
													 name: NSManagedObjectContextObjectsDidChangeNotification
												   object: self.managedObjectContext];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleManagedObjectContextDidSave:)
													 name: NSManagedObjectContextDidSaveNotification
												   object: self.managedObjectContext];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleManagedObjectContextWillSave:)
													 name: NSManagedObjectContextWillSaveNotification
												   object: self];
		
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
		if (![NSThread isMainThread]) {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[strongDocument closeWithCompletionHandler:^(BOOL successClose) {
					completion(successClose, fileURL, gutsUrl);
				}];
			}];
		} else {
			[strongDocument closeWithCompletionHandler:^(BOOL successClose) {
				completion(successClose, fileURL, gutsUrl);
			}];
		}
	} else {
		completion(YES, fileURL, gutsUrl);
	}
}

// Helpers

- (MADModelDocument *)documentModel {
	if (!_documentModel) {
		MADModelDocument *documentModel;
		documentModel = [[MADModelDocument alloc] initWithContext:self.managedObjectContext];
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

#pragma mark -
#pragma mark MADCacheProtocol

- (NSURL *)cachedFilesDirectory {
	return [MADURLFactory newURLCacheFilesDirectoryForFilename:self.filename];
}

#pragma mark -
#pragma mark UIDocument

- (NSDictionary <NSNumber *, NSNumber *> *)layoutHeightsBySectionKey {
	NSMutableDictionary *layoutHeights = [[NSMutableDictionary alloc] initWithCapacity:self.sectionLayoutManagers.count];
	[self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock: ^(NSNumber *key, MADSectionLayoutManager *manager, BOOL *stop) {
		layoutHeights[key] = @(manager.size.height);
		
	}];
	return layoutHeights;
}

- (NSDictionary *)persistentStoreOptions {
	return @{
		NSInferMappingModelAutomaticallyOption: @YES,
		NSMigratePersistentStoresAutomaticallyOption: @YES
	};
}

#pragma mark -
#pragma mark Reading

/// Reading MADocument has the following steps:
/// 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
/// 2. Read the unarchived file.  It's currently a Core Data file.

- (BOOL)readFromURL:(NSURL *)url error:(NSError * __autoreleasing *)outError {

	__block BOOL success = NO;
	if ([url.pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument]) {
		MADArchiveManager *archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: _urlGuts
																				   archiveURL: url];
		success = [archiveManager unarchive];
		if (!success) {
			os_log_error(GetMadLog(), "%s: Document unarchive failed.", __PRETTY_FUNCTION__);
		}
	}
	
	/// 2. Read the unarchived file.  It's currently a Core Data file.
	NSError *error = NULL;
	success = success ? [super readFromURL:_urlGuts error:&error] : NO;
	if (error && outError != NULL) { // Check if outError is not NULL before dereferencing
		*outError = error;
	}
	return success;
	
}

#pragma mark -
#pragma mark Error handling

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
	[super handleError:error userInteractionPermitted:userInteractionPermitted];
	
	os_log_error(GetMadLog(), "MADocument Error (Show UI %s): %s\n\t%s", userInteractionPermitted ? "YES" : "NO", error.localizedFailureReason.UTF8String, error.localizedDescription.UTF8String);

	NSArray *detailErrors = [error.userInfo objectForKey:NSDetailedErrorsKey];
	if (detailErrors.count > 0) {
		for (NSError *detailError in detailErrors) {
			os_log_error(GetMadLog(), "  Error: %@\n\t%@", detailError.localizedFailureReason, detailError.localizedDescription);
		}
	}
}

#pragma mark -
#pragma mark Writing

- (BOOL)writeContents:(id)contents
		andAttributes:(NSDictionary *)additionalFileAttributes
		  safelyToURL:(NSURL *)url
	 forSaveOperation:(UIDocumentSaveOperation)saveOperation
				error:(NSError * __autoreleasing *)outError {
	NSError *error = nil;
	if (![super writeContents:contents andAttributes:additionalFileAttributes
				  safelyToURL:self.urlGuts forSaveOperation:saveOperation error:&error]) {
		if (outError != nil) {
			*outError = error.copy;
		}
		return NO;
	}

	MADArchiveManager *archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL:self.urlGuts
																			   archiveURL:self.fileURL];
	return [archiveManager archive:YES];
}

- (NSDictionary *)fileAttributesToWriteToURL: (NSURL *)url
							forSaveOperation: (UIDocumentSaveOperation)saveOperation
									   error: (NSError * __autoreleasing *)outError {
	id fileAttributes;
	if (self.thumbnail != nil) {
		UIImage *thumbnail = self.thumbnail.copy;
		NSDictionary *thumbnails = [[NSDictionary alloc] initWithObjectsAndKeys:
									thumbnail, NSThumbnail1024x1024SizeKey, nil];
		thumbnail = nil;
		
		fileAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								thumbnails, NSURLThumbnailDictionaryKey, nil];
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
#pragma mark UIManagedDocument Overrides

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL
							   error:(NSError * __autoreleasing *)error {

	NSError *readError = nil;

	NSData *imageData = nil;
	NSURL *thumbnailURL = [self thumbnailURL];
	NSString *path = thumbnailURL.path;
	if (path) {
		if ([[NSFileManager defaultManager] fileExistsAtPath: path]) {
			imageData = [NSData dataWithContentsOfURL: thumbnailURL
											  options: NSDataReadingUncached
												error: &readError];
		}
	}
	
	if (imageData != nil) {
		self.extraInformation[MADDocumentInfoKeyThumbnailRetna] = [UIImage imageWithData:imageData];
	}
	
	NSDictionary *dicionary = [[NSDictionary alloc] initWithContentsOfURL:self.urlMetaPlaylist];
	NSString *infoKeyGenerator = dicionary[MADDocumentInfoKeyGenerator];
	NSString *lastGenerator = infoKeyGenerator.copy;
	NSNumber *lastVersion = ((NSNumber *)dicionary[MADDocumentInfoKeyVersion]).copy;
	
	if (lastGenerator == nil) {
		lastGenerator = @"MAD Designer";
	}
	
	if (lastVersion == nil) {
		NSNumber *lastDocVersoin = [[NSNumber alloc] initWithDouble:1.0];
		lastVersion = lastDocVersoin;
	}
	
	self.extraInformation[MADDocumentInfoKeyGenerator] = lastGenerator;
	self.extraInformation[MADDocumentInfoKeyVersion] = lastVersion;
	
	return YES;
}

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError * __autoreleasing *)error {

	if (self.extraInformation == nil) {
		NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
		self.extraInformation = extraInfo;
	}
	NSNumber *dataVersion = [[NSNumber alloc] initWithDouble:1.0];
	self.extraInformation[MADDocumentInfoKeyVersion] = dataVersion;
	self.extraInformation[MADDocumentInfoKeyGenerator] = @"MAD Designer";
	return self.extraInformation;
}

- (BOOL)writeAdditionalContent:(id)content
						 toURL:(NSURL *)absoluteURL
		   originalContentsURL:(NSURL *)absoluteOriginalContentsURL
						 error:(NSError * __autoreleasing *)error {
	
	BOOL writeAdditionalContent = NO; // Initialize to NO by default

	if (content == [NSNull null] || self.documentStatus.isSuspended) {
		// If content is NSNull or the document is suspended, do not write additional content
		writeAdditionalContent = NO;
	} else if (content != nil) {
		// If content is not nil, write additional content
		writeAdditionalContent = YES;

		// Safely retrieve version and generator from the content dictionary
		id version = content[MADDocumentInfoKeyVersion];
		id generator = content[MADDocumentInfoKeyGenerator];

		// Create a dictionary with version and generator information
		NSDictionary<NSString *, id> *additionalContent = [[NSDictionary alloc] initWithObjectsAndKeys:
			version, MADDocumentInfoKeyVersion,
			generator, MADDocumentInfoKeyGenerator,
			nil]; // Sentinel to mark the end of the key-value pairs

		// Write the additional content to the specified URL
		if (![additionalContent writeToURL:_urlMetaPlaylist atomically:NO]) {
			NSLog(@"Write to %@ failed", _urlMetaPlaylist);
		}
	}

	return writeAdditionalContent;
}

+ (NSString *)persistentStoreName { return MADPersistentStoreAliasMad; }

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

- (void)addQueryGroupWithQueryField: (NSManagedObjectID *)queryFieldObjectID
					   andSortOrder: (MADSortOrder)sortOrder; {

	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = self.managedObjectContext;

	[private performBlockAndWait: ^{
		
		RptqQueryField *queryField = [private objectWithID:queryFieldObjectID];
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		
		
		RptqQueryGroup *queryGroup = [RptqQueryGroup newQueryGroupQueryWithSortOrder: sortOrder
															 andManagedObjectContext: private];
		
		queryGroup.hasField = queryField;   //Retain cycle
		
		//Create group header (contains a retain cycle)
		RptqDocumentSection *headerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupHeader
																   forManagedObjectContext: private];

		RptqDocumentSectionRows *headerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:private];
		headerSectionRow.inSection = headerSection;
		
		NSMutableOrderedSet *headerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: headerSectionRow];
		headerSection.hasRows = headerSectionRows;
		
		[queryGroup addHasSectionObject:headerSection];
		
		//Create group footer (contains a retain cycle)
		RptqDocumentSection *footerSection;
		footerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupFooter
											  forManagedObjectContext: private];
		RptqDocumentSectionRows *footerSectionRow;
		footerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext: private];
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
		BOOL saved = [private save:&error];
		if (!saved && error != nil) {
			os_log_error(GetMadLog(), "Error saving managed object: %@", error);
		}
		
		RptqQueryField *groupByField = queryGroup.hasField;
		if (groupByField) {
			[private refreshObject:groupByField mergeChanges:NO];
		}
		[private refreshObject:queryGroup mergeChanges:NO];
		
		RptqDocumentSection *header;
		if ((header = headerSectionRow.inSection)) {
			[private refreshObject:header mergeChanges:NO];
		}
		
		RptqDocumentSection *footer;
		if ((footer = footerSectionRow.inSection)) {
			[private refreshObject:footer mergeChanges:NO];
		}
		
		[private refreshObject:headerSectionRow mergeChanges:NO];
		[private refreshObject:footerSectionRow mergeChanges:NO];
		[private refreshObject:headerSection mergeChanges:NO];
		[private refreshObject:footerSection mergeChanges:NO];
		
		[private refreshObject:query mergeChanges:NO];
		[private refreshObject:database mergeChanges:NO];
		[private refreshObject:queryGroup mergeChanges:NO];
		[private refreshObject:rptqDocument mergeChanges:NO];
		[private refreshObject:queryField mergeChanges:NO];

		[headerSectionRows removeAllObjects];
		[footerSectionRows removeAllObjects];

	}];
	[self updateChangeCount: UIDocumentChangeDone];
	[self autosaveWithCompletionHandler:^(BOOL success) { }];
}

#pragma mark -
#pragma mark NSManagedObjectContext Notifications

- (void)handleManagedObjectContextDidChange:(NSNotification *)notification {
	//NSSet *updated = notification.userInfo[NSUpdatedObjectsKey];
	self.documentStatus.needsSave = YES;
	self.documentStatus.contextChagned = YES;
}

- (void)handleManagedObjectContextDidSave:(NSNotification *)notification {
	self.documentStatus.saveInProgress = NO;
	self.documentStatus.needsSave = NO;
}

- (void)handleManagedObjectContextWillSave:(NSNotification *)notification {
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
		return nil;
	}
}

#pragma mark -
#pragma mark MADReportFormatterDataSource Protocol

- (NSEnumerator *)enumeratorForReportData {
	return [self.dataTable enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
	NSString *path = self.urlDataTableCache.path;
	return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

- (NSDictionary *)dataForRow:(NSUInteger)rowID {
	return [self.dataTable dataForRow:rowID error:nil];
}

- (NSDictionary *)dataForRow:(NSUInteger)rowID error:(NSError *__autoreleasing *)outError {
	NSError *error = nil;
	NSDictionary *result = [self.dataTable dataForRow:rowID error:&error];
	if (error != nil) {
		os_log_error(GetMadLog(), "%s Error: %@", __PRETTY_FUNCTION__, error);
		if (outError != NULL) {
			*outError = error;
		}
	}
	return result;
}

#pragma mark -
#pragma mark MADPrintPageRendererDataSourceProtocol

- (NSDictionary *)dataForRow:(NSUInteger)rowID
					  column:(NSString *)columnKey
					   error:(NSError * __autoreleasing *)error {
	NSError * errorQ = nil;
	NSDictionary *result = [self.dataTable dataForRow:rowID column:columnKey error:&errorQ];
	if (errorQ != nil && error != NULL) {
		os_log_error(GetMadLog(), "%s Error: %@", __PRETTY_FUNCTION__, errorQ);
		*error = errorQ;
	}
	return result;
}

- (NSArray <NSString *> *)groupLevelKeyNames {
	NSMutableArray <NSString *> *groupKeys = [[NSMutableArray alloc] initWithCapacity:self.dataTable.sortDescriptors.count];
	for (NSSortDescriptor *sortDescriptor in self.dataTable.sortDescriptors) {
		NSString *key = sortDescriptor.key;
		if (key != nil) {
			[groupKeys addObject:key];
		}
	}
	return groupKeys;
}

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID {
	if (self.reportFormatter.numberOfGroups > 0) {
		NSError *error = nil;
		NSDictionary <NSString *, MADResult *> *row = [self.dataTable dataForRow: (NSUInteger)rowID error:&error];
		if (error != nil) {
			os_log_error(GetMadLog(), "%s Error: %@", __PRETTY_FUNCTION__, error);
		}
		return [self.reportFormatter newObjectArrayKeyValuesForResultRow: row];
	} else {
		return [[NSArray alloc] init];
		
	}
}

- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber {
	NSArray *groupKeys = nil;
	NSArray <MADResult *> *groupLevelKeys = [self groupLevelKeys:rowID];
	if (groupNumber < (int64_t)groupLevelKeys.count && groupNumber >= 0) {
		groupKeys = [groupLevelKeys subarrayWithRange:MADRangeToGroup(groupNumber)];
	}
	return groupKeys;
}


- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys
											 groupID:(int64_t)groupID {
	NSArray <__kindof NSDictionary *> *dataForGroup;
	if (groupID < (int64_t)groupKeys.count) {
		NSArray *groupKeysInRange = [groupKeys subarrayWithRange: MADRangeToGroup(groupID)];
		dataForGroup = [self.dataTable objectsForGroupKeys:groupKeysInRange];
	} else {
		dataForGroup = [[NSArray alloc] init];
	}
	
	return dataForGroup;
}

- (MADResult *)dataForRows:(NSArray *)rowIDs column:(NSString *)columnKey groups:(NSArray *)groupKeys
				  function:(MTAggregateFunctionType)function groupBy:(MTAggregateGroupByType)groupBy {
	os_log_t logger = GetMadLog();

	if (!self.dataTable) {
		return nil;
	}

	if (!columnKey || columnKey.length == 0) {
		os_log_error(logger, "[MADocument dataForRows] CRITICAL - columnKey is NIL or EMPTY. Query will likely fail or return incorrect data.");
	}

	NSDictionary <NSNumber *, MADResult *> *parameters = [MADParameters paramatersAggregateByType: groupBy
																						 function: function
																						   rowids: rowIDs
																						groupKeys: groupKeys
																						 fieldKey: columnKey
																						dataTable: self.dataTable];
	if (parameters != nil) {
		__kindof MADQuery *query = [[MADQuery alloc] initWithQueryType: MADQueryTypeCacheAggregateFunction
																object: parameters];
		MADResult *result = [self.dataTable runSelectQuery:query];
		return result;
	}
	return nil;
}

- (NSUInteger)rowIDFirstOfReport {
	NSUInteger rowID = NSUIntegerMax;
	MADDocumentSectionType sectionType;
	NSArray<__kindof MADSectionRepresentation *> *pageLayout = nil;
	bool found = false;
	
	for (pageLayout in self.reportFormatter.reportLayout) {
		for (MADSectionRepresentation *pageSection in pageLayout) {
			sectionType = pageSection.sectionType;
			if (sectionType == MADDocumentSectionTypeBody) {
				rowID = pageSection.detailRowId;
				found = true;
				break;
			}
		}
		if (found) {
			break;
		}
	}
	return rowID;
}

- (NSUInteger)rowIDLastOfReport {
	NSUInteger rowID = NSUIntegerMax;
	MADDocumentSectionType sectionType;
	bool found = false;
	NSArray<__kindof MADSectionRepresentation *> *pageLayout = nil;
	NSUInteger reportLayoutCount = self.reportFormatter.reportLayout.count;
	for (NSUInteger i = reportLayoutCount; i > 0; i--) {
		pageLayout = self.reportFormatter.reportLayout[i - 1];
		NSEnumerator<MADSectionRepresentation *> *reverseObjectEnumerator = [pageLayout reverseObjectEnumerator];
		for (MADSectionRepresentation *pageSection in reverseObjectEnumerator) {
			sectionType = pageSection.sectionType;
			if (sectionType == MADDocumentSectionTypeBody) {
				rowID = pageSection.detailRowId;
				found = true;
				break;
			}
		}
		if (found) {
			break;
		}
	}
	return rowID;
}

- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page {
	NSUInteger rowID = NSUIntegerMax;
	MADDocumentSectionType section;
	NSArray <MADSectionRepresentation *> *pageLayout;
	pageLayout = self.reportFormatter.reportLayout[page];
	for (MADSectionRepresentation *pageSection in pageLayout) {
		section = pageSection.sectionType;
		if (section == MADDocumentSectionTypeBody) {
			rowID = pageSection.detailRowId;
			break;
		}
	}
	return rowID;
}

- (NSUInteger)rowIDLastOfPage:(NSUInteger)page {
	NSUInteger rowID = NSUIntegerMax;
	NSEnumerator <MADSectionRepresentation *> *enumerator = [self.reportFormatter.reportLayout[page] reverseObjectEnumerator];
	for (MADSectionRepresentation *pageSection in enumerator) {
		if (pageSection.sectionType == MADDocumentSectionTypeBody) {
			return pageSection.detailRowId;
			break;
		}
	}
	return rowID;
}

- (NSDictionary *)dataForRowReportFirst {
	NSUInteger firstRowID = [self rowIDFirstOfReport];
	return firstRowID != NSUIntegerMax ? [self dataForRow:firstRowID] : nil;

}

- (NSDictionary *)dataForRowReportLast {
	NSUInteger lastRowID = [self rowIDLastOfReport];
	return lastRowID != NSUIntegerMax ? [self dataForRow:lastRowID] : nil;
}

- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex {
	NSUInteger firstRowid = [self rowIDFirstOfPage:pageIndex];
	return firstRowid != NSUIntegerMax ? [self dataForRow:firstRowid] : nil;
}

- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex {
	NSUInteger lastRowid = [self rowIDLastOfPage:pageIndex];
	return lastRowid != NSUIntegerMax ? [self dataForRow:lastRowid] : nil;
}

- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex {
	return [self.reportFormatter rowIDsForPage:pageIndex];
}

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
	NSError *error;
	if (self.managedObjectContext != nil) {
		if ((self.managedObjectContext).hasChanges && ![self.managedObjectContext save:&error]) {
			os_log_error(GetMadLog(), "Error saving managed object: %s", error.localizedDescription.UTF8String);
			[self.managedObjectContext save:nil];
		}
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

- (RptqDocument *)activeDocumentModel {

	if (_activeDocumentModel == nil) {
		
		RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: self.managedObjectContext];
		
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

	NSManagedObjectContext *private;
	private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = self.managedObjectContext;
	[private performBlockAndWait: ^{

		RptqDocumentElement *element;
		element = [RptqDocumentElement newDocumentElementWithIdentifier:objectID
													  fromObjectContext:private];
		RptqDocumentSection *parentSection = element.inSectionRow.inSection;
		MADSectionLayoutManager *layoutManager;
		NSNumber *key = @(parentSection.identifier);
		layoutManager = self.sectionLayoutManagers[key];
		[RptqDocumentElement removeDocumentObject: element
								fromParentSection: parentSection
								withLayoutManager: layoutManager];

		NSError *error = NULL;
		BOOL saved = [private save:&error];
		if (!saved && error != nil) {
			os_log_error(GetMadLog(), "Error saving managed object: %@", error);
		}
	}];
	[self updateChangeCount: UIDocumentChangeDone];

}

- (void)deleteAggregateFieldRelatedToTable: (NSManagedObjectID *)deleatedTableObjectID
								 inContent: (NSManagedObjectContext *)managedObjectContext {
	NSString *entityName = NSStringFromClass([RptqDocumentElement class]);
	NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
	NSString *keyInQueryTable, *keyInQueryTableRel;
	
	keyInQueryTableRel = NSStringFromSelector(@selector(inQueryTable));
	
	keyInQueryTable = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(aggregateField))];
	keyInQueryTable = [keyInQueryTable stringByAppendingString:keyInQueryTableRel];
	
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID: deleatedTableObjectID
															   atKeyPath: keyInQueryTable];

	fetchReqest.predicate = predicate;
	NSError *fetchError = nil;
	NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest error:&fetchError];
	if (fetchError != nil) {
		os_log_error(GetMadLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, fetchError);
	} else {
		for (RptqDocumentElement *documentObject in objectsToDelete) {
			RptqDocumentSection *parentSection = documentObject.inSectionRow.inSection;
			MADSectionLayoutManager *layoutManager = self.sectionLayoutManagers[@(parentSection.identifier)];
			[RptqDocumentElement removeDocumentObject:documentObject
									fromParentSection:parentSection
									withLayoutManager:layoutManager];
			[managedObjectContext deleteObject:documentObject];
		}
	}
}

- (void)deleteDatafieldsRelatedToTable: (NSManagedObjectID *)deleatedTableObjectID
							 inContent: (NSManagedObjectContext *)managedObjectContext {
	NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDocumentElement class])];
	NSString *keyInQueryTable = [[MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(referencesQueryField))] stringByAppendingString:NSStringFromSelector(@selector(inQueryTable))];
	
	fetchReqest.predicate = [NSPredicate newPredicateObjectWithObjectID: deleatedTableObjectID
															  atKeyPath: keyInQueryTable];
	NSError *fetchError = nil;
	NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest
																   error:&fetchError];
	if (fetchError != nil) {
		os_log_error(GetMadLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, fetchError);
	} else {
		
		
		for (RptqDocumentElement *documentObject in objectsToDelete) {
			RptqDocumentSection *parentSection = documentObject.inSectionRow.inSection;

			NSNumber *key = @(parentSection.identifier);
			MADSectionLayoutManager *layoutManager = self.sectionLayoutManagers[key];
			[RptqDocumentElement removeDocumentObject: documentObject
									fromParentSection: parentSection
									withLayoutManager: layoutManager];
			[managedObjectContext deleteObject:documentObject];
		}
	}
}

- (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID
	  fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	//NSManagedObjectContext *private;
	// = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	//private.parentContext = managedObjectContext;
	
	//[private performBlockAndWait: ^{
	
	RptqQueryGroup *group = [managedObjectContext objectWithID:groupID];
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
		
		[query.managedObjectContext deleteObject: group];
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
	NSPersistentStoreCoordinator *persistentStoreCoordinator =
		self.managedObjectContext.persistentStoreCoordinator;
	NSPersistentStore *persistentStore = persistentStoreCoordinator.persistentStores.lastObject;
	NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:persistentStore];
	return storeURL.copy;
}

#pragma mark -
#pragma mark Public

- (void)archiveAndRemoveFileWrapper {
	[MADFileUtilities removeFileAndArchiveAtURL:self.urlGuts];
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
