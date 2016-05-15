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

#import <Foundation/NSException.h>
#import <MADFoundation/NSURL+Document.h>
#import <MAD/MADErrorUserInfo.h>

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

#import "MTDataTableFast.h"
#import "MTDatabase.h"
#import "MTReportViewerPrintPageRenderer.h"

#import <MAD/miniz.h>

#import <MADBarcodes/png.h>
#import <setjmp.h>

typedef void (^MTCompletionHandlerSuccess)(BOOL success);

typedef struct _iodata_stream {
    unsigned int  i;
    char         *m;
} iodata_stream;

static void mad_png_read_fn(png_structp ps, png_bytep obuffer, png_size_t z) {
    png_voidp io_ptr = png_get_io_ptr(ps);
    memcpy(obuffer, (((iodata_stream *)io_ptr)->m) + (((iodata_stream*)io_ptr)->i), z);
    ((iodata_stream *)io_ptr)->i += (unsigned int)z;


    //png_voidp a = png_get_io_ptr(png_ptr);
    //memcpy(bytes, a, length);
    //a = ((uint8_t *) a) + length;
    //png_voidp io_ptr = png_get_io_ptr(png_ptr);
    //if(io_ptr == NULL)
    //    return;   // add custom error handling here
    //png_cop(png_ptr)
    //memcpy(&io_ptr, &bytes, size);
    // bytes;
    //NSData *d = [[NSData alloc] initWithBytesNoCopy: bytes length: size freeWhenDone: NO];
    //[d getBytes:&io_ptr range:NSMakeRange(0, size)];
//    io_ptr
    
    // using pulsar::InputStream
    // -> replace with your own data source interface
    //InputStream& inputStream = *(InputStream*)io_ptr;
    //const size_t bytesRead = inputStream.Read(
    //                                          (byte*)outBytes,
    //                                          (size_t)byteCountToRead);
    
    //if((png_size_t)bytesRead != byteCount)
    //    return;   // add custom error handling here
}

static void png_error_func(png_structp png_ptr, png_const_charp message) {
    
    NSLog(@"%s", message);
    
    /*
     changed 20040224
     From the libpng docs:
     "Errors handled through png_error() are fatal, meaning that png_error()
     should never return to its caller. Currently, this is handled via
     setjmp() and longjmp()"
     */
    //return;
    longjmp(png_jmpbuf(png_ptr), 1);
}

static void png_warn_func(png_structp png_ptr, png_const_charp message) {
    NSLog(@"%s", message);
}

int process_data(png_structp *png_ptr, png_infop *info_ptr,
                 png_bytep buffer, png_uint_32 length);
int process_data(png_structp *png_ptr, png_infop *info_ptr,
                 png_bytep buffer, png_uint_32 length)
{
    if (setjmp(png_jmpbuf((*png_ptr))))
    {
        /* Free the png_ptr and info_ptr memory on error */
        png_destroy_read_struct(png_ptr, info_ptr, NULL);
        return (-1);
    }
    
    /* This one's new also.  Simply give it chunks of data as
     * they arrive from the data stream (in order, of course).
     * On segmented machines, don't give it any more than 64K.
     * The library seems to run fine with sizes of 4K, although
     * you can give it much less if necessary (I assume you can
     * give it chunks of 1 byte, but I haven't tried with less
     * than 256 bytes yet).  When this function returns, you may
     * want to display any rows that were generated in the row
     * callback, if you aren't already displaying them there.
     */
//#ifdef PNG_PROGRESSIVE_READ_SUPPORTED
//    png_process_data(*png_ptr, *info_ptr, buffer, length);
//#endif
    return (0);
}

void info_callback(png_structp png_ptr, png_infop info);
void info_callback(png_structp png_ptr, png_infop info) {
    /* Do any setup here, including setting any of the transformations
     * mentioned in the Reading PNG files section.  For now, you _must_
     * call either png_start_read_image() or png_read_update_info()
     * after all the transformations are set (even if you don't set
     * any).  You may start getting rows before png_process_data()
     * returns, so this is your last chance to prepare for that.
     */
}

void row_callback(png_structp png_ptr, png_bytep new_row, png_uint_32 row_num, int pass);
void row_callback(png_structp png_ptr, png_bytep new_row, png_uint_32 row_num, int pass) {
    /*
     * This function is called for every row in the image.  If the
     * image is interlaced, and you turned on the interlace handler,
     * this function will be called for every row in every pass.
     *
     * In this function you will receive a pointer to new row data from
     * libpng called new_row that is to replace a corresponding row (of
     * the same data format) in a buffer allocated by your application.
     *
     * The new row data pointer "new_row" may be NULL, indicating there is
     * no new data to be replaced (in cases of interlace loading).
     *
     * If new_row is not NULL then you need to call
     * png_progressive_combine_row() to replace the corresponding row as
     * shown below:
     */
    
    /* Get pointer to corresponding row in our
     * PNG read buffer.
     */
    //png_bytep old_row = ((png_bytep *)our_data)[row_num];
    
#ifdef PNG_READ_INTERLACING_SUPPORTED
    /* If both rows are allocated then copy the new row
     * data to the corresponding row data.
     */
    /*if ((old_row != NULL) && (new_row != NULL))
        png_progressive_combine_row(png_ptr, old_row, new_row);*/
    
    /*
     * The rows and passes are called in order, so you don't really
     * need the row_num and pass, but I'm supplying them because it
     * may make your life easier.
     *
     * For the non-NULL rows of interlaced images, you must call
     * png_progressive_combine_row() passing in the new row and the
     * old row, as demonstrated above.  You can call this function for
     * NULL rows (it will just return) and for non-interlaced images
     * (it just does the memcpy for you) if it will make the code
     * easier.  Thus, you can just do this for all cases:
     */
    
    /*png_progressive_combine_row(png_ptr, old_row, new_row);*/
    
    /* where old_row is what was displayed for previous rows.  Note
     * that the first pass (pass == 0 really) will completely cover
     * the old row, so the rows do not have to be initialized.  After
     * the first pass (and only for interlaced images), you will have
     * to pass the current row as new_row, and the function will combine
     * the old row and the new row.
     */
#endif /* READ_INTERLACING */
}

void end_callback(png_structp png_ptr, png_infop info);
void end_callback(png_structp png_ptr, png_infop info)
{
    /* This function is called when the whole image has been read,
     * including any chunks after the image (up to and including
     * the IEND).  You will usually have the same info chunk as you
     * had in the header, although some data may have been added
     * to the comments and time fields.
     *
     * Most people won't do much here, perhaps setting a flag that
     * marks the image as finished.
     
     */
}

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

@interface MADocument ()

    @property (nonatomic, strong) MTReportFormatter *printingReportFormatter;   //Used only when printing

    @property (nonatomic, strong) NSMutableDictionary *extraInformation;        //Structure for extra info

    @property (nonatomic, copy, readwrite) NSURL *urlDataTableCache;
    @property (nonatomic, copy, readwrite) NSURL *urlGuts;
    @property (nonatomic, copy, readwrite) NSURL *urlMetaPlaylist;

    @property (nonatomic, assign) bool didRefresh;

@end

@implementation MADocument

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreOptions = _persistentStoreOptions;


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

- (void)dealloc {
    //_managedObjectModel = nil;
    //_database.delegate = nil;
    //_database = nil;
    //_mainQuery.database.delegate = nil;
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

#pragma mark - UIDocument

- (NSDictionary *)copyLayoutHeightsBySectionKey {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:self.sectionLayoutManagers.count];

    [self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *key,
                                                                    MADSectionLayoutManager *sectionLayoutManager,
                                                                    BOOL *stop) {
        
        id k = [key key];
        NSNumber *height = [[NSNumber alloc] initWithFloat:sectionLayoutManager.size.height];
        dictionary[k] = height;
        
    }];
    return dictionary;
}

- (NSDictionary *)persistentStoreOptions {
    if (_persistentStoreOptions != nil) return _persistentStoreOptions;
    
    _persistentStoreOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @YES, NSInferMappingModelAutomaticallyOption,
                                    @YES, NSMigratePersistentStoresAutomaticallyOption, nil];
    return _persistentStoreOptions;
}

- (instancetype)initWithFileURL:(NSURL *)url {
    if (self = [super initWithFileURL:url]) {
        
        NSURL *urlGuts = [MADocument newArchiveUrlForMadUrl:self.fileURL];
        NSURL *urlMetaPlaylist = [urlGuts URLByAppendingPathComponent:MADFileNameMetaPlist];
        
        _managedObjectModel = nil;
        _urlMetaPlaylist = urlMetaPlaylist.copy;
        _urlGuts = urlGuts.copy;
        
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

        self.didRefresh = false;
    }
    return self;
}

- (NSString *)filename {
    return [MADocument fileNameForMadUrl:self.fileURL];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler {
    [self regenThumbnail];
    
    NSURL *gutsUrl = self.urlGuts.copy;
    [self removeObservers];
    MADocument * __weak weakself = self;
    [super closeWithCompletionHandler:^(BOOL success) {
        if (success) {
            [MADocument RemoveGutsAtUrl:gutsUrl];
        }
    }];

    if (completionHandler != nil) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(YES);
        }];
    }
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError **)outError {

    BOOL success = NO;
    NSURL * __weak urlGuts;
    
    if ([url.pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument]) {
    
        @autoreleasepool {

            urlGuts = self.urlGuts.copy;
            
            [MADocument deleteCoreDataFilesAtDirectory: urlGuts];
            
            NSData *data = [NSData dataWithContentsOfURL:url];
            NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
            NSError * __autoreleasing *error = NULL;
            success = [fileWrapper writeToURL: urlGuts
                                      options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
                          originalContentsURL: url
                                        error: error];
            
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
                error:(NSError **)outError {
    
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

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation
                                       error:(NSError **)outError {
    
    UIImage *thumbnail = [self newFullyRenderedThumbnail];
    NSDictionary *thumbnails = [[NSDictionary alloc] initWithObjectsAndKeys:
                                thumbnail, NSThumbnail1024x1024SizeKey, nil];
    
    id fileAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         thumbnails, NSURLThumbnailDictionaryKey, nil];
    
    
    return fileAttributes;
}


- (NSString *)fileNameExtensionForType: (NSString *)typeName saveOperation: (UIDocumentSaveOperation)saveOperation {
    return MADFileExtentionMobleApplicationDocument;
}

#pragma mark UIManagedDocument

- (NSManagedObjectModel *)managedObjectModel {

    if (_managedObjectModel == nil) {
        @synchronized (_managedObjectModel) {
            NSString *modelPath = [[NSBundle mainBundle] pathForResource: MADManagedObjectModelName
                                                                  ofType: MADManagedObjectModelExtention];
            NSURL *modelURL = [[NSURL alloc] initFileURLWithPath:modelPath];
            _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        }
    }
    return _managedObjectModel;
}



/*- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *url = self.storeURL;
    if (!url) {
        return nil;
    }
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption: @(YES),
                              NSInferMappingModelAutomaticallyOption: @(YES)
                              };
    
    NSError *error;
    
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error]) {
        [NSApp presentError:error];
        
        return nil;
    }
    
    _persistentStoreCoordinator = psc;
    
    return _persistentStoreCoordinator;
}*/

/*- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)storeURL
                                           ofType:(NSString *)fileType
                               modelConfiguration:(NSString *)configuration
                                     storeOptions:(NSDictionary *)storeOptions
                                            error:(NSError * _Nullable *)error {
    
}*/

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error {

    NSError *readError = nil;

    NSData *imageData = nil;
    NSURL *thumbnailURL = [self copyThumbnailURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath: thumbnailURL.path]) {
        imageData = [NSData dataWithContentsOfURL: thumbnailURL options:NSDataReadingUncached error:&readError];
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
    
    NSDictionary *dicionary = [NSDictionary dictionaryWithContentsOfURL:self.urlMetaPlaylist];
    NSString *lastGenerator = [NSString stringWithString: dicionary[MADDocumentInfoKeyGenerator]];
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

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError **)error {

    if (self.extraInformation == nil) {
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
    }
    NSNumber *dataVersion = [[NSNumber alloc] initWithDouble:1.0];
    self.extraInformation[MADDocumentInfoKeyVersion] = dataVersion;
    self.extraInformation[MADDocumentInfoKeyGenerator] = @"MAD Designer";
    return self.extraInformation;
}

- (BOOL)writeAdditionalContent: (id)content toURL: (NSURL *)absoluteURL
           originalContentsURL: (NSURL *)absoluteOriginalContentsURL error: (NSError **)error {
    
    BOOL writeAdditionalContent = [super writeAdditionalContent:content toURL:absoluteURL originalContentsURL:absoluteOriginalContentsURL error:error];

    if (content == [NSNull null] || self.documentStatus.isSuspended) {
        
        writeAdditionalContent  = NO;
        
    } else if (content != nil) {
        
        writeAdditionalContent  = YES;
        
        NSURL *metaUrl = [self urlMetaPlaylist];
        id version = content[MADDocumentInfoKeyVersion];
        id generator = content[MADDocumentInfoKeyGenerator];
        
        NSDictionary *additionalContent = @{MADDocumentInfoKeyVersion:version, MADDocumentInfoKeyGenerator:generator};
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
        RptqDocument *rptqDocument = [RptqDocument documentForManagedObjectContext: private];
        RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
        RptqQuery *query = rptqDatabase.hasQueries.anyObject;
        
        RptqQueryTable *newQueryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable database:rptqDatabase forManagedObjectContext:private];
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

- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryFieldObjectID andSortOrder:(MNSSortOrder)sortOrder; {

    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.managedObjectContext;
    [private performBlockAndWait:^{
        
        RptqQueryField *queryField = [private objectWithID:queryFieldObjectID];
        RptqDocument *rptqDocument = [RptqDocument documentForManagedObjectContext: private];
        
        
        RptqQueryGroup *queryGroup = [RptqQueryGroup newQueryGroupQueryWithSortOrder:sortOrder andManagedObjectContext:private];
        
        queryGroup.hasField = queryField;   //Retain cycle
        
        
        //Create group header (contains a retain cycle)
        RptqDocumentSection *headerSection = [RptqDocumentSection newDocumentSectionOfType: MNSDocumentSectionTypeGroupHeader forManagedObjectContext: private];
        RptqDocumentSectionRows *headerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:private];
        headerSectionRow.inSection = headerSection;
        
        NSMutableOrderedSet *headerSectionRows = [[NSMutableOrderedSet alloc] initWithObject: headerSectionRow];
        headerSection.hasRows = headerSectionRows;
        
        [queryGroup addHasSectionObject:headerSection];
        
        //Create group footer (contains a retain cycle)
        RptqDocumentSection *footerSection = [RptqDocumentSection newDocumentSectionOfType: MNSDocumentSectionTypeGroupFooter forManagedObjectContext: private];
        RptqDocumentSectionRows *footerSectionRow = [RptqDocumentSectionRows newDocumentSectionRowsForManagedObjectContext:private];
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

        document = [RptqDocument documentForManagedObjectContext: self.managedObjectContext];
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

- (void)removeDocumentObjectWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

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

- (void)deleteAggregateFieldRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId inContent:(NSManagedObjectContext *)context {
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

- (void)deleteDatafieldsRelatedToTable:(NSManagedObjectID *)deleatedTableObjectId inContent:(NSManagedObjectContext *)context {
    
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
            NSArray *sortDescriptors = @[sortDescriptor];
            NSArray *sortedQueryGroups = [query.hasQueryGroups sortedArrayUsingDescriptors:sortDescriptors];
            NSUInteger counter = 0;
            for (RptqQueryGroup *group in sortedQueryGroups) {
                NSNumber *counterWrapper = [[NSNumber alloc] initWithUnsignedInteger:counter];
                group.weight = counterWrapper;
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
    return [[NSFileManager defaultManager] fileExistsAtPath:self.urlDataTableCache.path];
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cachedID {
    return  [self.mainDataTable dataForCacheId:cachedID];
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

- (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion {
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
        contentChanged = [self activeDocumentModel] != nil && (self.documentStatus.contextChagned) && [self.reportFormatter numberOfPages] > 0;
    }
    contentChanged = YES;
    if (contentChanged || ![[NSFileManager defaultManager] fileExistsAtPath: path]) {
        UIImage *thumbnail = [self newFullyRenderedThumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        size_t newImageSize = 0;
        
        const kPngSignatureLength = 8;
        Byte pngSignature[kPngSignatureLength];
        [pngImage getBytes:&pngSignature range:NSMakeRange(0, kPngSignatureLength)];
        bool ispng = png_check_sig(pngSignature, 8);
        
        iodata_stream dstream;
        
        png_structp p = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, png_error_func, png_warn_func);// (struct png_struct_def *)pngImage.bytes;
        png_infop info =  png_create_info_struct(p);
        
        if (info == NULL) {
            png_destroy_read_struct(&p, NULL, NULL);
        } else {
    
            dstream.i = 0;
            dstream.m = pngImage.bytes;
            png_set_read_fn(p, &dstream, mad_png_read_fn);
            png_set_sig_bytes(pngSignature, kPngSignatureLength);
        }
        png_byte numberOfChannels = png_get_channels(p, info);
        png_uint_32 imageWidth = png_get_image_width(p, info);
        png_sig_cmp(pngImage.bytes+kPngSignatureLength, (png_size_t)0, numberOfChannels*imageWidth);
        
        png_read_png(p, info, PNG_TRANSFORM_IDENTITY, NULL);
        int interlaceHandling = png_set_interlace_handling(p);
        png_uint_32 imageHeight = png_get_image_height(p, info);
        png_byte colorType = png_get_color_type(p, info);
        png_byte bitDepth = png_get_bit_depth(p, info);
        void *compressedPNG = tdefl_write_image_to_png_file_in_memory_ex(p,
                                                                         (int)imageWidth,
                                                                         (int)imageHeight,
                                                                         (int)numberOfChannels,
                                                                         &newImageSize,
                                                                         MZ_UBER_COMPRESSION, 0);
        png_destroy_read_struct(&p, (png_infopp)NULL, NULL);
        p = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, png_error_func, png_warn_func);
        const char *path = thumbnailURL.path.UTF8String;
        FILE *fp = fopen(path, "wb");
        png_init_io(p, fp);
        png_write_png(p, info, PNG_TRANSFORM_IDENTITY, compressedPNG);
        png_destroy_write_struct(&p, &info);
        free(compressedPNG);
        fclose(fp);
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
        NSError *deleteError = nil;
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
            for (NSURL *file in enumerator) {
                NSError *error = nil;
                
                [[NSFileManager defaultManager] removeItemAtURL:file error:&error];
                if (error != nil) {
                    NSAssert(error != nil, @"%s : %@",__PRETTY_FUNCTION__, error);
                    [[NSFileManager defaultManager] removeItemAtURL:file error:&error];
                }
                
            }
            
            [[NSFileManager defaultManager] removeItemAtURL:destinationUrl error:&deleteError];
            if (deleteError != nil) {
                NSAssert(deleteError != nil, @"%s : %@",__PRETTY_FUNCTION__, deleteError);
                [[NSFileManager defaultManager] removeItemAtURL:destinationUrl error:&deleteError];
            }
            
        } else {
            [[NSFileManager defaultManager] removeItemAtURL:destinationUrl error:&deleteError];
            if (deleteError != nil) {
                NSAssert(deleteError != nil, @"%s : %@",__PRETTY_FUNCTION__, deleteError);
                [[NSFileManager defaultManager] removeItemAtURL:destinationUrl error:&deleteError];
            }
        }
    }
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
    
    // retrieve the store URL
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
    NSPersistentStore *persistentStore = persistentStoreCoordinator.persistentStores.lastObject;
    NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:persistentStore];
    
    [managedObjectContext performBlockAndWait:^{
        
        [managedObjectContext reset];//to drop pending changes
        
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
        
    }];

    
    [self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

- (UIImage *)newFullyRenderedThumbnail {
    MTReportViewerPrintPageRenderer *printPageRender =
    [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: self.reportFormatter dataTable: self.mainDataTable];
    
    CGRect letterRect = [MTPaper rectLetter];
    UIImage *thumbnail = [printPageRender newThumbnailWithRect: CGRectMake(CGPointZero.x, CGPointZero.y,
                                                                           (MADFloat_1024 * letterRect.size.width) / MADFloat_1024,
                                                                           (MADFloat_1024 * letterRect.size.height) / MADFloat_1024)
                                                          size: MADFloat_1024
                                                    edgeEffect: NO
                                                    zoomEffect: NO
                                                  squareEffect: YES
                                                    cornerSize: 0.0000f
                                                         scale: 1.0000f];
    return thumbnail;
}

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
            success = [data writeToURL:fileURL options:NSDataWritingAtomic error:&errorWriting] ? true : false;
        } else {
            resultUrl = [fileURL uniqueUrl];
            NSData *data = [fileWrapper serializedRepresentation];
            success = [data writeToURL:resultUrl atomically:YES] ? true : false;
        }
    }
    
    return success;
}

#pragma mark File Name

+ (void)RemoveGutsAtUrl:(NSURL *)url {
    NSArray *propertyKeys = [[NSArray alloc] initWithObjects: NSURLIsDirectoryKey, nil];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: url
                                                             includingPropertiesForKeys: propertyKeys
                                                                                options: NSNotFound
                                                                           errorHandler: ^BOOL(NSURL *url, NSError *error) {
                                                                               return YES;
                                                                           }];
    
    NSError *error;
    for (NSURL *url in enumerator) {
        error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
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
