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

#import "MADSortOrder.h"
#import "MADConstants.h"

#import <Foundation/NSException.h>
#import <MADFoundation/NSURL+Document.h>
#import <MAD/MADErrorUserInfo.h>

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

#import "RptqDocument.h"
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

#import "RptqUserCredentals.h"
#import "RptqUserCredentals+Extras.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentSectionRows.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"

#import "RptqDocumentSectionEnumerator.h"
#import "MADSectionLayoutManager.h"

#import "NSManagedObject+Extras.h"
#import "NSManagedObjectID+Extras.h"

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADFilename.h>
#import <MADCocoaExtensions/MADThread.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADFileManager/MADFileUtilities.h>

#import "MTDataTableFast.h"
#import "MTDatabase.h"
#import "MTReportViewerPrintPageRenderer.h"

#import <MAD/miniz.h>

#import <MADBarcodes/png.h>
#import <setjmp.h>

#import <CoreData/NSManagedObjectModel.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSPersistentStoreCoordinator.h>

#import <UIKit/UIScreen.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIPrintPaper.h>
#import <UIKit/UILabel.h>

#import "png.h"

#import <archive.h>
#import <archive_entry.h>
//#include <zlib.h>
//#include <bzlib.h>

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
    NSLog(@"PNG: %s", message);
    longjmp(png_jmpbuf(png_ptr), 1);
}

static void png_warn_func(png_structp png_ptr, png_const_charp message) {
    NSLog(@"%s", message);
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

typedef void(^MTPerformAsynchronousFileAccessUsingBlock)(void);

NSString * const MADMimeType                                = @"application/vnd.everydayapps.mad";
NSString * const MADDocumentInfoKeyThumbnail                = @"thumbnail";
NSString * const MTDocumentExtentionPoratableNetworkGraphic = @"png";

static NSString * const MTDocumentAdditionalContentKey      = @"additionalContent";
static NSString * const MTDocumentFileTypeKey               = @"fileType";
static NSString * const MTDocumentParentContextKey          = @"parentContext";

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

static NSString * const MADDocumentErrorDomain                          = @"MADocument";

#if MAD_DESIGNER == 1 || MAD_TEST == 1
NSString * const MADUbiquitousPeerToken = @"MADDESIGNER";
#elif MAD_VIEWER == 1
NSString * const MADUbiquitousPeerToken = "MADVIEWER";
#endif


void write_archive(const char *outname, const char **filename);
void write_archive(const char *outname, const char **filename) {
    struct archive *a;
    struct archive_entry *entry;
    struct stat st;
    char buff[8192];
    ssize_t len;
    int fd;
    
    a = archive_write_new();
    archive_write_add_filter_bzip2(a);
    archive_write_set_format_pax_restricted(a); // Note 1
    archive_write_open_filename(a, outname);
    while (*filename) {
        stat(*filename, &st);
        entry = archive_entry_new(); // Note 2
        archive_entry_set_pathname(entry, *filename);
        archive_entry_set_size(entry, st.st_size); // Note 3
        archive_entry_set_filetype(entry, AE_IFREG);
        archive_entry_set_perm(entry, 0644);
        archive_write_header(a, entry);
        fd = open(*filename, O_RDONLY);
        len = read(fd, buff, sizeof(buff));
        while ( len > 0 ) {
            archive_write_data(a, buff, (size_t)len);
            len = read(fd, buff, sizeof(buff));
        }
        close(fd);
        archive_entry_free(entry);
        filename++;
    }
    archive_write_close(a); // Note 4
    archive_write_free(a); // Note 5
}

//int main(int argc, const char **argv)
//{
//    const char *outname;
//    argv++;
//    outname = argv++;
//    write_archive(outname, argv);
//    return 0;
//}

@interface MADocument ()

    @property (nonatomic, strong, readwrite) NSManagedObjectModel *madManagedObjectModel;
    @property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *madPersistentStoreCoordinator;
    @property (nonatomic, strong, readwrite) NSDictionary *madPersistentStoreOptions;

    @property (nonatomic, strong) MTReportFormatter *printingReportFormatter;   //Used only when printing

    @property (nonatomic, strong) NSMutableDictionary *extraInformation;        //Structure for extra info

    @property (nonatomic, copy, readwrite) NSURL *urlDataTableCache;
    @property (nonatomic, copy, readwrite) NSURL *urlGuts;
    @property (nonatomic, copy, readwrite) NSURL *urlMetaPlaylist;

    @property (nonatomic, assign) bool didRefresh;

@end

@implementation MADocument

//@synthesize managedObjectModel = _managedObjectModel;
//@synthesize persistentStoreOptions = _persistentStoreOptions;

+ (bool)wrapFileOverwrite:(BOOL)overwrite urlGuts:(NSURL *)urlGuts fileURL:(NSURL *)fileURL {
    NSError *fileWrapperError = nil;
    bool success = false;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: urlGuts
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    NSURL *resultUrl;
    
    if (fileWrapperError == nil) {
        if (overwrite) {
            NSData *data = [fileWrapper serializedRepresentation];
            NSError *errorWriting = nil;
            success = [data writeToURL: fileURL
                               options: (NSDataWritingOptions)
                       (NSDataWritingAtomic |
                        NSFileWrapperWritingWithNameUpdating)
                                 error: &errorWriting] ? true : false;
        } else {
            resultUrl = [fileURL uniqueUrl];
            NSData *data = [fileWrapper serializedRepresentation];
            success = [data writeToURL:resultUrl atomically:YES] ? true : false;
        }
    }
    
    return success;
}

+ (instancetype)newManagedDocumentForURL:(NSURL *)url {
    id document = [[self alloc] initWithFileURL:url];
    return document;
}

+ (BOOL)isRetnaDisplay {
    return [[UIScreen mainScreen] scale] > 1.5;
}

+ (NSURL *)newArchiveUrlForMadUrl:(NSURL *)madUrl {
    NSString *name = madUrl.lastPathComponent.stringByDeletingPathExtension.copy;
    NSString *destinationName = [name stringByAppendingPathExtension:MADFileExtentionMobleApplicationDocumentArchive];
    NSURL *destinationDirectoryUrl = [MADFileUtilities localTemporaryDirectory];
    id url = [destinationDirectoryUrl URLByAppendingPathComponent: destinationName
                                                      isDirectory: YES];
    return url;
}

+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename {
    NSString *filenameId = [MADFilename newFilenameId:filename.hash];
    return [MADFileUtilities newUrlForLocalCacheDirectoryNamed:filenameId];
}

+ (NSURL *)newThumbnailUrlForMadUrl:(NSURL *)madUrl {
    NSString *handle = madUrl.lastPathComponent.stringByDeletingPathExtension.copy;
    return [self newUrlThumbnailForHandle: handle andRetinaDisplay: [self isRetnaDisplay]];
    
}

+ (NSURL *)newUrlThumbnailForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
    NSString *name = [self isRetnaDisplay] ? [handle stringByAppendingString:@"@2x"] : handle;
    NSString *filename = [name stringByAppendingPathExtension:MTDocumentExtentionPoratableNetworkGraphic];
    NSString *fileNameId = [MADFilename newFilenameId:handle.hash];
    NSURL *cacheDirectory = [MADFileUtilities newUrlForLocalCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (NSURL *)copyThumbnailURL {
    NSString *name = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
    NSURL *url = [MADocument newUrlThumbnailForHandle: name
                                     andRetinaDisplay: [MADocument isRetnaDisplay]];
    return url;
}

- (NSURL *)urlDataTableCache {
    NSString *cacheName = [self.mainDataTable newFilenameMDCache];
    return [self newUrlCacheForFilename:cacheName];
}
- (NSURL *)cachedFilesDirectory {
    NSString *filename = [self filename];
    return [MADocument cacheFilesDirectoryForFilename:filename];
}

- (NSURL *)newUrlCacheForFilename:(NSString *)filename {
    NSURL *cacheUrl = [self.cachedFilesDirectory URLByAppendingPathComponent: filename
                                                                 isDirectory: NO];
    return cacheUrl;
}

#pragma mark - Property Overrides

- (void)setDatabase:(MTDatabase *)database {
    if (_database != database) {
        _database = database;
        _database.delegate = self;
    }
}

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

#pragma mark - UIDocument

- (NSDictionary *)copyLayoutHeightsBySectionKey {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:self.sectionLayoutManagers.count];

    [self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *key,
                                                                    MADSectionLayoutManager *sectionLayoutManager,
                                                                    BOOL *stop) {
        
        id k = [key copyKey];
        NSNumber *height = [[NSNumber alloc] initWithFloat:sectionLayoutManager.size.height];
        dictionary[k] = height;
        
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

- (instancetype)initWithFileURL:(NSURL *)url {
    if (self = [super initWithFileURL:url]) {
        
        _urlGuts = [MADocument newArchiveUrlForMadUrl: url];
        _urlMetaPlaylist = [_urlGuts URLByAppendingPathComponent: MADFileNameMetaPlist];
        
        
        [self initalizeMainDataTable];
        
        id documentState = [[MADocumentState alloc] init];
        self.documentStatus = documentState;
        
        id extraInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
        self.extraInformation = extraInfo;
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver: self
                          selector: @selector(managedObjectContextDidChange:)
                              name: NSManagedObjectContextObjectsDidChangeNotification
                            object: self.managedObjectContext];
        
        [defaultCenter addObserver: self
                          selector: @selector(managedObjectContextDidSave:)
                              name: NSManagedObjectContextDidSaveNotification
                            object: self.managedObjectContext];

        [defaultCenter addObserver: self
                          selector: @selector(managedObjectContextWillSave:)
                              name: NSManagedObjectContextWillSaveNotification
                            object: self];

        [defaultCenter addObserver: self
                          selector: @selector(documentStateChanged:)
                              name: UIDocumentStateChangedNotification
                            object: self];

        _didRefresh = false;
    }
    return self;
}

- (NSString *)filename {
    return [MADocument fileNameForMadUrl:self.fileURL];
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError * __autoreleasing *)outError {

    bool success = false;
    NSURL *urlGuts;
    urlGuts = self.urlGuts.copy;
    
    NSString *pathExtension = url.pathExtension;
    if ([pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument]) {
    
        @autoreleasepool {

            
            [MADocument deleteCoreDataFilesAtDirectory: urlGuts];

            NSError * __autoreleasing *errorReading = NULL;
            NSData *data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingUncached
                                                           error:errorReading];
            NSFileWrapper *fileWrapper;
            fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
            NSError * __autoreleasing *error = NULL;
            success = [fileWrapper writeToURL: urlGuts
                                      options: NSFileWrapperWritingWithNameUpdating
                          originalContentsURL: url
                                        error: error] ? true : false;
            NSAssert(success, @"Failed to write at %s.", __PRETTY_FUNCTION__);
            
        }
    }
    
    if (success) {
        return [super readFromURL:urlGuts error:outError];
    }
    
    return NO;
}

- (BOOL)writeContents:(id)contents andAttributes:(NSDictionary *)additionalFileAttributes
          safelyToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation
                error:(NSError * __autoreleasing *)outError {
    
    BOOL success = [super writeContents:contents andAttributes:additionalFileAttributes
             safelyToURL:self.urlGuts forSaveOperation:saveOperation error:outError];
    
    if (!success) return NO;

    return [MADocument wrapFileOverwrite: YES
                                 urlGuts: self.urlGuts
                                 fileURL: self.fileURL] ? YES : NO;
    
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    [super handleError:error userInteractionPermitted:userInteractionPermitted];
    //if (userInteractionPermitted) {
        if (error.code == 260) {
            NSError *err = [MADocument errorFailedToOpenDocument];
            NSLog(@"Error saving context1: %@\n%@", [err localizedDescription], [err userInfo]);
            //[NSError presentError: err
            NSLog(@"Error saving context2: %@\n%@", [error localizedDescription], [error userInfo]);
            //     onViewController: nil
            //           completion: NULL];
        } else {
            NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
            //[NSError presentError: error
            //     onViewController: nil
            //           completion: NULL];
        }
    //}
}

- (NSDictionary *)fileAttributesToWriteToURL: (NSURL *)url
                            forSaveOperation: (UIDocumentSaveOperation)saveOperation
                                       error: (NSError * __autoreleasing *)outError {
    
    UIImage *thumbnail = [self newFullyRenderedThumbnail];
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

#pragma mark UIManagedDocument

- (NSManagedObjectModel *)madManagedObjectModel {
    @synchronized (self) {
        if (!_madManagedObjectModel) {
            NSURL *modelURL = [[NSBundle mainBundle] URLForResource: MADManagedObjectModelName
                                                      withExtension: MADManagedObjectModelExtention];
            NSManagedObjectModel *managedObjectModel;
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            _madManagedObjectModel = managedObjectModel;
        }
        
    }
    return _madManagedObjectModel;
}

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
            imageData = [NSData dataWithContentsOfURL: thumbnailURL options: NSDataReadingUncached
                                                error: &readError];
        }
    }
    
    if (imageData != nil) {
        UIImage *image = [UIImage imageWithData: imageData];
        
        if (image != nil) {

            UIImage *extraImage = [UIImage imageWithData:imageData];
            NSString *key = [MADocument isRetnaDisplay] ?
                                    MADDocumentInfoKeyThumbnailRetna :
                                    MADDocumentInfoKeyThumbnailStandard;
            self.extraInformation[key] = extraImage;

        }
    }
    
    NSDictionary *dicionary = [[NSDictionary alloc] initWithContentsOfURL:self.urlMetaPlaylist];
    NSString * __weak infoKeyGenerator = dicionary[MADDocumentInfoKeyGenerator];
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
        [self setExtraInformation:extraInfo];
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
    
    BOOL writeAdditionalContent = [super writeAdditionalContent: content toURL: absoluteURL
                                            originalContentsURL: absoluteOriginalContentsURL
                                                          error: error];

    if (content == [NSNull null] || self.documentStatus.isSuspended) {
        
        writeAdditionalContent  = NO;
        
    } else if (content != nil) {
        
        writeAdditionalContent  = YES;
        
        NSURL *metaUrl = [self urlMetaPlaylist];
        id version = content[MADDocumentInfoKeyVersion];
        id generator = content[MADDocumentInfoKeyGenerator];
        
        NSDictionary *additionalContent = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           version, MADDocumentInfoKeyVersion,
                                           generator, MADDocumentInfoKeyGenerator, nil];
        [additionalContent writeToURL:metaUrl atomically:NO];
        
    } else {
        
        writeAdditionalContent = NO;
        
    }
    return writeAdditionalContent;
}

+ (NSString *)persistentStoreName { return MADPersistentStoreAliasMad; }

#pragma mark - Reporting Functions
#pragma mark Query Building

- (void)addQuerySelectTableForSchemeTableWithObjectID:(NSManagedObjectID *)objectID {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
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
        
        NSMutableSet *tablesInQuery = [[NSMutableSet alloc] initWithSet: query.hasQueryTables];
        NSMutableSet *newQueryFields = [[NSMutableSet alloc] initWithCapacity: schemaTable.hasFields.count];
        
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
        RptqDocumentSection *headerSection = [RptqDocumentSection newDocumentSectionOfType: MNSDocumentSectionTypeGroupHeader
                                                                   forManagedObjectContext: private];
        RptqDocumentSectionRows *headerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:private];
        headerSectionRow.inSection = headerSection;
        
        NSMutableOrderedSet *headerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: headerSectionRow];
        headerSection.hasRows = headerSectionRows;
        
        [queryGroup addHasSectionObject:headerSection];
        
        //Create group footer (contains a retain cycle)
        RptqDocumentSection *footerSection = [RptqDocumentSection newDocumentSectionOfType: MNSDocumentSectionTypeGroupFooter
                                                                   forManagedObjectContext: private];
        RptqDocumentSectionRows *footerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext: private];
        footerSectionRow.inSection = footerSection;
        
        NSMutableOrderedSet *footerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: footerSectionRow];
        footerSection.hasRows = footerSectionRows;
        
        [queryGroup addHasSectionObject:footerSection];
        
        
        MADSectionLayoutManager *layoutManagerHeader = [[MADSectionLayoutManager alloc] initWithDocumentSection:headerSection];
        [self.sectionLayoutManagers setObject: layoutManagerHeader forKey: headerSection.objectID];
        
        MADSectionLayoutManager *layoutManagerFooter = [[MADSectionLayoutManager alloc] initWithDocumentSection:footerSection];
        [self.sectionLayoutManagers setObject: layoutManagerFooter forKey: footerSection.objectID];


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


#pragma mark - UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController { }

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)printInteractionController {
    self.printingReportFormatter.dataDelegate = self;
    self.printingReportFormatter.layoutSize = printInteractionController.printPaper.paperSize;
    self.printingReportFormatter.marginUsingPrintableRect = printInteractionController.printPaper.printableRect;
    self.printingReportFormatter.didRefresh = true;
    [self.printingReportFormatter formatForSize: printInteractionController.printPaper.paperSize contentChanged: NO];
}
- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)printInteractionController {
    self.printingReportFormatter = nil;
}

#pragma mark - NSManagedObjectContext Notifications
#pragma mark NSManagedObjectContextObjectsDidChangeNotification

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSSet *updated = notification.userInfo[NSUpdatedObjectsKey];
    
    //NSPredicate *p = [[NSPredicate alloc] init
    self.documentStatus.needsSave = YES;
    self.documentStatus.contextChagned = YES;
}

#pragma mark NSManagedObjectContextDidSaveNotification

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    self.documentStatus.saveInProgress = NO;
    self.documentStatus.needsSave = NO;
}

#pragma mark NSManagedObjectContextWillSaveNotification

- (void)managedObjectContextWillSave:(NSNotification *)notification {
    self.documentStatus.saveInProgress = YES;
}

#pragma mark - UIDocument Notifications
#pragma mark UIDocumentStateChangedNotification

- (void)documentStateChanged:(NSNotification *)notification {
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

#pragma mark - MTDatabaseProtocol

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    MADCredential *credentials = [self.documentDelegate getCredentialsForKey:key];
    return credentials;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {

    switch (query.type) {
        
        case MTQueryTypeFull:
            self.mainDataTable.dataDelegate = self;
            return self.mainDataTable;
            break;
    
        default:
            return nil;
            break;
    }
}

#pragma mark - Helpers

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext != nil) {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
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
            [self initalizeMainDatabase:document];
        }
        
        if (self.reportFormatter == nil) {
            [self initalizeMainQuery:document];
            [self initalizeSectionLayoutManagers:document];
            [self initalizeReportFormatter];
        }

    } else {
        document = (RptqDocument *)[self.managedObjectContext objectWithID:self.documentObjectID];
    }
    return document;
}

- (void)initalizeSectionLayoutManagers:(RptqDocument *)document {
    NSMutableDictionary *sectionLayoutManagers = [NSMutableDictionary new];
    RptqDocumentSectionEnumerator *sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        MADSectionLayoutManager *layoutManager = [[MADSectionLayoutManager alloc] initWithDocumentSection:reportSection];
        [sectionLayoutManagers setObject:layoutManager forKey:reportSection.objectID];
    }
    
    self.sectionLayoutManagers = sectionLayoutManagers;
    
}

- (void)removeDocumentObjectWithObjectID: (NSManagedObjectID *)objectID
                    managedObjectContext: (NSManagedObjectContext *)managedObjectContext {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = managedObjectContext;
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
    [fetchReqest setPredicate:documentObjectsPredicate];
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

- (void)removeGroupWitObjectID:(NSManagedObjectID *)groupID fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

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
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(weight)) ascending:YES];
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

- (void)initalizeMainQuery:(RptqDocument *)document {
    RptqDatabase *database = [document defaultDatabase];
    if (database) {
    
        RptqQuery *rquery = [database defaultQuery];
        MADQueryDefinition *parameters = [MTQuery newQueryDefinitionFull:rquery];
        NSMutableDictionary *extraParameters = parameters.mutableCopy;

        NSNumber *queryLimit = [[NSNumber alloc] initWithInteger: self.limitResultsDesignMode ? 50 : NSNotFound];
        extraParameters[@"MADQueryLimit"] = queryLimit;
        
        MTQueryFull *defaultQuery = [[MTQueryFull alloc] initWithObject:extraParameters];
        defaultQuery.dataDelegate = self;
        
        NSArray *sortDescriptors = [self readCurrentSortDescriptors];
        [self.mainDataTable sortUsingDescriptors:sortDescriptors];
        [self setMainQuery:defaultQuery];
    }
}

- (void)initalizeMainDataTable {

    NSString *filename = self.filename;
    MTDataTableFast *datatable = [[MTDataTableFast alloc] initWithId:filename.hash];
    datatable.cacheDelegate = self;

    NSString *cacheName = [datatable newFilenameMDCache];
    NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
    self.urlDataTableCache = cacheUrl;
    [datatable loadFromCacheWithUrl:cacheUrl];
    self.mainDataTable = datatable;
}

- (void)initalizeReportFormatter {
    MTReportFormatter *reportFormatter = [[MTReportFormatter alloc] initWithDocument: self
                                                                             options: MTReportFormatterOptionsNone];
    reportFormatter.dataDelegate = self;
    reportFormatter.datasource = self;
    reportFormatter.cachedDelegate = self;
    [reportFormatter initalize];

    self.reportFormatter = reportFormatter;
}

- (void)initalizeMainDatabase:(RptqDocument *)document {
    RptqDatabase *database = [document defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForObject:query.inDatabase.ownedByUser];
    MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
    db.delegate = self;
    self.database = db;
}

- (void)prepareForQuery {
    NSArray *sortDescriptors = [self readCurrentSortDescriptors];
    [self.mainDataTable sortUsingDescriptors:sortDescriptors];
}

#pragma mark - MTReportFormatterDataSource

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

#pragma mark - Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSDictionary *parameters = [sender userInfo];
    NSNumber *pageNumber = parameters[MTDatabaseNumberOfPagesFormattedKey];
    
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:pageNumber numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
    NSString *readRecords = [[NSString alloc] initWithFormat:formatString, decimalString];
    [self.statusLabel.status performSelectorOnMainThread: @selector(setText:)
                                              withObject: readRecords
                                           waitUntilDone: NO];
}

+ (void)close:(MADocument *)document completion:(void (^)(BOOL success))completion  {

    [document regenThumbnail];
    [document removeObservers];
    NSURL *gutsUrl = document.urlGuts.copy;

    [document closeWithCompletionHandler:^(BOOL success) {
        [self RemoveGutsAtUrl:gutsUrl];
        completion(YES);
    }];
}

+ (void)closeAndDelete:(MADocument *)document completion:(void (^)(BOOL success))completion  {
    [self close:document completion:^(BOOL success) {
        [self DeletePersistentStoreForManagedObjectContext:document.managedObjectContext];
        [self DeleteDocument:document fromDiskCompletion:^(BOOL successDelete) {
            completion(YES);
        }];
    }];
}

- (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion {
    NSURL *gutsUrl = self.urlGuts.copy;
    [self removeObservers];
    MADocument * __weak weakself = self;
    [MADocument RemoveGutsAtUrl:gutsUrl];
    
    [self closeWithCompletionHandler:^(BOOL successClosingReport) {
        if (successClosingReport) {
            [self deleteFromDiskCompletion:^(BOOL successDeletingFromDisk) { }];
            NSError *error = [MADocument errorConnectionProblem];
            [MADThread completeOnMainThread:completion withObject:error andSuccess:NO];
        }
    }];
}

+ (NSError *)errorConnectionProblem {
    NSString *title = NSLocalizedString(@"Connection Problem", @"Connection Problem");
    NSString *message = NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.");
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
    return [errorUserInfo errorWithDomain: MADDocumentErrorDomain code: 36732];
}

+ (NSError *)errorFailedToOpenDocument {
    NSString *title = NSLocalizedString(@"Failed to open document.", @"Failed to open document.");
    NSString *message = NSLocalizedString(@"Document may be incomplete, missing, or corrupt.", @"Document may be incomplete, missing, or corrupt.");
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
    return [errorUserInfo errorWithDomain: MADDocumentErrorDomain code: 260];
}

typedef struct png_control
{
    png_structp png_ptr;
    png_infop   info_ptr;
    png_voidp   error_buf;           /* Always a jmp_buf at present. */
    
    png_const_bytep memory;          /* Memory buffer. */
    png_size_t      size;            /* Size of the memory buffer. */
    
    unsigned int for_write       :1; /* Otherwise it is a read structure */
    unsigned int owned_file      :1; /* We own the file in io_ptr */
} png_control;

- (void)regenThumbnail {
    NSURL *thumbnailURL = [self copyThumbnailURL];
    NSString *path = thumbnailURL.path;
    BOOL contentChanged = NO;
    if (!path) contentChanged = YES;
    if (!contentChanged) {
        contentChanged = [self activeDocumentModel] != nil &&
                         (self.documentStatus.contextChagned) &&
                         [self.reportFormatter numberOfPages] > 0;
    }
    contentChanged = YES;
    if (contentChanged || ![[NSFileManager defaultManager] fileExistsAtPath: path]) {
        UIImage *thumbnail = [self newFullyRenderedThumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        size_t newImageSize = 0;
        
        const int kPngSignatureLength = 8;

        
        png_const_bytep pngSignature = malloc(kPngSignatureLength * sizeof(Byte));
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
        [self initalizeMainDatabase:document];        // FIXME: I doubt this ever runs.
    }
    return [document.defaultDatabase.defaultQuery sortDescriptorsForDatabase:self.database];
}

- (MTReportViewerPrintPageRenderer *)newPrinterPrintPageRender {
    MTReportFormatter *reportFormatter = [MTReportFormatter newReportFormatterWithLayout: self
                                                                                 options: MTReportFormatterOptionsMargin];
    reportFormatter.overrideIdentifier = @"madprinter";
    reportFormatter.dataDelegate = self;
    reportFormatter.datasource = self;
    reportFormatter.cachedDelegate = self;
    [reportFormatter initalize];
    
    id printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: reportFormatter
                                                                                dataTable: self.mainDataTable];
    self.printingReportFormatter = reportFormatter;
    return printPageRender;
    
}

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl {
    BOOL isDirectory;
    
    NSString *destinationPath = destinationUrl.path.copy;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: destinationPath
                                                       isDirectory: &isDirectory];
    if (exists) {
        if (isDirectory) {
            
            BOOL(^ErrorHandler)(NSURL *, NSError *) = ^BOOL(NSURL *url, NSError *error) {
                NSAssert(error != nil, @"%s : %@",__PRETTY_FUNCTION__, error);
                return YES;
            };
            
            NSArray *requestedKeys = [[NSArray alloc] initWithObjects:NSURLIsDirectoryKey, nil];
            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: destinationUrl
                                                                     includingPropertiesForKeys: requestedKeys
                                                                                        options: NSDirectoryEnumerationSkipsPackageDescendants
                                                                                   errorHandler: ErrorHandler];

            dispatch_queue_t queueHigh = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            
            for (NSURL *fileURL in enumerator) {
                NSURL *file = fileURL.copy;
                dispatch_group_async(group, queueHigh, ^{
                    //@autoreleasepool {
                        [MADocument removeItemAtURL:file];
                    //}
                });
            }
            
            NSURL *file = destinationUrl.copy;
            dispatch_group_async(group, queueHigh, ^{
                //@autoreleasepool {
                    [MADocument removeItemAtURL:file];
                //}
            });
            dispatch_group_leave(group);
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            
        }
    }
}

+ (void)removeItemAtURL:(NSURL *)url {
    NSError * __autoreleasing *deleteError = NULL;
    [[NSFileManager defaultManager] removeItemAtURL:url error:deleteError];
    if (deleteError != nil) {
        NSAssert(*deleteError != nil, @"%s : %@",__PRETTY_FUNCTION__, *deleteError);
        *deleteError = NULL;
        [[NSFileManager defaultManager] removeItemAtURL:url error:deleteError];
    }
}

- (NSURL *)copyPersistentStoreURL {
    NSPersistentStoreCoordinator *persistentStoreCoordinator =
        self.managedObjectContext.persistentStoreCoordinator;
    NSPersistentStore *persistentStore = persistentStoreCoordinator.persistentStores.lastObject;
    NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:persistentStore];
    return storeURL.copy;
}

+ (void)DeletePersistentStoreForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSPersistentStoreCoordinator *persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator;
    NSPersistentStore *persistentStore = persistentStoreCoordinator.persistentStores.lastObject;
    NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:persistentStore];
    
    [managedObjectContext performBlockAndWait:^{
        [managedObjectContext reset];//to drop pending changes
    }];
    NSError *error = nil;
    
    //delete the store from the current managedObjectContext
    BOOL success = [persistentStoreCoordinator removePersistentStore: persistentStore
                                                               error: &error];
    if (success) {
        
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        
        NSNumber *o1 = @YES;
        NSNumber *o2 = @YES;
        id options = [[NSDictionary alloc] initWithObjectsAndKeys:
                      o1, NSMigratePersistentStoresAutomaticallyOption,
                      o2, NSInferMappingModelAutomaticallyOption, nil];
        
        [persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
                                                 configuration: nil
                                                           URL: storeURL
                                                       options: options
                                                         error: &error];
    }

}

+ (void)DeleteDocument:(MADocument *)document fromDiskCompletion:(void (^)(BOOL success))completion {
    
    NSURL *fileURL = document.fileURL;
    MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {

        NSError *deleteError = nil;
        
        NSArray *properties = [[NSArray alloc] initWithObjects:NSURLIsDirectoryKey, nil];
        
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: document.fileURL
                                                                 includingPropertiesForKeys: properties
                                                                                    options: NSDirectoryEnumerationSkipsHiddenFiles
                                                                               errorHandler: ^BOOL(NSURL *url, NSError *error) {
                                                                                   return YES;
                                                                               }];
        for (NSURL *file in enumerator) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:file error:&error];
        }
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&deleteError];
        NSAssert(deleteError == nil, @"%@", deleteError);
        completion(YES);
    };
    
    
    [document performAsynchronousFileAccessUsingBlock:asyncBlock];
}


- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion {
    
    MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
        NSURL *fileURL = self.fileURL;
        NSError *deleteError = nil;

        NSArray *properties = [[NSArray alloc] initWithObjects:NSURLIsDirectoryKey, nil];
        
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: fileURL
                                                                 includingPropertiesForKeys: properties
                                                                                    options: NSDirectoryEnumerationSkipsHiddenFiles
                                                                               errorHandler: ^BOOL(NSURL *url, NSError *error) {
            return YES;
        }];
        for (NSURL *file in enumerator) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:file error:&error];
        }
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&deleteError];
        NSAssert(deleteError == nil, @"%@", deleteError);
        completion(YES);
    };
    
    NSAssert(self.documentState == UIDocumentStateClosed, @"Document must be closed to call this!");
    [MADocument DeletePersistentStoreForManagedObjectContext:self.managedObjectContext];

    
    [self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

- (UIImage *)newFullyRenderedThumbnail {
    MTReportViewerPrintPageRenderer *printPageRender =
    [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: self.reportFormatter dataTable: self.mainDataTable];
    
    CGRect letterRect = [MTPaper rectLetter];
    UIImage *thumbnail = [printPageRender newThumbnailWithRect: MADRectOfSize(CGSizeMake(
                                                                           (MADFloat_1024 * letterRect.size.width) / MADFloat_1024,
                                                                           (MADFloat_1024 * letterRect.size.height) / MADFloat_1024))
                                                          size: MADFloat_1024
                                                    edgeEffect: NO
                                                    zoomEffect: NO
                                                  squareEffect: YES
                                                    cornerSize: 0.0000f
                                                         scale: 1.0000f];
    return thumbnail;
}

#pragma mark File Name

+ (void)RemoveGutsAtUrl:(NSURL *)url {
    NSArray *propertyKeys = [[NSArray alloc] initWithObjects: NSURLIsDirectoryKey, nil];
    NSDirectoryEnumerator *enumerator;
    enumerator = [[NSFileManager defaultManager] enumeratorAtURL: url
                                      includingPropertiesForKeys: propertyKeys options: NSNotFound
                                                    errorHandler: ^BOOL(NSURL *errorUrl,
                                                                        NSError *error) {
        return YES;
    }];
    
    NSError *error;
    for (NSURL *fileURL in enumerator) {
        error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
    }
    
    error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    
}

- (void)removeGuts {
    [MADocument RemoveGutsAtUrl:self.urlGuts];
    
}

+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl { return madUrl.lastPathComponent.stringByDeletingPathExtension; }

- (NSString *)mimetype { return MADMimeType; }

@end
