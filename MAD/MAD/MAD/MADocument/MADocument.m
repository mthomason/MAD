//
//  MADocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADocument.h"

#import "MADReportSections.h"

#import <CoreData/NSManagedObjectModel.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSPersistentStoreCoordinator.h>

#import <UIKit/UIScreen.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIPrintPaper.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIPrintInteractionController.h>

#import <setjmp.h>
//#import <copyfile.h>

#import <MADFoundation/UIScreen+Properties.h>
#import <MADFoundation/NSURL+CommonURLs.h>
#import <MADFoundation/MADFilename.h>

#import <MADFileManager/MADFileUtilities.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADThread.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADFoundation/NSURL+Document.h>

#import <MADBarcodes/png.h>

#import "MADDocumentProtocol.h"
#import "MADDatabaseProtocol.h"

#import "MADSortOrder.h"
#import "MADConstants.h"

#import "MADErrorUserInfo.h"

#import "MTQueryFull.h"

#import "MADConstants.h"
#import "MADCredential.h"

#import "MADActivityIndicator.h"
#import "MADocumentState.h"

#import "MTDataTable+Factory.h"

#import "MTQuery.h"
#import "MTReportFormatter.h"
#import "MTDatabaseConnection.h"

#import "MADNotificationDidFormatPage.h"

#import "RptqDocument+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows+Extras.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentSectionEnumerator.h"
#import "MADSectionLayoutManager.h"
#import "NSManagedObject+Extras.h"
#import "NSManagedObjectID+Extras.h"

#import "MTDataTableFast.h"
#import "MTDatabase.h"
#import "MTReportViewerPrintPageRenderer.h"

#import "NSString+RelativePath.h"

#import "UIImage+MADDocument.h"
#import "NSError+Document.h"
#import "UIManagedDocument+Extras.h"

#import "miniz.h"

#import "MADArchiveManager.h"

typedef void (^MTCompletionHandlerSuccess)(BOOL success);

typedef struct _iodata_stream {
    unsigned int  i;
    char         *m;
} iodata_stream;

static void mad_png_read_fn(png_structp ps, png_bytep obuffer, png_size_t z) {
    png_voidp io_ptr = png_get_io_ptr(ps);
    memcpy(obuffer, (((iodata_stream *)io_ptr)->m) + (((iodata_stream*)io_ptr)->i), z);
    ((iodata_stream *)io_ptr)->i += (unsigned int)z;
}

static void png_error_func(png_structp png_ptr, png_const_charp message) {
    //NSLog(@"PNG: %s", message);
    longjmp(png_jmpbuf(png_ptr), 1);
}

static void png_warn_func(png_structp png_ptr, png_const_charp message) {
    //NSLog(@"%s", message);
}

int process_data(png_structp *png_ptr, png_infop *info_ptr,
                 png_bytep buffer, png_uint_32 length);
int process_data(png_structp *png_ptr, png_infop *info_ptr,
                 png_bytep buffer, png_uint_32 length) {
    if (setjmp(png_jmpbuf((*png_ptr)))) {
        /* Free the png_ptr and info_ptr memory on error */
        png_destroy_read_struct(png_ptr, info_ptr, NULL);
        return (-1);
    }
    return (0);
}

void info_callback(png_structp png_ptr, png_infop info);
void info_callback(png_structp png_ptr, png_infop info) { }

void row_callback(png_structp png_ptr, png_bytep new_row, png_uint_32 row_num, int pass);
void row_callback(png_structp png_ptr, png_bytep new_row, png_uint_32 row_num, int pass) { }

void end_callback(png_structp png_ptr, png_infop info);
void end_callback(png_structp png_ptr, png_infop info) { }

typedef struct png_control {
    png_structp png_ptr;
    png_infop   info_ptr;
    png_voidp   error_buf;           /* Always a jmp_buf at present. */
    
    png_const_bytep memory;          /* Memory buffer. */
    png_size_t      size;            /* Size of the memory buffer. */
    
    unsigned int for_write       :1; /* Otherwise it is a read structure */
    unsigned int owned_file      :1; /* We own the file in io_ptr */
} png_control;

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

@interface MADocument ()
    <UIPrintInteractionControllerDelegate,
        MTReportFormatterDataSource,
        MTCacheProtocol,
        MTDatabaseProtocol>

    @property (nonatomic, readwrite, strong) MADReportSections *reportSections;

    @property (nonatomic, readwrite, strong) NSManagedObjectModel *madManagedObjectModel;
    @property (nonatomic, readwrite, strong) NSPersistentStoreCoordinator *madPersistentStoreCoordinator;
    @property (nonatomic, readwrite, strong) NSDictionary *madPersistentStoreOptions;

    @property (nonatomic, readwrite, strong) NSMutableDictionary *extraInformation;

    @property (nonatomic, readwrite, copy) NSURL *urlDataTableCache;
    @property (nonatomic, readwrite, copy) NSURL *urlGuts;
    @property (nonatomic, readwrite, copy) NSURL *urlMetaPlaylist;

    @property (nonatomic, readwrite, assign) BOOL didRefresh;

@end

@implementation MADocument

#pragma mark - NSObject

- (void)dealloc { }

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
    if (self = [super initWithFileURL:url]) {
        
        _urlGuts = [NSURL newURLDocumentArchiveForFileURL: url
                                                extension: MADFileExtentionMobleApplicationDocumentArchive];
        _urlMetaPlaylist = [_urlGuts URLByAppendingPathComponent: MADFileNameMetaPlist];
        
        //Initalize the main data table.
        NSString *filename = self.filename;
        MTDataTableFast *datatable = [[MTDataTableFast alloc] initWithId:filename.hash];
        datatable.cacheDelegate = self;
        
        NSString *cacheName = [datatable newFilenameMDCache];
        NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
        self.urlDataTableCache = cacheUrl;
        [datatable loadFromCacheWithUrl:cacheUrl];
        self.mainDataTable = datatable;
        
        //Initzlize the main document state
        id documentState = [[MADocumentState alloc] init];
        self.documentStatus = documentState;
        
        //Initzlize the extra info output container
        id extraInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
        self.extraInformation = extraInfo;
        
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
        
        _didRefresh = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Lazy Load Document Model

- (MADReportSections *)reportSections {
    if (_reportSections == nil) {
        id reportSections = [[MADReportSections alloc] initWithDocument:[self activeDocumentModel]];
        _reportSections = reportSections;
    }
    return _reportSections;
}

#pragma mark -
#pragma mark Static Helpers

+ (void)close:(MADocument *)document completion:(void (^)(BOOL success, NSURL *cleanupURL))completion  {
    
    [document regenThumbnail];
    [document removeObservers];

    NSURL *fileURL = document.fileURL.copy;
    NSURL *gutsUrl = document.urlGuts.copy;

    void (^closeCompletionHandler)(BOOL);
    closeCompletionHandler = ^(BOOL successClose) { completion(successClose, gutsUrl); };
    
    void (^ saveCompletionHandler)(BOOL);
    saveCompletionHandler = ^(BOOL success) {
        
        if (success && document != nil)
            [document closeWithCompletionHandler:closeCompletionHandler];
        
    };
    
    [document saveToURL: fileURL
       forSaveOperation: UIDocumentSaveForOverwriting
      completionHandler: saveCompletionHandler];
}

// Helpers

- (NSURL *)copyThumbnailURL {
    NSString *name = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
    NSURL *url = [NSURL newUrlThumbnailForHandle: name
                                andRetinaDisplay: [UIScreen mainScreen].isRetnaDisplay];
    return url;
}

- (NSURL *)urlDataTableCache {
    NSString *cacheName = [self.mainDataTable newFilenameMDCache];
    return [self newUrlCacheForFilename:cacheName];
}

- (NSURL *)newUrlCacheForFilename:(NSString *)filename {
    NSURL *cacheUrl = [self.cachedFilesDirectory URLByAppendingPathComponent: filename
                                                                 isDirectory: NO];
    return cacheUrl;
}

#pragma mark -
#pragma mark MTCacheProtocol

- (NSURL *)cachedFilesDirectory {
    NSString *filename = self.filename;
    NSURL *result = [NSURL newURLCacheFilesDirectoryForFilename:filename];
    return result;
}

#pragma mark -
#pragma mark UIDocument

- (NSDictionary *)copyLayoutHeightsBySectionKey {
    NSMutableDictionary *dictionary;
    dictionary = [[NSMutableDictionary alloc] initWithCapacity:self.sectionLayoutManagers.count];

    [self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *key,
                                                                    MADSectionLayoutManager *sectionLayoutManager,
                                                                    BOOL *stop) {
        
        NSNumber *height = [[NSNumber alloc] initWithFloat:sectionLayoutManager.size.height];
        dictionary[key] = height;
        
    }];
    return dictionary;
}

- (NSDictionary *)persistentStoreOptions {
    if (_madPersistentStoreOptions != nil) return _madPersistentStoreOptions;
    
    _madPersistentStoreOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @YES, NSInferMappingModelAutomaticallyOption,
                                    @YES, NSMigratePersistentStoresAutomaticallyOption, nil];
    return _madPersistentStoreOptions;
}

#pragma mark -
#pragma mark Reading

- (BOOL)readFromURL:(NSURL *)url error:(NSError * __autoreleasing *)outError {

    MADArchiveManager *archiveManager;
    BOOL success = [url.pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument];
    if (!success) goto READFROMURL_END;

    archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: _urlGuts
                                                            archiveURL: url];
    success = [archiveManager unarchive];

READFROMURL_END:;

    return success ? [super readFromURL:_urlGuts error:outError] : NO;
    
}

#pragma mark Writing

- (BOOL)writeContents:(id)contents
        andAttributes:(NSDictionary *)additionalFileAttributes
          safelyToURL:(NSURL *)url
     forSaveOperation:(UIDocumentSaveOperation)saveOperation
                error:(NSError * __autoreleasing *)outError {
    
    BOOL success = [super writeContents:contents andAttributes:additionalFileAttributes
             safelyToURL:self.urlGuts forSaveOperation:saveOperation error:outError];
    
    if (!success) return NO;
    MADArchiveManager *archiveManager;
    archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: self.urlGuts
                                                            archiveURL: self.fileURL];
    return [archiveManager archive:YES];
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    [super handleError:error userInteractionPermitted:userInteractionPermitted];
    //if (userInteractionPermitted) {
        if (error.code == 260) {
            NSError *err = [NSError newErrorFailedToOpenDocument];
            //NSLog(@"Error saving context1: %@\n%@", err.localizedDescription, err.userInfo);
            //[NSError presentError: err
            //NSLog(@"Error saving context2: %@\n%@", error.localizedDescription, error.userInfo);
            //     onViewController: nil
            //           completion: NULL];
        } else {
            //NSLog(@"Error saving context: %@\n%@", error.localizedDescription, error.userInfo);
            //[NSError presentError: error
            //     onViewController: nil
            //           completion: NULL];
        }
    //}
}

- (NSDictionary *)fileAttributesToWriteToURL: (NSURL *)url
                            forSaveOperation: (UIDocumentSaveOperation)saveOperation
                                       error: (NSError * __autoreleasing *)outError {
    
    UIImage *thumbnail = [UIImage newImageThumbnailWithDocument:self];
    NSDictionary *thumbnails = [[NSDictionary alloc] initWithObjectsAndKeys:
                                thumbnail, NSThumbnail1024x1024SizeKey, nil];
    
    id fileAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         thumbnails, NSURLThumbnailDictionaryKey, nil];
    
    
    return fileAttributes;
}


- (NSString *)fileNameExtensionForType: (NSString *)typeName
                         saveOperation: (UIDocumentSaveOperation)saveOperation {
    return MADFileExtentionMobleApplicationDocument;
}

- (void)autosaveWithCompletionHandler:(void (^ __nullable)(BOOL success))completion {
    if ([self hasUnsavedChanges]) {
        
        NSURL *url = self.fileURL.copy;
        [self saveToURL: url
       forSaveOperation: UIDocumentSaveForOverwriting
      completionHandler: completion];
        
    } else {
        completion(YES);
    }
}

#pragma mark -
#pragma mark MADocument Overrides

- (void)setDatabase:(MTDatabase *)database {
    if (_database != database) {
        _database = database;
        _database.delegate = self;
    }
}

#pragma mark Lazy Loading

- (NSManagedObjectModel *)madManagedObjectModel {
    @synchronized (self) {
        if (!_madManagedObjectModel) {
            NSURL *modelURL;
            NSManagedObjectModel *managedObjectModel;
            modelURL = [[NSBundle mainBundle] URLForResource: MADManagedObjectModelName
                                               withExtension: MADManagedObjectModelExtention];
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            _madManagedObjectModel = managedObjectModel;
        }
        
    }
    return _madManagedObjectModel;
}

#pragma mark -
#pragma mark UIManagedDocument Overrides

- (NSManagedObjectModel *)managedObjectModel {
    return self.madManagedObjectModel;
}

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL
                               error:(NSError * __autoreleasing *)error {

    NSError *readError = nil;

    NSData *imageData = nil;
    NSURL *thumbnailURL = [self copyThumbnailURL];
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

        }
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
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
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
        [additionalContent writeToURL:_urlMetaPlaylist atomically:NO];
        
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
    [self.printingReportFormatter formatForSize: controller.printPaper.paperSize
                                 contentChanged: NO];
}
- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)controller {
    self.printingReportFormatter = nil;
}

#pragma mark -
#pragma mark Query Building

- (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID {

    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.managedObjectContext;
    [private performBlockAndWait:^{

        RptqDatabaseSchemaTable *schemaTable = [private objectWithID:objectID];
        RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *query = rptqDatabase.hasQueries.anyObject;
        
        RptqQueryTable *newQueryTable = [RptqQueryTable newQueryTableForSchemaTable: schemaTable
                                                                           database: rptqDatabase
                                                            forManagedObjectContext: private];
        newQueryTable.inQuery = query;
        
        NSMutableSet *tablesInQuery = [[NSMutableSet alloc] initWithSet: query.hasQueryTables],
                     *newQueryFields = [[NSMutableSet alloc] initWithCapacity: schemaTable.hasFields.count];
        
        for (RptqDatabaseSchemaField *field in schemaTable.hasFields) {
            @autoreleasepool {
                
                RptqQueryField *newQueryField = [RptqQueryField newQueryFieldForManagedObjectContext:private];
                newQueryField.inQueryTable = newQueryTable;
                newQueryField.databaseSchemaField = field;
                [newQueryFields addObject:newQueryField];
                
            }
        }
        newQueryTable.hasQueryFields = newQueryFields;
        
        [tablesInQuery addObject:newQueryTable];
        query.hasQueryTables = tablesInQuery;
        
        NSError * __autoreleasing *error = NULL;
        [private save:error];
        
        [private refreshObject:newQueryTable mergeChanges:NO];
        
        for (RptqQueryField *field in newQueryFields) {
            [private refreshObject:field.inQueryTable           mergeChanges:NO];
            [private refreshObject:field.databaseSchemaField    mergeChanges:NO];
            [private refreshObject:field                        mergeChanges:NO];
        }

        for (RptqDatabaseSchemaField *field in schemaTable.hasFields) {
            [private refreshObject:field mergeChanges:NO];
        }

        [private refreshObject:query mergeChanges:NO];
        [private refreshObject:rptqDatabase mergeChanges:NO];
        [private refreshObject:rptqDocument mergeChanges:NO];

        [tablesInQuery removeAllObjects];
        [newQueryFields removeAllObjects];

    }];
    
}

- (void)addQueryGroupWithQueryField: (NSManagedObjectID *)queryFieldObjectID
                       andSortOrder: (MNSSortOrder)sortOrder; {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.managedObjectContext;
    [private performBlockAndWait:^{
        
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
        RptqDocumentSection *footerSection = [RptqDocumentSection newDocumentSectionOfType: MADDocumentSectionTypeGroupFooter
                                                                   forManagedObjectContext: private];
        RptqDocumentSectionRows *footerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext: private];
        footerSectionRow.inSection = footerSection;
        
        NSMutableOrderedSet *footerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: footerSectionRow];
        footerSection.hasRows = footerSectionRows;
        
        [queryGroup addHasSectionObject:footerSection];
        
        
        MADSectionLayoutManager *layoutManagerHeader = [[MADSectionLayoutManager alloc] initWithDocumentSection:headerSection];
        (self.sectionLayoutManagers)[headerSection.objectID] = layoutManagerHeader;
        
        MADSectionLayoutManager *layoutManagerFooter = [[MADSectionLayoutManager alloc] initWithDocumentSection:footerSection];
        (self.sectionLayoutManagers)[footerSection.objectID] = layoutManagerFooter;


        RptqDatabase *database = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *query = database.hasQueries.anyObject;
        [query addHasQueryGroupsObject: queryGroup];

        NSError * __autoreleasing *error = NULL;
        [private save:error];
        
        [private refreshObject:queryGroup.hasField mergeChanges:NO];
        [private refreshObject:queryGroup mergeChanges:NO];
        [private refreshObject:headerSectionRow.inSection mergeChanges:NO];
        [private refreshObject:footerSectionRow.inSection mergeChanges:NO];
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

}

#pragma mark -
#pragma mark NSManagedObjectContext Notifications

- (void)handleManagedObjectContextDidChange:(NSNotification *)notification {
    NSSet *updated = notification.userInfo[NSUpdatedObjectsKey];
    
    //NSPredicate *p = [[NSPredicate alloc] init
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
/*
    switch (self.documentState) {
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
        default:
            break;
    }
    */
}

#pragma mark - Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSDictionary *parameters = sender.userInfo;
    NSNumber *pageNumber = parameters[MTDatabaseNumberOfPagesFormattedKey];
    
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:pageNumber numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
    NSString *readRecords = [[NSString alloc] initWithFormat:formatString, decimalString];
    [self.statusLabel.status performSelectorOnMainThread: @selector(setText:)
                                              withObject: readRecords
                                           waitUntilDone: NO];
}

#pragma mark - MTDatabaseProtocol

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    MADCredential *credentials = [self.documentDelegate getCredentialsForKey:key];
    return credentials;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {

    switch (query.type) {
        
        case MADQueryTypeFull:
            self.mainDataTable.dataDelegate = self;
            return self.mainDataTable;
            break;
    
        default:
            return nil;
            break;
    }
}

#pragma mark - MTReportFormatterDataSource Protocol

- (NSEnumerator *)enumeratorForReportData {
    return [self.mainDataTable enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
    NSString *path = self.urlDataTableCache.path;
    return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

- (NSDictionary *)copyDataForCacheId:(NSNumber *)cachedID {
    return  [self.mainDataTable copyDataForCacheId:cachedID];
}

#pragma mark - Helpers

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext != nil) {
        if ((self.managedObjectContext).hasChanges && ![self.managedObjectContext save:&error]) {
            [self.managedObjectContext save:nil];
        }
    }
}

- (RptqDocument *)activeDocumentModel {

    RptqDocument *document = nil;

    if (self.documentObjectID == nil) {

        document = [RptqDocument newDocumentReadFromManagedObjectContext: self.managedObjectContext];
        if (document == nil) {
            document = [RptqDocument newDocumentForManagedObjectContext: self.managedObjectContext];
        }

        
        self.documentObjectID = document.objectID;
        
        MTPaper *paper = [[MTPaper alloc] initWithType: document.paperType];
        self.paper = paper;
        
        if (self.database == nil) {
            [self initializeMainDatabase:document];
        }
        
        if (self.reportFormatter == nil) {
            [self resetMainQueryWithDocumentModel:document];
            
            [self resetSectionLayoutManagers: document];
            
            
            [self initializeReportFormatter];
        }

    } else {
        document = (RptqDocument *)[self.managedObjectContext objectWithID:self.documentObjectID];
    }
    return document;
}

- (void)resetSectionLayoutManagers:(RptqDocument *)document {
    NSMutableDictionary *sectionLayoutManagers = [[NSMutableDictionary alloc] init];
    RptqDocumentSectionEnumerator *sections;
    sections = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];
    for (RptqDocumentSection *reportSection in sections) {
        
        MADSectionLayoutManager *layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
        sectionLayoutManagers[reportSection.objectID] = layoutManager;
    }
    
    self.sectionLayoutManagers = sectionLayoutManagers;
    
}

- (void)removeDocumentObjectWithObjectID: (NSManagedObjectID *)objectID {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.managedObjectContext;
    [private performBlockAndWait:^{

        RptqDocumentObject *documentObject = [private objectWithID:objectID];
        RptqDocumentSection *parentSection = documentObject.inSectionRow.inSection;
        MADSectionLayoutManager *layoutManager = self.sectionLayoutManagers[parentSection.objectID];
        [RptqDocumentObject removeDocumentObject:documentObject fromParentSection:parentSection withLayoutManager:layoutManager];

        NSError * __autoreleasing *error = NULL;
        [private save:error];
    }];

}

- (void)deleteAggregateFieldRelatedToTable: (NSManagedObjectID *)deleatedTableObjectId
                                 inContent: (NSManagedObjectContext *)context {
    NSString *entityName = NSStringFromClass([RptqDocumentObject class]);
    NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *documentObjectsPredicate = [NSPredicate predicateWithFormat:@"isAggregate.aggregateField.inQueryTable == %@", deleatedTableObjectId];
    fetchReqest.predicate = documentObjectsPredicate;
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [context executeFetchRequest:fetchReqest error:&fetchError];
    if (fetchError == nil) {
        for (RptqDocumentObject *documentObject in objectsToDelete) {
        
            RptqDocumentSection *parentSection = documentObject.inSectionRow.inSection;
            MADSectionLayoutManager *layoutManager = self.sectionLayoutManagers[parentSection.objectID];
            [RptqDocumentObject removeDocumentObject:documentObject fromParentSection:parentSection withLayoutManager:layoutManager];
            [RptqDocument removeDocumentObject:documentObject fromManagedObjectContext:context];
        }
    }
}

- (void)deleteDatafieldsRelatedToTable: (NSManagedObjectID *)deleatedTableObjectId
                             inContent: (NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchReqest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDocumentObject class])];
    NSPredicate *documentObjectsPredicate = [NSPredicate predicateWithFormat:@"isLabelDataField.referencesQueryField.inQueryTable == %@", deleatedTableObjectId];
    fetchReqest.predicate = documentObjectsPredicate;
    
    NSError *fetchError = nil;
    NSArray *objectsToDelete = [context executeFetchRequest:fetchReqest error:&fetchError];
    if (fetchError == nil) {
        
        for (RptqDocumentObject *documentObject in objectsToDelete) {
            RptqDocumentSection *parentSection = documentObject.inSectionRow.inSection;
            
            MADSectionLayoutManager *layoutManager = self.sectionLayoutManagers[parentSection.objectID];
            [RptqDocumentObject removeDocumentObject:documentObject fromParentSection:parentSection withLayoutManager:layoutManager];
            [RptqDocument removeDocumentObject:documentObject fromManagedObjectContext:context];
        }
    }
}

- (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID
      fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = managedObjectContext;

    void (^removeRptqGroup)(RptqQueryGroup *group);
    removeRptqGroup = ^(RptqQueryGroup *group) {

        if (group) {
            RptqQuery *query = group.inQuery;
            
            NSArray *sections = group.hasSection.allObjects;
            NSAssert(sections.count == 2, @"Expecting a header and footer.");
            
            RptqDocumentSection *section0 = sections[0];
            RptqDocumentSection *section1 = sections[1];
            
            [self.sectionLayoutManagers removeObjectForKey:section0.objectID];
            [self.sectionLayoutManagers removeObjectForKey:section1.objectID];
            
            [group removeHasSectionObject: section0];
            [group removeHasSectionObject: section1];
            
            [query.managedObjectContext deleteObject: group];
            [query removeHasQueryGroupsObject: group];
            
            //Reweight Groups
            SEL weightSelector = @selector(weight);
            NSString *key = NSStringFromSelector(weightSelector);
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: key
                                                                             ascending: YES];
            
            id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
            NSArray *sortedQueryGroups = [query.hasQueryGroups sortedArrayUsingDescriptors:sortDescriptors];
            
            NSUInteger counter = 0;
            for (RptqQueryGroup *sortedGroup in sortedQueryGroups) {
                NSNumber *counterWrapper = [[NSNumber alloc] initWithUnsignedInteger:counter];
                sortedGroup.weight = counterWrapper;
                counter++;
            }

        }
    };
    
    [private performBlockAndWait:^{
        
        RptqQueryGroup *group = [private objectWithID:groupID];
        removeRptqGroup(group);
        
        NSError * __autoreleasing * error = NULL;
        [private save:error];
    }];
    

}

- (void)resetMainQueryWithDocumentModel:(RptqDocument *)document {
    RptqDatabase *database = document.defaultDatabase;
    if (!database) return;
    
    RptqQuery *rquery = database.defaultQuery;
    MADQueryDefinition *parameters = [MTQuery newQueryDefinitionFull:rquery];
    NSMutableDictionary *extraParameters = parameters.mutableCopy;
    
    NSNumber *queryLimit;
    queryLimit = [[NSNumber alloc] initWithUnsignedInteger: self.limitResultsDesignMode ?
                                                                50 : NSUIntegerMax];
    extraParameters[@"MADQueryLimit"] = queryLimit;
    
    MTQueryFull *defaultQuery = [[MTQueryFull alloc] initWithObject:extraParameters];
    defaultQuery.dataDelegate = self;
    
    NSArray *sortDescriptors = [self readCurrentSortDescriptors];
    [self.mainDataTable sortUsingDescriptors:sortDescriptors];
    self.mainQuery = defaultQuery;
}

- (void)initializeReportFormatter {
    MTReportFormatter *reportFormatter;
    reportFormatter = [[MTReportFormatter alloc] initWithDocument: self
                                                          options: MTReportFormatterOptionsNone];
    reportFormatter.dataDelegate = self;
    reportFormatter.datasource = self;
    reportFormatter.cachedDelegate = self;

    self.reportFormatter = reportFormatter;
}

- (void)initializeMainDatabase:(RptqDocument *)document {
    RptqDatabase *database = document.defaultDatabase;
    RptqQuery *query = database.defaultQuery;
    MTDatabaseConnection *connection;
    connection = [MTDatabaseConnection newDatabaseConnectionForObject:query.inDatabase.ownedByUser];
    MTDatabase *db = [MTDatabase newDatabaseWithConnection:connection];
    db.delegate = self;
    self.database = db;
}

- (void)prepareForQuery {
    NSArray *sortDescriptors = [self readCurrentSortDescriptors];
    [self.mainDataTable sortUsingDescriptors:sortDescriptors];
}

- (void)regenThumbnail {
    NSURL *thumbnailURL = [self copyThumbnailURL];
    NSString *path = thumbnailURL.path;
    BOOL contentChanged = NO;
    if (!path) contentChanged = YES;
    if (!contentChanged) {
        contentChanged = self.activeDocumentModel != nil &&
                         (self.documentStatus.contextChagned) &&
                         (self.reportFormatter).numberOfPages > 0;
    }
    contentChanged = YES;
    if (contentChanged || ![[NSFileManager defaultManager] fileExistsAtPath: path]) {
        UIImage *thumbnail = [UIImage newImageThumbnailWithDocument:self];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        size_t newImageSize = 0;
        
        const int kPngSignatureLength = 8;
        //int BYTE_SIZE = sizeof(float);
        
        png_const_bytep pngSignature = malloc(kPngSignatureLength * BYTE_SIZE);
        [pngImage getBytes:(void *)pngSignature range:NSMakeRange(0, kPngSignatureLength)];
        
        if (!png_check_sig(pngSignature, 8)) goto RegenThumbnailShortCircuit;

        iodata_stream dstream;
        
        png_structp p = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, png_error_func, png_warn_func);
        png_infop info =  png_create_info_struct(p);
        
        if (info == NULL) {
            png_destroy_read_struct(&p, NULL, NULL);
        } else {
    
            dstream.i = 0;
            dstream.m = (char *)pngImage.bytes;
            png_set_read_fn(p, &dstream, mad_png_read_fn);
            png_set_sig_bytes((png_structp)pngSignature, kPngSignatureLength);
        }
        png_byte numberOfChannels = png_get_channels(p, info);
        png_uint_32 imageWidth = png_get_image_width(p, info);
        png_sig_cmp(pngImage.bytes+kPngSignatureLength, (png_size_t)0, numberOfChannels*imageWidth);
        
        png_read_png(p, info, PNG_TRANSFORM_IDENTITY, NULL);
        png_uint_32 imageHeight = png_get_image_height(p, info);
        void *compressedPNG = tdefl_write_image_to_png_file_in_memory_ex(p,
                                                                         (int)imageWidth,
                                                                         (int)imageHeight,
                                                                         (int)numberOfChannels,
                                                                         &newImageSize,
                                                                         MZ_UBER_COMPRESSION, 0);
        png_destroy_read_struct(&p, (png_infopp)NULL, NULL);
        p = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, png_error_func, png_warn_func);
        const char *thumbnailPath = thumbnailURL.path.UTF8String;
        FILE *fp = fopen(thumbnailPath, "wb");
        png_init_io(p, fp);
        png_write_png(p, info, PNG_TRANSFORM_IDENTITY, compressedPNG);
        png_destroy_write_struct(&p, &info);
        free(compressedPNG);
        free((void *)pngSignature);
        fclose(fp);
        RegenThumbnailShortCircuit:;
    }
}

- (NSArray *)sortDescriptors{
    return [self readCurrentSortDescriptors];
}

- (NSArray *)readCurrentSortDescriptors {
    RptqDocument *document = (RptqDocument *)[self.managedObjectContext objectWithID:self.documentObjectID];
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
    NSString *filename = self.fileURL.lastPathComponent.stringByDeletingPathExtension.copy;
    return filename;
}

#pragma mark -
#pragma mark Debugging

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendString:@"-------------------------------\n"];
    [debug appendFormat:@"Filename:\t%@\n", [self filename]];
    [debug appendFormat:@"Sections:\t%@\n", [self reportSections]];
    [debug appendString:@"-------------------------------\n"];
    return debug;
}

@end
