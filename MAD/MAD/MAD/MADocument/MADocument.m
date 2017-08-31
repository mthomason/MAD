//
//  MADocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADocument.h"

#import <os/log.h>
#import <setjmp.h>
#import <asl.h>

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

#import "MADDesignerViewer.h"
#import "MADDesignerLayout.h"
#import "MADDesignerQuery.h"

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADURL.h>
#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/UIScreen+Properties.h>
#import <MADFoundation/NSString+Common.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MADFileManager/MADFileUtilities.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADThread.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADDataTable+Constructor.h"

#import "MADDocumentProtocol.h"
#import "MADocumentDesignerProtocol.h"

#import "MADSortOrder.h"
#import "MADConstants.h"


#import <MADAPI/MADQuery.h>
#import "MADQueryFull.h"

#import "MADConstants.h"

#import "MADActivityIndicator.h"
#import "MADocumentState.h"

#import "MADReportFormatter.h"

#import "MADNotificationDidFormatPage.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqBorder.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqAlignment.h"

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

#import "RptqDocumentElementAggregate.h"

#import "RptqDocumentSectionRows.h"

#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDocumentSectionEnumerator.h"
#import "RptqRect.h"
#import "RptqSize.h"
#import "MADSectionLayoutManager.h"
#import "RptqDirectionalAsymmetry.h"

#import <MADSqlite3/MADDataTableFast.h>
#import <MADAPI/MADDatabase.h>

#import "MADModel.h"
#import "MADModelDocument.h"
#import "MADModelDatabase.h"

#import "MADPrintPageRenderer.h"

#import "NSString+RelativePath.h"

#import "MADImageThumbnail.h"

#import "miniz.h"

#import "MADArchiveManager.h"

#import <mach/machine/vm_param.h>

#import "MADNotificationFileUpdate.h"

#import "NSPredicate+Creators.h"
#import "RptqDataHelper.h"

#import "MADDatabase+Constructor.h"

#import <MADAPI/MADQueryType.h>

#import "MADQuery+Extras.h"

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

NSString * const MADMimeType                                    = @"application/vnd.everydayapps.mad";
NSString * const MADDocumentInfoKeyThumbnail                    = @"thumbnail";

static NSString * const MTDocumentAdditionalContentKey          = @"additionalContent";
static NSString * const MTDocumentFileTypeKey                   = @"fileType";
static NSString * const MTDocumentParentContextKey              = @"parentContext";

static NSString * const MADDocumentInfoKeyThumbnailStandard     = @"thumbnail.png";
static NSString * const MADDocumentInfoKeyThumbnailRetna        = @"thumbnail@2x.png";
static NSString * const MADDocumentInfoKeyMeta                  = @"meta.plist";
static NSString * const MADDocumentInfoKeyVersion               = @"version";
static NSString * const MADDocumentInfoKeyGenerator             = @"generator";

static NSString * const MADFileNameMetaPlist                   = @"meta.plist";

static NSString * const MADPersistentStoreAliasMad             = @"analyitics";
static NSString * const MADDocumentTypeUtiMad                  = @"com.everydayapps.productivity.mad";

static NSString * const MNSInterfaceMessageErrorFailedToCreateReport    = @"Failed to create report document.";
static NSString * const MNSInterfaceTitleProblem                        = @"Problem";

static NSString * const MADManagedObjectModelName                       = @"MAD";
static NSString * const MADManagedObjectModelExtention                  = @"momd";

#if MAD_DESIGNER == 1 || MAD_TEST == 1
  NSString * const MADUbiquitousPeerToken = @"MADDESIGNER";
#elif MAD_VIEWER == 1
  NSString * const MADUbiquitousPeerToken = "MADVIEWER";
#endif

void fail(char *err, const char*err2, int n);
void fail(char *err, const char*err2, int n) { }
void msg(const char *err);
void msg(const char *err) { }
void madwarn(char *err,  const char*err2);
void madwarn(char *err,  const char*err2) { }

@interface MADocument () <MADReportFormatterDataSource, MADCacheProtocol, MADDatabaseResultsProtocol,
                            MADocumentDesignerProtocol>

    @property (readwrite, nonatomic, strong) MADReportFormatter *printingReportFormatter;

    @property (nonatomic, readwrite, strong) RptqDocument *activeDocumentModel;
    @property (nonatomic, readwrite, strong) NSManagedObjectModel *madManagedObjectModel;
    @property (nonatomic, readwrite, strong) NSDictionary *madPersistentStoreOptions;

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

@synthesize sectionLayoutManagers = _sectionLayoutManagers;

#pragma mark -
#pragma mark MADPrintPageRendererDataSourceProtocol

@dynamic filename;
@dynamic refreshed;

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

- (NSArray *)groupLevelKeys:(NSUInteger)rowID {
        NSArray *groupLevelKeys;

    if (self.reportFormatter.numberOfGroups > 0) {
        
        NSDictionary *row = [self.dataTable copyDataForCacheId: rowID];
        groupLevelKeys = [self.reportFormatter newObjectArrayKeyValuesForResultRow: row];
        return groupLevelKeys;
        
    } else {
        
        groupLevelKeys = [[NSArray alloc] init];
        return groupLevelKeys;
        
    }
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [RptqDataHelper cleanup];
    _thumbnail = nil;
    _madManagedObjectModel = nil;
}

- (void)resetCache {

    NSNumber *typeKey = [[NSNumber alloc] initWithShort: MADDataTableParametersType];
    NSNumber *type = [[NSNumber alloc] initWithShort: MADDataTableTypePhysical];
    NSNumber *objectIdKey = [[NSNumber alloc] initWithShort: MADDataTableParametersIdentifier];
    NSNumber *objectIdV = [[NSNumber alloc] initWithUnsignedInteger: self.filename.hash];
    NSDictionary *parameters;
    parameters = [[NSDictionary alloc] initWithObjectsAndKeys:type, typeKey, objectIdV, objectIdKey, nil];
    
    MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:self.filename.hash];
    datatable.cacheDelegate = self;
    [datatable loadFromCacheWithUrl:self.urlDataTableCache];
    self.dataTable = datatable;

}

- (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection {
    MADDatabase *database;
    database = [MADDatabase newDatabaseWithConnection:databaseConnection];
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

- (instancetype)initWithFileURL:(NSURL *)url andDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
    if (self = [super initWithFileURL:url]) {
        
        
        _autosaveEnabled = YES;
        _urlGuts = [MADURL newURLDocumentArchiveForFileURL: url
                                                 extension: MADFileExtentionMobleApplicationDocumentArchive];
        _urlMetaPlaylist = [_urlGuts URLByAppendingPathComponent: MADFileNameMetaPlist];
        
        //Initialize the main data table.
        NSString *filename = self.filename;

        MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:filename.hash];
        datatable.cacheDelegate = self;
        
        NSString *cacheName = [datatable newFilenameMDCache];
        NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
        self.urlDataTableCache = cacheUrl;
        [datatable loadFromCacheWithUrl:cacheUrl];
        self.dataTable = datatable;
        
        //Initzlize the main document state
        id documentState = [[MADocumentState alloc] init];
        self.documentStatus = documentState;
        
        //Initzlize the extra info output container
        id extraInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
        self.extraInformation = extraInfo;
        
        if (databaseConnection != nil) {
            MADDatabase *database = [MADDatabase newDatabaseWithConnection: databaseConnection];
            self.database = database;
        }
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver: self
                          selector: @selector(handleManagedObjectContextDidChange:)
                              name: NSManagedObjectContextObjectsDidChangeNotification
                            object: self.managedObjectContext];
        
        [defaultCenter addObserver: self
                          selector: @selector(handleManagedObjectContextDidSave:)
                              name: NSManagedObjectContextDidSaveNotification
                            object: self.managedObjectContext];
        
        [defaultCenter addObserver: self
                          selector: @selector(handleManagedObjectContextWillSave:)
                              name: NSManagedObjectContextWillSaveNotification
                            object: self];
        
        [defaultCenter addObserver: self
                          selector: @selector(handleDocumentStateChanged:)
                              name: UIDocumentStateChangedNotification
                            object: self];
    }
    return self;
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
    NSURL *url = [MADURL newURLThumbnailForHandle: name
                                 andRetinaDisplay: [UIScreen mainScreen].isRetnaDisplay];
    return url;
}

- (NSURL *)urlDataTableCache {
    NSString *cacheName = [self.dataTable newFilenameMDCache];
    return [self newUrlCacheForFilename:cacheName];
}

- (NSURL *)newUrlCacheForFilename:(NSString *)filename {
    NSURL *cacheUrl = [self.cachedFilesDirectory URLByAppendingPathComponent: filename
                                                                 isDirectory: NO];
    return cacheUrl;
}

#pragma mark -
#pragma mark MADCacheProtocol

- (NSURL *)cachedFilesDirectory {
    NSString *filename = self.filename;
    NSURL *result = [MADURL newURLCacheFilesDirectoryForFilename:filename];
    return result;
}

#pragma mark -
#pragma mark UIDocument

- (NSDictionary <NSNumber *, NSNumber *> *)layoutHeightsBySectionKey {
    NSMutableDictionary *dictionary;
    dictionary = [[NSMutableDictionary alloc] initWithCapacity:self.sectionLayoutManagers.count];

    [self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock:^(NSNumber *key,
                                                                    MADSectionLayoutManager *sectionLayoutManager,
                                                                    BOOL *stop) {
        
        NSNumber *height = [[NSNumber alloc] initWithDouble:sectionLayoutManager.size.height];
        dictionary[key] = height;
        
    }];
    return dictionary;
}

- (NSDictionary *)persistentStoreOptions {
    if (_madPersistentStoreOptions == nil) {
        NSDictionary *persistentStoreOptions;
        persistentStoreOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @YES, NSInferMappingModelAutomaticallyOption,
                                      @YES, NSMigratePersistentStoresAutomaticallyOption, nil];
        _madPersistentStoreOptions = persistentStoreOptions;
    }
    return _madPersistentStoreOptions;
}

#pragma mark -
#pragma mark Reading

/// Reading MADocument has the following steps:
/// 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
/// 2. Read the unarchived file.  It's currently a Core Data file.

- (BOOL)readFromURL:(NSURL *)url error:(NSError * __autoreleasing *)outError {

    __block BOOL success = NO;

    /// 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
    if ([url.pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument]) {
        MADArchiveManager *archiveManager;
        archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: _urlGuts
                                                                archiveURL: url];
        if (!(success = [archiveManager unarchive])) {
            os_log_debug(OS_LOG_DEFAULT, "Document unarchive failed.");
        }
    }
    
    /// 2. Read the unarchived file.  It's currently a Core Data file.
    NSError *error = NULL;
    success = success ? [super readFromURL:_urlGuts error:&error] : NO;
    if (error) *outError = error;
    return success;
    
}

#pragma mark -
#pragma mark Error handling

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    [super handleError:error userInteractionPermitted:userInteractionPermitted];
    os_log_debug(OS_LOG_DEFAULT, "MADocument Error (Show UI %s): %s\n\t%s",
            userInteractionPermitted ? "YES" : "NO", error.localizedFailureReason.UTF8String,
            error.localizedDescription.UTF8String);
    NSArray *detailErrors;
    if((detailErrors = [error.userInfo objectForKey:NSDetailedErrorsKey]).count > 0) {
        for (NSError *detailError in detailErrors) {
            os_log_debug(OS_LOG_DEFAULT, "  Error: %s\n\t%s",
                    detailError.localizedFailureReason.UTF8String,
                    detailError.localizedDescription.UTF8String);
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
    
    BOOL success;
    NSError * __autoreleasing error = nil;
    if (!(success = [super writeContents: contents
                           andAttributes: additionalFileAttributes
                             safelyToURL: self.urlGuts
                        forSaveOperation: saveOperation
                                   error: &error])) {
        if (*outError != nil) {
            *outError = error.copy;
        }
        return NO;
    }

    MADArchiveManager *archiveManager;
    archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: self.urlGuts
                                                            archiveURL: self.fileURL];
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
        UIImage *image = [UIImage imageWithData: imageData];
        
        if (image != nil) {

            UIImage *extraImage = [UIImage imageWithData:imageData];
            NSString *key = [UIScreen mainScreen].isRetnaDisplay ?
                                    MADDocumentInfoKeyThumbnailRetna :
                                    MADDocumentInfoKeyThumbnailStandard;
            self.extraInformation[key] = extraImage;
            extraImage = nil;
        }
        image = nil;
    }
    
    NSDictionary *dicionary = [[NSDictionary alloc] initWithContentsOfURL:self.urlMetaPlaylist];
    NSString *infoKeyGenerator = dicionary[MADDocumentInfoKeyGenerator];
    NSString *lastGenerator = infoKeyGenerator.copy;
    NSNumber *lastVersion = ((NSNumber *)dicionary[MADDocumentInfoKeyVersion]).copy;
    
    if (lastGenerator == nil) {
        NSString *generator = @"MAD Designer";
        lastGenerator = generator;
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

- (BOOL)writeAdditionalContent: (id)content
                         toURL: (NSURL *)absoluteURL
           originalContentsURL: (NSURL *)absoluteOriginalContentsURL
                         error: (NSError * __autoreleasing *)error {
    
    BOOL writeAdditionalContent = [super writeAdditionalContent: content
                                                          toURL: absoluteURL
                                            originalContentsURL: absoluteOriginalContentsURL
                                                          error: error];

    if (content == [NSNull null] || self.documentStatus.isSuspended) {
        
        writeAdditionalContent  = NO;
        
    } else if (content != nil) {
        
        writeAdditionalContent  = YES;
        
        NSDictionary *additionalContent;
        id version = content[MADDocumentInfoKeyVersion];
        id generator = content[MADDocumentInfoKeyGenerator];
        
        additionalContent = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           version, MADDocumentInfoKeyVersion,
                                           generator, MADDocumentInfoKeyGenerator, nil];
        if (![additionalContent writeToURL:_urlMetaPlaylist atomically:NO])
            NSLog(@"Write to %@ failed", _urlMetaPlaylist);
    } else {
        
        writeAdditionalContent = NO;
        
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
    MADReportFormatter *reportFormatter;
    reportFormatter = [MADReportFormatter newReportFormatterWithLayout: self
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
        RptqDocumentSection *headerSection;
        headerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupHeader
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

        NSError * __autoreleasing error = NULL;
        if (![private save:&error]) {
            os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
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
                NSLog(@"\n\n\tDocument state closed.\n\n");
                break;
            case UIDocumentStateEditingDisabled:
                NSLog(@"\n\n\tDocument state editing disabled.\n\n");
                break;
            case UIDocumentStateInConflict:
                NSLog(@"\n\n\tDocument state in conflict.\n\n");
                break;
            case UIDocumentStateNormal:
                NSLog(@"\n\n\tDocument state normal.\n\n");
                break;
            case UIDocumentStateSavingError:
                NSLog(@"\n\n\tDocument state saving error.\n\n");
                break;
            case UIDocumentStateProgressAvailable:
                NSLog(@"Document progress: %@", notification);
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
    
    NSString *decimalString;
    decimalString = [NSNumberFormatter localizedStringFromNumber: pageNumber
                                                     numberStyle: NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
    NSString *readRecords = [[NSString alloc] initWithFormat:formatString, decimalString];
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

- (NSDictionary *)copyDataForCacheId:(NSUInteger)cachedID {
    return  [self.dataTable copyDataForCacheId:cachedID];
}

#pragma mark -
#pragma mark Helpers

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
            os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
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
        
        RptqDocument *document = nil;
        
        document = [RptqDocument newDocumentReadFromManagedObjectContext: self.managedObjectContext];
        
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
        NSMutableDictionary <NSNumber *, MADSectionLayoutManager *> *sectionLayoutManagers;
        RptqDocumentSectionEnumerator *sections;
        MADSectionLayoutManager *layoutManager;
        NSNumber *identifier;
        
        sectionLayoutManagers = [[NSMutableDictionary alloc] init];
        sections = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.activeDocumentModel];
        for (RptqDocumentSection *reportSection in sections) {
            layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
            identifier = @(reportSection.identifier);
            sectionLayoutManagers[identifier] = layoutManager;
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

        NSError * __autoreleasing error = NULL;
        if (![private save:&error]) {
            os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
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
    
    keyInQueryTable = [NSStringFromSelector(@selector(aggregateField)) stringByAppendingPeriod];
    keyInQueryTable = [keyInQueryTable stringByAppendingString:keyInQueryTableRel];
    
    NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID: deleatedTableObjectID
                                                               atKeyPath: keyInQueryTable];

    fetchReqest.predicate = predicate;
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest error:&fetchError];
    if (fetchError == nil) {
        RptqDocumentElement *documentObject; RptqDocumentSection *parentSection;
        MADSectionLayoutManager *layoutManager;
        for (documentObject in objectsToDelete) {
            parentSection = documentObject.inSectionRow.inSection;
            NSNumber *key = @(parentSection.identifier);
            layoutManager = self.sectionLayoutManagers[key];
            [RptqDocumentElement removeDocumentObject:documentObject
                                    fromParentSection:parentSection
                                    withLayoutManager:layoutManager];
            [managedObjectContext deleteObject:documentObject];
        }
    }
}

- (void)deleteDatafieldsRelatedToTable: (NSManagedObjectID *)deleatedTableObjectID
                             inContent: (NSManagedObjectContext *)managedObjectContext {
    NSString *entityName = NSStringFromClass([RptqDocumentElement class]);
    NSFetchRequest *fetchReqest;
    fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSString *keyInQueryTable = [NSStringFromSelector(@selector(referencesQueryField)) stringByAppendingPeriod];
    keyInQueryTable = [keyInQueryTable stringByAppendingString:NSStringFromSelector(@selector(inQueryTable))];
    
    NSPredicate *predicate = [NSPredicate newPredicateObjectWithObjectID: deleatedTableObjectID
                                                               atKeyPath: keyInQueryTable];
    fetchReqest.predicate = predicate;
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [managedObjectContext executeFetchRequest:fetchReqest
                                                                   error:&fetchError];
    if (fetchError == nil) {
        
        RptqDocumentSection *parentSection;
        MADSectionLayoutManager *layoutManager;
        for (RptqDocumentElement *documentObject in objectsToDelete) {
            parentSection = documentObject.inSectionRow.inSection;

            NSNumber *key = @(parentSection.identifier);
            layoutManager = self.sectionLayoutManagers[key];
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
        if (group) {
            RptqQuery *query = group.inQuery;
            
            NSArray *sections = group.hasSection.allObjects;
            NSAssert(sections.count == 2, @"Expecting a header and footer.");
            
            RptqDocumentSection *section0 = sections[0];
            RptqDocumentSection *section1 = sections[1];
            
            NSNumber *key = @(section0.identifier);
            [self.sectionLayoutManagers removeObjectForKey:key];

            key = @(section1.identifier);
            [self.sectionLayoutManagers removeObjectForKey:key];
            
            [group removeHasSectionObject: section0];
            [group removeHasSectionObject: section1];
            
            [query.managedObjectContext deleteObject: group];
            [query removeHasQueryGroupsObject: group];
            
            //Reweight Groups
            SEL weightSelector = @selector(weight);
            NSSortDescriptor *sort;
            sort = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(weightSelector)
                                                 ascending: YES];
            
            NSArray <NSSortDescriptor *> *sortDescriptors;
            sortDescriptors = [[NSArray alloc] initWithObjects: sort, nil];
            NSArray <RptqQueryGroup *> *sortedGroups;
            sortedGroups = [query.hasQueryGroups sortedArrayUsingDescriptors:sortDescriptors];
            
            int16_t counter = 0;
            for (RptqQueryGroup *sortedGroup in sortedGroups) {
                sortedGroup.weight = counter;
                counter++;
            }
            
        }
        
        NSError * __autoreleasing error = NULL;
    if (![managedObjectContext save:&error]) {
        os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
    }

    //}];
    

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
        MADReportFormatter *formatter;
        formatter = [[MADReportFormatter alloc] initWithDocument: self
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
    MADDatabaseConnection *connection;
    connection = [MADDatabaseConnection newDatabaseConnectionWithCredentals: database.ownedByUser];
    MADDatabase *db = [MADDatabase newDatabaseWithConnection:connection];
    db.delegate = self;
    self.database = db;
}

- (void)prepareForQuery {
    NSArray *sortDescriptors = [self readCurrentSortDescriptors];
    [self.dataTable sortUsingDescriptors:sortDescriptors];
}

- (void)notifyThumbnailUpdated {
    MADNotificationFileUpdate *fileUpdate = [[MADNotificationFileUpdate alloc] init];
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
