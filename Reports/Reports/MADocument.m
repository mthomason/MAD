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

typedef void (^MTCompletionHandlerSuccess)(BOOL success);

#import "MADocument.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTLog.h"
#import "MTPaper.h"

#import "UIManagedDocument+FileOperations.h"
#import "UIColor+EverydayApps.h"
#import "UIColor+Gradients.h"
#import "NSURL+Document.h"
#import "UIDevice+Hack.h"
#import "NSError+UserInterface.h"
#import "NSError+Constructors.h"
#import "NSFileManager+Common.h"
#import "NSFileManager+Reports.h"
#import "NSThread+Extras.h"

#import "MADocumentState.h"

#import "MACloudManager.h"

#import "MTQuery.h"
#import "MTReportFormatter.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"
#import "MTDataTable.h"

#import "MTNotificationDidFormatPage.h"

#import "MTActivityIndicator.h"
#import "MTReportFormatterPageDefinition.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqUserCredentals.h"
#import "RptqUserCredentals+Extras.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryGroup.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryField.h"

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

NSString * const MTDocumentAdditionalContentKey         = @"additionalContent";
NSString * const MTDocumentFileTypeKey                  = @"fileType";
NSString * const MTDocumentParentContextKey             = @"parentContext";

NSString * const MTDocumentAdditionalContentFileName    = @"sup";
NSString * const MTDocumentGeneratorFileName            = @"gen";
NSString * const MTDocumentThumbnailFileName            = @"img";
NSString * const MTDocumentVersionFileName              = @"ver";
NSString * const MTDocumentTypenFileName                = @"typ";
NSString * const MTDocumentParentContextName            = @"moc";

NSString * const MTDocumentInfoKeyThumbnail             = @"thumbnail";
NSString * const MTDocumentInfoKeyThumbnailStandard     = @"thumbnail.png";
NSString * const MTDocumentInfoKeyThumbnailRetna        = @"thumbnail@2x.png";
NSString * const MTDocumentInfoKeyMeta                  = @"meta.plist";
NSString * const MTDocumentInfoKeyVersion               = @"version";
NSString * const MTDocumentInfoKeyGenerator             = @"generator";

NSString * const MTDocumentInfoKeyMetaEditor            = @"editor";
NSString * const MTDocumentInfoKeyMetaFileVersion       = @"fileversion";
NSString * const MTDocumentInfoKeyMetaDateCreated       = @"datacreated";

//Keys stored in the cache.  Short and unique.
NSString * const MTReportSectionType                    = @"a";
NSString * const MTReportGroupLevel                     = @"b";
NSString * const MTReportDetailRowId                    = @"d";

NSString * const MADUtiType                             = @"com.everydayapps.productivity.mad";
NSString * const MADMimeType                            = @"application/vnd.everydayapps.mad";

@interface MADocument ()
    <MTDatabaseProtocol>

@property (nonatomic, strong) NSMutableDictionary *extraInformation;        //Structure for extra info
@property (nonatomic, strong) UIImage *thumbnail;

@property (nonatomic, strong) NSManagedObjectModel *mom;

@property (nonatomic, strong) RptqDocument *document;
@property (nonatomic, strong) MTDatabase *mainDatabase;
@property (nonatomic, strong) MTQuery *mainQuery;
@property (nonatomic, strong, readwrite) MTDataTable *mainDataTable;

@property (nonatomic, strong) NSMutableDictionary *reportQueries;

@property (nonatomic, assign) BOOL didRefresh;

@property (nonatomic, strong) MTActivityIndicator *statusLabel;

@property (nonatomic, strong) MTReportFormatter *printingReportFormatter;   //Used only when printing

@property (nonatomic, strong, readwrite) NSURL *urlGuts;

@end

@implementation MADocument

#pragma mark - NSObject

- (void)dealloc {
    
    [_mainQuery database].delegate = nil;

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextObjectsDidChangeNotification
                           object: self.managedObjectContext];
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextDidSaveNotification
                           object: self.managedObjectContext];
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextWillSaveNotification
                           object: self];
    [defaultCenter removeObserver: self
                             name: UIDocumentStateChangedNotification
                           object: self];
}

#pragma mark - UIDocument

- (instancetype)initWithFileURL:(NSURL *)url {
    MTLog(@"\n\t%s\n\t%@\n\n", __PRETTY_FUNCTION__, url);
    self = [super initWithFileURL:url];
    if (self) {
        
        NSNumber *migratePersistentStoresAutomaticallyOption = @(YES);
        NSNumber *inferMappingModelAutomaticallyOption = @(YES);
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption : migratePersistentStoresAutomaticallyOption,
                                  NSInferMappingModelAutomaticallyOption : inferMappingModelAutomaticallyOption,
                                  };
        [self setPersistentStoreOptions: options];
        
        NSURL *destinationUrl = [self archiveUrlForMadUrl:url];
        MTLog(@"Archive URL: %@", destinationUrl);
        self.urlGuts = destinationUrl;

        MADocumentState *documentState = [MADocumentState new];
        documentState.saveInProgress = NO;
        documentState.needsSave = NO;
        documentState.contextChagned = NO;
        [self setDocumentStatus:documentState];
        
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
        
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

        NSMutableDictionary *reportQueries = [[NSMutableDictionary alloc] init];
        [self setReportQueries:reportQueries];
        [self setDidRefresh:NO];
        
        NSString *name = [self fileNameMinusExtention];
        [self initalizeMainDataTableWithName:name];
        
    }
    return self;
}

- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler {
    __weak MADocument *weakself = self;
    [super closeWithCompletionHandler:^(BOOL success) {
        if (success) {
            [weakself removeGuts];
            completionHandler(YES);
        } else {
            completionHandler(NO);
        }
    }];
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError **)outError {
    MTLog(@"\n\t%s\n\t%@\n\n", __PRETTY_FUNCTION__, url);

    //Unpack files from binary NSData url to NSFileWrapper in tmp folder
    BOOL success = NO;
    if ([url.pathExtension isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager deleteCoreDataFilesAtDirectory:self.urlGuts];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
        NSError *fileWrittingError = nil;
        [fileWrapper writeToURL:self.urlGuts options:writingOptions originalContentsURL:url error:&fileWrittingError];
        if (fileWrittingError) {
            fileWrittingError = nil;
            [fileWrapper writeToURL:self.urlGuts options:writingOptions originalContentsURL:url error:&fileWrittingError];
        }
        success = fileWrittingError == nil;
    }
    if (success) {
        success = [super readFromURL:self.urlGuts error:outError];
    }
    return success;
}

- (BOOL)writeContents:(id)contents
        andAttributes:(NSDictionary *)additionalFileAttributes
          safelyToURL:(NSURL *)url
     forSaveOperation:(UIDocumentSaveOperation)saveOperation
                error:(NSError **)outError {
    MTLog(@"\n\t%s\n\t%@\n\t%@\n\t%@\n\t%ld\n\n", __PRETTY_FUNCTION__, contents, additionalFileAttributes, url, saveOperation);
    MTLog(@"\n\tAutosave bitches");
    
    [super writeContents:contents andAttributes:additionalFileAttributes
             safelyToURL:self.urlGuts forSaveOperation:saveOperation error:outError];
    
    [self wrapFileOverwrite: YES];
    
    NSError *fileWrapperError = nil;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: self.urlGuts
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    //NSURL *resultUrl;
    BOOL success = NO;
    if (fileWrapperError == nil) {
        NSData *data = [fileWrapper serializedRepresentation];
        NSError *errorWriting = nil;
        success = [data writeToURL:self.fileURL options:NSDataWritingAtomic error:&errorWriting];
        if (errorWriting) {
            success = [data writeToURL:self.fileURL options:NSDataWritingAtomic error:&errorWriting];
            if (errorWriting) {
                *outError = errorWriting;
            }
        }
    } else {
        *outError = fileWrapperError;
    }
    
    return YES;
}

- (void)removeGuts {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *propertyKeys = @[NSURLIsDirectoryKey];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:self.urlGuts includingPropertiesForKeys:propertyKeys options:-1 errorHandler:^BOOL(NSURL *url, NSError *error) {
        NSAssert(error == nil, @"%@", error);
        return YES;
    }];
    for (NSURL *url in enumerator) {
        NSError *error = nil;
        [fileManager removeItemAtURL:url error:&error];
        NSAssert(error == nil, @"%@", error);
    }
    NSError *deleteError = nil;
    [fileManager removeItemAtURL:self.urlGuts error:&deleteError];
    NSAssert(deleteError == nil, @"%@", deleteError);
   
}

- (NSURL *)unpackMadFile:(NSURL *)url toDestinationUrl:(NSURL *)destinationUrl {
    NSURL *urlToOpen = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileexist = [fileManager fileExistsAtPath:[url path]];
    if (fileexist) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
        NSError *fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
        if (fileWrittingError) {
            fileWrittingError = nil;
            [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
        }
        if (fileWrittingError == nil) {
            urlToOpen = destinationUrl;
        }
    } else {
        urlToOpen = url;
    }
    return urlToOpen;
}

- (NSURL *)archiveUrlForMadUrl:(NSURL *)madUrl {
    NSString *filename = [madUrl.lastPathComponent stringByDeletingPathExtension];
    NSString *destinationName = [filename stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocumentArchive];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *destinationDirectoryUrl = [fileManager localTemporaryDirectory];
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSAutosavedInformationDirectory, NSUserDomainMask, YES);
    [directories lastObject];
    return [destinationDirectoryUrl URLByAppendingPathComponent:destinationName isDirectory:YES];
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    MTLog(@"%s %@\n\n", __PRETTY_FUNCTION__, [error localizedDescription]);
    
    if (false) {
        NSArray *errors = [error userInfo][NSDetailedErrorsKey];
        if (errors != nil && errors.count > 0) {
            for (NSError *error in errors) {
                MTLog(@"  Error: %@", error.userInfo);
            }
        }
    }
    
    BOOL showError = NO;
    switch ([error code]) {
        case 260:
            showError = YES;
            break;
        default:
            break;
    }
    if (showError) {
        [NSThread completeOnMainThread:^(BOOL success, id obj) {
            NSString *errorDesc = @"Failed to open document. Document incomplete, missing, or corrupt.";
            NSString *localizedErrorDesc = NSLocalizedString(errorDesc, errorDesc);
            NSError *err = [NSError errorWithDomain: @"MADocument"
                                               code: 260
                                           userInfo: @{ NSLocalizedDescriptionKey : localizedErrorDesc}];
            [err presentErrorToUser];
        } withObject:error andSuccess:YES];
    }
    MTLog(@"  %@", error.userInfo);
}


- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url
                            forSaveOperation:(UIDocumentSaveOperation)saveOperation
                                       error:(NSError **)outError {

    return [UIDevice isModernOS] ? [self fileAttributesOSModernError:outError] :
                                   [self fileAttributesOSLagacy];
    
}

- (NSDictionary *)fileAttributesOSModernError:(NSError **)outError {
    
    MTReportViewerPrintPageRenderer *printPageRender =
        [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: self.reportFormatter
                                                               dataTable: self.mainDataTable];

    CGRect letterRect = [MTPaper rectLetter];
    UIImage *thumbnail = [printPageRender thumbnailWithRect: CGRectMake(CGPointZero.x, CGPointZero.y, (1024.0000f * letterRect.size.width) / 1024.0000f, 1024.0000f)
                                                       size: 1024.0000f
                                                 edgeEffect: NO
                                                 zoomEffect: NO
                                               squareEffect: YES
                                                 cornerSize: 0.0000f
                                                      scale: 1.0000f];
    
    NSDictionary *thumbnails = @{NSThumbnail1024x1024SizeKey : thumbnail};
    NSData *pngImage = UIImagePNGRepresentation(thumbnail);
    NSError *error = nil;
    [pngImage writeToFile:@"/Users/mthomason/Desktop/test.png" options:NSAtomicWrite error:&error];
    NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
    *outError = error;
    
    return @{
             NSURLThumbnailDictionaryKey : thumbnails
             };

}

- (NSDictionary *)fileAttributesOSLagacy {
    return @{};
}


- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(UIDocumentSaveOperation)saveOperation {
    return MTDocumentExtentionMobleApplicationDocumentArchive;
}

- (NSString *)fileType {
    return [MADocument fileType];
}

#pragma mark - UIManagedDocument

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)storeURL
                                           ofType:(NSString *)fileType
                               modelConfiguration:(NSString *)configuration
                                     storeOptions:(NSDictionary *)storeOptions
                                            error:(NSError **)error {
    MTLog(@"\n\t%s\n\tstore url: %@\n\n", __PRETTY_FUNCTION__, storeURL);
    return [super configurePersistentStoreCoordinatorForURL:storeURL
                                                     ofType:fileType
                                         modelConfiguration:configuration
                                               storeOptions:storeOptions
                                                      error:error];
}

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error {
    MTLog(@"\n\t%s\n\t%@\n\n", __PRETTY_FUNCTION__, absoluteURL);
    
    NSData *imageData = [[NSFileManager defaultManager] dataForUrl:self.urlThumbnail];;
    
    if (imageData != nil) {
        UIImage *image = [UIImage imageWithData: imageData];
        if (image != nil) {
            UIImage *extraImage = [UIImage imageWithData:imageData];
            NSString *key = [MADocument thumbnailSaveName];
            self.extraInformation[key] = extraImage;
        }
    }
    
    NSURL *metaUrl = [self urlMetaPlaylist];
    
    NSDictionary *dicionary = [NSDictionary dictionaryWithContentsOfURL:metaUrl];
    NSString *lastGenerator = dicionary[MTDocumentInfoKeyGenerator];
    NSNumber *lastVersion = dicionary[MTDocumentInfoKeyGenerator];
    
    if (lastGenerator == nil) lastGenerator = @"MAD Designer";
    if (lastVersion == nil) lastVersion = @(1.0);
    
    self.extraInformation[MTDocumentInfoKeyGenerator] = lastGenerator;
    
    self.extraInformation[MTDocumentInfoKeyVersion] = lastVersion;
    
    return YES;
}

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError **)error {
    MTLog(@"\n\t%s\n\t%@\n\n", __PRETTY_FUNCTION__, absoluteURL);
    
    if (self.extraInformation == nil) {
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
    }
    NSNumber *dataVersion = @(1.0);
    self.extraInformation[MTDocumentInfoKeyVersion] = dataVersion;
    self.extraInformation[MTDocumentInfoKeyGenerator] = @"MAD Designer";
    return self.extraInformation;
}

- (BOOL)writeAdditionalContent:(id)content toURL:(NSURL *)absoluteURL originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error {
    MTLog(@"\n\t%s\n\tabsoluteURL: %@\n\tabsoluteOriginalContentsURL%@\n\n", __PRETTY_FUNCTION__, absoluteURL, absoluteOriginalContentsURL);
    BOOL writeAdditionalContent = [super writeAdditionalContent:content toURL:absoluteURL originalContentsURL:absoluteOriginalContentsURL error:error];
    
    
    if (content ==[NSNull null] || [self.documentStatus isSuspended]) {
        
        writeAdditionalContent  = NO;
        
    } else if (content != nil) {
        
        writeAdditionalContent  = YES;
        
        NSError *filePresenterError = nil;
        
        NSURL *metaUrl = [self urlMetaPlaylist];
        id version = content[MTDocumentInfoKeyVersion];
        id generator = content[MTDocumentInfoKeyGenerator];
        [(NSDictionary *)@{MTDocumentInfoKeyVersion:version, MTDocumentInfoKeyGenerator:generator} writeToURL:metaUrl atomically:NO];
        
        if (filePresenterError != nil) {
            [filePresenterError presentErrorToUser];
        }
        
    } else {
        writeAdditionalContent = NO;
    }
    return writeAdditionalContent;
}

- (NSManagedObjectModel *)managedObjectModel {
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"MAD" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return mom;
}

+ (NSString *)persistentStoreName {
    return MTPersistentStoreAliasMad;
}

#pragma mark - UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController {}
- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController {}

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)printInteractionController {
    UIPrintPaper *printPaper = printInteractionController.printPaper;
    self.printingReportFormatter.dataDelegate = self;
    self.printingReportFormatter.layoutSize = printPaper.paperSize;
    self.printingReportFormatter.marginUsingPrintableRect = printPaper.printableRect;
    self.printingReportFormatter.didRefresh = YES;   //Force formatting
    [self.printingReportFormatter formatForSize: printPaper.paperSize
                                 contentChanged: NO];
}
- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)printInteractionController {
    [self setPrintingReportFormatter:nil];
}

#pragma mark - NSManagedObjectContext Notifications
#pragma mark NSManagedObjectContextObjectsDidChangeNotification

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    [self.documentStatus setNeedsSave:YES];
    [self.documentStatus setContextChagned:YES];
}

#pragma mark NSManagedObjectContextDidSaveNotification

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    [self.documentStatus setSaveInProgress:NO];
    [self.documentStatus setNeedsSave:NO];
}

#pragma mark NSManagedObjectContextWillSaveNotification

- (void)managedObjectContextWillSave:(NSNotification *)notification {
    [self.documentStatus setSaveInProgress:YES];
}

#pragma mark - UIDocument Notifications
#pragma mark UIDocumentStateChangedNotification

- (void)documentStateChanged:(NSNotification *)notification {

    switch (self.documentState) {
        case UIDocumentStateClosed:
            MTLog(@"\n\n\tDocument state closed.\n\n");
            break;
        case UIDocumentStateEditingDisabled:
            MTLog(@"\n\n\tDocument state editing disabled.\n\n");
            break;
        case UIDocumentStateInConflict:
            MTLog(@"\n\n\tDocument state in conflict.\n\n");
            break;
        case UIDocumentStateNormal:
            MTLog(@"\n\n\tDocument state normal.\n\n");
            break;
        case UIDocumentStateSavingError:
            MTLog(@"\n\n\tDocument state saving error.\n\n");
            break;
        default:
            break;
    }
    
}

#pragma mark - MTDatabaseProtocol

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    switch (query.type) {
        case MTQueryTypeFull:
            [[self mainDataTable] setDataDelegate:self];
            return [self mainDataTable];
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - Helpers

- (NSString *)name {
    return [self.fileURL.lastPathComponent stringByDeletingPathExtension];
}

+ (NSString *)thumbnailSaveName {
    return [UIDevice isRetnaDisplay] ? MTDocumentInfoKeyThumbnailRetna : MTDocumentInfoKeyThumbnailStandard;
}

- (NSURL *)urlThumbnail {
    return [MADocument thumbnailUrlForMadUrl:self.fileURL];
}

- (NSURL *)urlMetaPlaylist {
    return [self.urlGuts URLByAppendingPathComponent:@"meta.plist"];
}

- (NSString *)fileName {
    return [MADocument fileNameForMadUrl:self.fileURL];
}

+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl {
    return [madUrl.lastPathComponent stringByDeletingPathExtension];
}

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext != nil) {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
            [self.managedObjectContext save:nil]; //Try again!?!?!?!
        }
    }
}

- (void)quickSave {
    if ([self.documentStatus saveInProgressLock] == NO) {
        [self.documentStatus setSaveInProgressLock:YES];
        NSURL *url = self.fileURL;
        __block MADocument *blockSelf = self;
        
        [blockSelf saveToURL: url
            forSaveOperation: UIDocumentSaveForOverwriting
           completionHandler:^(BOOL success) {
            
            blockSelf.documentStatus.suspended = YES;
            [blockSelf wrapFileOverwrite:YES];
            blockSelf.documentStatus.suspended = NO;
            blockSelf.documentStatus.saveInProgressLock = NO;
            blockSelf = nil;
        }];
    }
}

- (void)wrapFileOverwrite:(BOOL)overwrite {
    NSError *fileWrapperError = nil;
    BOOL success = NO;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: self.urlGuts
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    NSURL *resultUrl;
    if (fileWrapperError == nil) {
        if (overwrite) {
            NSData *data = [fileWrapper serializedRepresentation];
            NSError *errorWriting = nil;
            success = [data writeToURL:self.fileURL options:NSDataWritingAtomic error:&errorWriting];
        } else {
            NSString *fileName = [self.fileURL.lastPathComponent stringByDeletingPathExtension];
            resultUrl = [NSURL uniqueUrlForDocumentWithName:fileName
                                              withExtension:MTDocumentExtentionMobleApplicationDocument];
            NSData *data = [fileWrapper serializedRepresentation];
            success = [data writeToURL:resultUrl atomically:YES];
        }
    }
}

- (NSURL *)storeUrlForContext:(NSManagedObjectContext *)managedObjectContext {
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [managedObjectContext persistentStoreCoordinator];
    NSArray *persistentStores = [persistentStoreCoordinator persistentStores];
    NSPersistentStore * lastPersistentStoreCoordinator = [persistentStores lastObject];
    NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:lastPersistentStoreCoordinator];
    return storeURL;
}

- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion {
    
    MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
        NSURL *fileURL = self.fileURL;
        NSError *deleteError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *properties = @[NSURLIsDirectoryKey];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL: fileURL
                                              includingPropertiesForKeys: properties
                                                                 options: -1
                                                            errorHandler: ^BOOL(NSURL *url, NSError *error) {
            return YES;
        }];
        for (NSURL *file in enumerator) {
            NSError *error = nil;
            [fileManager removeItemAtURL:file error:&error];
        }
        [fileManager removeItemAtURL:fileURL error:&deleteError];
        NSAssert(deleteError == nil, @"%@", deleteError);
        completion(YES);
    };

    NSAssert([self documentState] == UIDocumentStateClosed, @"Document must be closed to call this!");

    NSError *error;
    
    // retrieve the store URL
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [managedObjectContext persistentStoreCoordinator];
    NSArray *persistentStores = [persistentStoreCoordinator persistentStores];
    NSPersistentStore *persistentStore = [persistentStores lastObject];
    NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:persistentStore];

    [managedObjectContext lock];
    [managedObjectContext reset];//to drop pending changes
    
    //delete the store from the current managedObjectContext
    BOOL success = [persistentStoreCoordinator removePersistentStore:persistentStore error:&error];
    if (success) {
        
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        //recreate the store like in the  appDelegate method
        
        NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
                                   NSInferMappingModelAutomaticallyOption : @YES};
        
        [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    }
    [managedObjectContext unlock];

    
    [self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

- (NSURL *)cachedFilesDirectory {
    return [MADocument cacheFilesDirectoryForFilename:[self fileName]];
}

+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename {
    NSString *filenameId = [NSFileManager filenameId:[filename hash]];
    return [[NSFileManager defaultManager] cacheDirectoryNamed:filenameId];
}

- (void)addConnection:(MTDatabaseConnection *)connection
               status:(void (^)(NSString *status, CGFloat progress))status
           completion:(void(^)(BOOL success, MTErrorContainer *error))completion {
    RptqDocument *rptqDocument = [self activeDocumentModel];
    MTDatabase *database = [MTDatabase databaseFactory:connection];
    if (database) {
        [self setMainDatabase:database];
        [rptqDocument addDatabase:self.mainDatabase status:^(NSString *message, CGFloat progress) {
            status(message, progress);
        } completion:^(BOOL success, MTErrorContainer *errorContainer) {
            MTLog(@"\n\t%@", errorContainer);
            completion(success, errorContainer);
        }];
    } else {
        completion(NO, nil);
    }
}

- (RptqDocument *)activeDocumentModel {
    if ([self document] == nil) {
        NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
        RptqDocument *document = [RptqDocument documentForManagedObjectContext: managedObjectContext];
        if (document == nil) {
            document = [RptqDocument documentFactory:managedObjectContext];
        }
        [self setDocument:document];
        
        if (self.reportFormatter == nil) {
            [self initalizeReportFormatter];
        }
        
        if (self.mainDatabase == nil) {
            [self initalizeMainDatabase];
        }
    }
    return [self document];
}

- (MTDatabase *)database {
    return [self mainDatabase];
}

- (void)initalizeMainQuery {
    RptqDatabase *database = [[self document] defaultDatabase];
    if (database) {
        RptqQuery *rquery = [database defaultQuery];
        
        NSDictionary *parameters = [MTQuery queryDefinitionFull:rquery];
        MTQuery *defaultQuery = [[MTQuery alloc] initWithQueryType:MTQueryTypeFull object:parameters];
        [defaultQuery setDataDelegate:self];
        
        [[self mainDataTable] sortUsingDescriptors:[self sortDescriptors]];
        [self setMainQuery:defaultQuery];
    }
}

- (void)initalizeMainDataTableWithName:(NSString *)name {
    NSUInteger hash = [name hash];
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypePhysical);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    MTDataTable *datatable = [MTDataTable dataTableFactory:parameters];
    [datatable setCacheDelegate:self];
    [self setMainDataTable:datatable];
}

- (void)initalizeReportFormatter {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: [self defaultQuery]
                                                                              layout: [self activeDocumentModel]
                                                                             options: MTReportFormatterOptionsNone];
    [reportFormatter setDataDelegate:self];
    [reportFormatter setCachedDelegate:self];
    [reportFormatter setDatasource:self];
    [self setReportFormatter:reportFormatter];
}

- (void)initalizeMainDatabase {
    RptqDatabase *database = [self.document defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    RptqUserCredentals *userCredentals = [[query inDatabase] ownedByUser];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
    MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
    db.delegate = self;
    [self setMainDatabase:db];
}

- (void)prepareForQuery {
    [[self mainDataTable] sortUsingDescriptors:[self sortDescriptors]];
}

- (NSEnumerator *)enumeratorForReportData {
    return [[self mainDataTable] enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
    NSURL *url = [[self mainDataTable] url];
    return [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cachedID {
    return  [[self mainDataTable] dataForCacheId:cachedID];
}

- (void)disableUserInteraction:(UIView *)view {
    for (UIView *subview in [view subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            [(UILabel *)subview performSelectorOnMainThread:@selector(setTextColor:) withObject:[UIColor lightGrayColor] waitUntilDone:NO];
        } else if ([subview isKindOfClass:[UIImageView class]]) {
            dispatch_queue_t dipatchQueueMain = dispatch_get_main_queue();
            dispatch_sync(dipatchQueueMain, ^{
                [(UIImageView *)subview setAlpha:0.3333f];
            });
        }
        [self disableUserInteraction:subview];
    }
}

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSDictionary *parameters = [sender userInfo];
    NSNumber *pageNumber = parameters[MTDatabaseNumberOfPagesFormattedKey];
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:pageNumber numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [[self statusLabel].status performSelectorOnMainThread:@selector(setText:) withObject:readRecords waitUntilDone:NO];
}

- (NSString *)fileNameMinusExtention {
    return [self.fileURL filenameMinusExtention];
}

- (NSUInteger)fileNameHash {
    return [[self fileNameMinusExtention] hash];
}

- (MTQuery *)defaultQuery {
    if ([self mainQuery] == nil) {
        [self initalizeMainQuery];
    }
    return [self mainQuery];
}

- (void)refresh:(void (^)(BOOL success, NSError *error))completion {
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(bgQueue, ^{
        NSString *name = [self fileNameMinusExtention];
        [self initalizeMainDataTableWithName:name];
        [self initalizeMainQuery];
        [self initalizeReportFormatter];
        MTQuery *fullQuery = [self defaultQuery];
        [fullQuery database].delegate = self;
        __weak MADocument *weakself = self;
        
        @autoreleasepool {
            [[self database] executeQuery:fullQuery completion:^(BOOL success, NSError *error) {
                [[weakself mainDataTable] cache];
                [weakself setDidRefresh:success];
                [NSThread completeOnMainThread:^(BOOL success, id error) {
                    completion(success, error);
                } withObject:error andSuccess:success];
            }];
        }
    });
}

- (NSURL *)mcacheUrl {
    NSString *fileName = [[NSString stringWithFormat:@"%ld", (unsigned long)[self fileNameHash]] stringByAppendingPathExtension:@"mdcache"];
    return [[self cachedFilesDirectory] URLByAppendingPathComponent:fileName isDirectory:NO];
}

- (NSURL *)maddbUrl {
    NSString *fileName = [[NSString stringWithFormat:@"%ld", (unsigned long)[self fileNameHash]] stringByAppendingPathExtension:@"maddb"];
    return [[self cachedFilesDirectory] URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSURL *)mcacheUrlForFileHandle:(NSString *)filehandle {
    return [MADocument cachedUrlForHash:[filehandle hash] andExtension:@"mcache"];
}

+ (NSURL *)maddbUrlForFileHandle:(NSString *)filehandle {
    return [MADocument cachedUrlForHash:[filehandle hash] andExtension:@"maddb"];
}

+ (NSURL *)cachedUrlForHash:(NSUInteger)hash andExtension:(NSString *)extension {
    NSString *fileName = [NSFileManager filenameId:hash extention:extension];
    NSURL *cachedDirectory = [[NSFileManager defaultManager] cacheDirectoryNamed:fileName];
    return [cachedDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

- (NSURL *)thumbnailUrl {
    return [MADocument thumbnailUrlForHandle:[self fileNameMinusExtention] andRetinaDisplay:NO];
}

- (NSURL *)thumbnailRetniaUrl {
    return [MADocument thumbnailUrlForHandle:[self fileNameMinusExtention] andRetinaDisplay:YES];
}

- (NSURL *)cachedDataUrl {
    return [[self mainDataTable] url];
}

- (NSString *)fileHandle {
    return [[[self urlThumbnail] path] lastPathComponent];
}

+ (NSString *)fileType {
    return MTDocumentTypeUtiMad;
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl {
    return [MADocument thumbnailUrlForHandle:[madUrl.lastPathComponent stringByDeletingPathExtension]
                                  andRetinaDisplay:[UIDevice isRetnaDisplay]];
}

+ (NSURL *)thumbnail1024UrlForMadUrl:(NSURL *)madUrl {
    NSString *handle = [madUrl.lastPathComponent stringByDeletingPathExtension];
    NSString *fileName = [handle stringByAppendingString:@"1024"];
    fileName = [fileName stringByAppendingPathExtension:@"png"];
    
    NSString *fileNameId = [NSFileManager filenameId:[handle hash]];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] cacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
    
}

+ (NSURL *)thumbnailUrlForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
    NSString *extention = [UIDevice isRetnaDisplay] ? @"@2x.png": @".png";
    NSString *fileName = [handle stringByAppendingString:extention];
    
    NSString *fileNameId = [NSFileManager filenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] cacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl {
    return [self thumbnailUrlForMadUrl:madUrl];
}

- (void)close:(void(^)(BOOL success, NSError *error))completion {
    [self closeWithCompletionHandler:^(BOOL success) {
        if (success) {
            [self.documentStatus setSuspended:YES];
            [self.managedObjectContext lock];
            [self wrapFileOverwrite:NO];
            [self deleteFromDiskCompletion:^(BOOL success) {
                [NSThread completeOnMainThread:completion withObject:nil andSuccess:YES];
            }];
        }
    }];
}

- (void)closeAndDelete:(void(^)(BOOL successAddingDatasource, NSError *error))completion {
    [self closeWithCompletionHandler:^(BOOL successClosingReport) {
        if (successClosingReport) {
            [self deleteFromDiskCompletion:^(BOOL successDeletingFromDisk) { }];
            NSError *error = [MADocument errorConnectionProblem];
            [NSThread completeOnMainThread:completion withObject:error andSuccess:NO];
        }
    }];
}

+ (NSError *)errorConnectionProblem {
    NSString *title = NSLocalizedString(@"Connection Problem", @"Connection Problem");
    NSString *message = NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.");
    return [NSError errorWithDomain:@"MTReportDocument" code:36732 title:title andMessage:message];
}

+ (NSError *)errorFailedToCreateReport {
    NSString *title = NSLocalizedString(MNSInterfaceTitleProblem, MNSInterfaceTitleProblem);
    NSString *message = NSLocalizedString(MNSInterfaceMessageErrorFailedToCreateReport, MNSInterfaceMessageErrorFailedToCreateReport);
    return [NSError errorWithDomain:@"MTReportDocument" code:36732 title:title andMessage:message];
}

- (void)regenThumbnail {
    [[NSFileManager defaultManager] fileExistsAtPath:[[self urlThumbnail] path]];
    BOOL contentChanged = [self activeDocumentModel] != nil && ([self.documentStatus contextChagned] == YES || [self didRefresh]) && [[self reportFormatter] numberOfPages] > 0;
    if (contentChanged || [[NSFileManager defaultManager] fileExistsAtPath:[[self urlThumbnail] path]] == NO) {
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[self reportFormatter]
                                                                                                                  dataTable:[self mainDataTable]];
        UIImage *thumbnail = [printPageRender thumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        [pngImage writeToURL:[self urlThumbnail] atomically:YES];
    }
}

- (NSArray *)sortDescriptors {
    
    if (self.mainDatabase == nil) [self initalizeMainDatabase];
    RptqDatabase *database = [self.document defaultDatabase];
    RptqQuery *rquery = [database defaultQuery];
    return [rquery sortDescriptorsForDatabase:self.mainDatabase];
}

- (UIPrintPageRenderer *)printerPrintPageRender {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: [self defaultQuery]
                                                                              layout: [self activeDocumentModel]
                                                                             options: MTReportFormatterOptionsMargin];
    
    [reportFormatter setCachedDelegate:self];
    [reportFormatter setOverrideIdentifier:@"madprinter"];
    [reportFormatter setDatasource:self];
    
    MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:reportFormatter
                                                                                                              dataTable:[self mainDataTable]];
    [self setPrintingReportFormatter:reportFormatter];
    return printPageRender;
    
}

- (CGRect)statusViewRect {
    return CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 200.0000f);
}

- (void)writeToPdf:(NSURL *)filepath withViewController:(UIViewController *)window {
    [self disableUserInteraction:window.view];
    
    MTActivityIndicator *activityView = [[MTActivityIndicator alloc] initWithFrame:[self statusViewRect]];
    activityView.center = window.view.center;
    
    [window.view performSelectorOnMainThread:@selector(addSubview:) withObject:activityView waitUntilDone:YES];
    [self setStatusLabel:activityView];
    
    __weak MADocument *weakself = self;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(dipatchQueue, ^{
        
        
        NSDictionary *options = @{(NSString *)kCGPDFContextCreator :  @"MAD® Designer"};
        CGRect letterRect = [MTPaper rectLetter];
        [[weakself mainDataTable] sortUsingDescriptors:[weakself sortDescriptors]];
        MTReportFormatter *rf = [MTReportFormatter reportFormatterWithQuery:weakself.mainQuery
                                                                     layout:weakself.document
                                                                    options:MTReportFormatterOptionsMargin];
        [rf setCachedDelegate:weakself];
        [rf setDataDelegate:weakself];
        [rf setOverrideIdentifier:@"madpreview"];
        [rf setDidRefresh:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver: weakself
                                                 selector: @selector(reportFormatterDidFormatPage:)
                                                     name: MTNotificationDidFormatPagesName
                                                   object: rf];
        
        
        [rf setLayoutSize:letterRect.size];
        CGFloat halfInch = 72.0000f / 2.0000f;
        UIEdgeInsets border = UIEdgeInsetsMake(halfInch, halfInch, halfInch, halfInch);
        CGRect trimBoxRect = UIEdgeInsetsInsetRect(letterRect, border);
        [rf setMarginUsingPrintableRect:trimBoxRect];
        [rf setDatasource:weakself];
        [rf formatForSize:letterRect.size contentChanged:NO];
        
        
        [[NSNotificationCenter defaultCenter] removeObserver: weakself
                                                        name: MTNotificationDidFormatPagesName
                                                      object: rf];
        
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:rf
                                                                                                                  dataTable:[weakself mainDataTable]];
        NSUInteger numberOfPages = [rf numberOfPages];
        UIGraphicsBeginPDFContextToFile([filepath path], letterRect, options);
        
        NSValue *trimBox = [NSValue valueWithCGRect:trimBoxRect];
        NSDictionary *boxInfo = @{(__bridge NSString *)kCGPDFContextTrimBox: trimBox};
        NSString *numberOfPagesString = [NSNumberFormatter localizedStringFromNumber:@(numberOfPages) numberStyle:NSNumberFormatterDecimalStyle];
        for (NSUInteger i=0; i<numberOfPages; i++) {
            @autoreleasepool {
                UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
                [printPageRender drawPageAtIndex:i inRect:trimBoxRect];
                NSString *iString = [NSNumberFormatter localizedStringFromNumber:@(i) numberStyle:NSNumberFormatterDecimalStyle];
                NSString *text = [NSString stringWithFormat:@"Drawing page %@ of %@.", iString, numberOfPagesString];
                [activityView.status performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];
            }
        }
        UIGraphicsEndPDFContext();
        
        dispatch_semaphore_signal(s1);
        
    });
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    [activityView removeFromSuperview];
    
}

@end
