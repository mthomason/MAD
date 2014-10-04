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
#import "MADocumentState.h"

#import "MACloudManager.h"


#import "MTReportViewerPrintPageRenderer.h"
#import "MTPaper.h"


#import "MTQuery.h"
#import "MTReportFormatter.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"
#import "MTDataTable.h"

#import "MTNotificationDidFormatPage.h"

#import "MTActivityIndicator.h"

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

#import "NSURL+Document.h"
#import "UIDevice+Hack.h"
#import "NSError+UserInterface.h"
#import "NSError+Constructors.h"
#import "NSFileManager+Common.h"
#import "NSThread+Extras.h"

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

NSString * const MADMimeType                            = @"application/vnd.everydayapps.mad";

NSString * const MADFileNameMetaPlist                   = @"meta.plist";

NSString * const MTPersistentStoreAliasMad              = @"analyitics";
NSString * const MTDocumentTypeUtiMad                   = @"com.everydayapps.productivity.mad";

NSString * const MNSInterfaceMessageErrorFailedToCreateReport       = @"Failed to create report document.";
NSString * const MNSInterfaceTitleProblem                           = @"Problem";

#if MAD_DESIGNER == 1 || MAD_TEST == 1
NSString * const MADUbiquitousPeerToken = @"MADDESIGNER";
#elif MAD_VIEWER == 1
NSString * const MADUbiquitousPeerToken = "MADVIEWER";
#endif

@interface MADocument ()
    <MTDatabaseProtocol>

@property (nonatomic, strong) UIImage *thumbnail;

@property (nonatomic, strong) NSMutableDictionary *extraInformation;        //Structure for extra info
@property (nonatomic, strong, readwrite) RptqDocument *document;
@property (nonatomic, strong, readwrite) MTDatabase *mainDatabase;
@property (nonatomic, strong, readwrite) MTQuery *mainQuery;
@property (nonatomic, strong, readwrite) MTDataTable *mainDataTable;

@property (nonatomic, assign) BOOL didRefresh;

@property (nonatomic, strong) MTReportFormatter *printingReportFormatter;   //Used only when printing

@property (nonatomic, strong, readwrite) NSURL *urlGuts;
@property (nonatomic, strong, readwrite) NSURL *urlThumbnail;
@property (nonatomic, strong, readwrite) NSURL *urlCachedFilesDirectory;
@property (nonatomic, strong, readwrite) NSURL *urlMetaPlaylist;

@property (nonatomic, strong, readwrite) NSString *fileName;

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
    self = [super initWithFileURL:url];
    if (self) {
        
        NSNumber *migratePersistentStoresAutomaticallyOption = @(YES);
        NSNumber *inferMappingModelAutomaticallyOption = @(YES);
        NSDictionary *options = @{
                                  //NSPersistentStoreUbiquitousContentNameKey : @"schema",
                                  NSMigratePersistentStoresAutomaticallyOption : migratePersistentStoresAutomaticallyOption,
                                  NSInferMappingModelAutomaticallyOption : inferMappingModelAutomaticallyOption,
                                  };
        
        [self setPersistentStoreOptions: options];
        
        NSURL *urlGuts = [self archiveUrlForMadUrl:url];
        NSURL *urlMetaPlaylist = [urlGuts URLByAppendingPathComponent:MADFileNameMetaPlist];
        self.urlMetaPlaylist = urlMetaPlaylist;
        self.urlGuts = urlGuts;
        
        NSURL *urlThumbnail = [MADocument thumbnailUrlForMadUrl:url];
        self.urlThumbnail = urlThumbnail;

        NSString *filename = [MADocument fileNameForMadUrl:url];
        NSURL *urlCachedFilesDirectory = [MADocument cacheFilesDirectoryForFilename:filename];
        self.urlCachedFilesDirectory = urlCachedFilesDirectory;
        self.fileName = filename;
        
        [self initalizeMainDataTable];
        
        MADocumentState *documentState = [MADocumentState new];
        self.documentStatus = documentState;
        
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
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

        self.didRefresh = NO;
        
        
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

    //Unpack files from binary NSData url to NSFileWrapper in tmp folder
    BOOL success = NO;
    if ([url.pathExtension isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
        
        [self deleteCoreDataFilesAtDirectory:self.urlGuts];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];

        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        NSError *error = nil;
        success = [fileWrapper writeToURL: self.urlGuts
                        options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
            originalContentsURL: url
                          error: outError];
        success = error == nil;
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
    
    [super writeContents:contents andAttributes:additionalFileAttributes
             safelyToURL:self.urlGuts forSaveOperation:saveOperation error:outError];
    
    [self wrapFileOverwrite: YES];
    
    NSError *fileWrapperError = nil;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: self.urlGuts
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    BOOL success = NO;
    if (fileWrapperError == nil) {
        NSData *data = [fileWrapper serializedRepresentation];
        NSError *errorWriting = nil;
        success = [data writeToURL:self.fileURL options:NSDataWritingAtomic error:&errorWriting];
        if (errorWriting) {
            *outError = errorWriting;
        }
        
    } else {
        *outError = fileWrapperError;
    }
    
    return YES;
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
            resultUrl = [[MACloudManager sharedManager] uniqueUrlForDocumentWithName: fileName
                                                                       withExtension: MTDocumentExtentionMobleApplicationDocument];
            NSData *data = [fileWrapper serializedRepresentation];
            success = [data writeToURL:resultUrl atomically:YES];
        }
    }
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    [super handleError:error userInteractionPermitted:userInteractionPermitted];
    if (userInteractionPermitted) {
        if (error.code == 260) {
            NSError *err = [MADocument errorFailedToOpenDocument];
            [err presentErrorToUser];
        } else {
            NSLog(@"Error: %@", error);
            [error presentErrorToUser];
        }
    }
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url
                            forSaveOperation:(UIDocumentSaveOperation)saveOperation
                                       error:(NSError **)outError {

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
    
    /*  Testing the image
     NSData *pngImage = UIImagePNGRepresentation(thumbnail);
     NSError *error = nil;
     [pngImage writeToFile:@"/Users/mthomason/Desktop/test.png" options:NSAtomicWrite error:&error];
     NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
     *outError = error;
     */
    
    return @{
             NSURLThumbnailDictionaryKey : thumbnails
             };
    
}


- (NSString *)fileNameExtensionForType: (NSString *)typeName
                         saveOperation: (UIDocumentSaveOperation)saveOperation {
    return MTDocumentExtentionMobleApplicationDocument;
}

#pragma mark UIManagedDocument

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)storeURL
                                           ofType:(NSString *)fileType
                               modelConfiguration:(NSString *)configuration
                                     storeOptions:(NSDictionary *)storeOptions
                                            error:(NSError **)error {
    return [super configurePersistentStoreCoordinatorForURL:storeURL
                                                     ofType:fileType
                                         modelConfiguration:configuration
                                               storeOptions:storeOptions
                                                      error:error];
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

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error {

    NSError *readError = nil;
    NSData *imageData = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.urlThumbnail path]]) {
        imageData = [NSData dataWithContentsOfURL: self.urlThumbnail options:NSDataReadingUncached error:&readError];
        if (readError != nil) {
            imageData = [NSData dataWithContentsOfURL: self.urlThumbnail options:NSDataReadingUncached error:&readError];
        }
    }
    
    if (imageData != nil) {
        UIImage *image = [UIImage imageWithData: imageData];
        if (image != nil) {
            UIImage *extraImage = [UIImage imageWithData:imageData];
            NSString *key = [UIDevice isRetnaDisplay] ? MTDocumentInfoKeyThumbnailRetna : MTDocumentInfoKeyThumbnailStandard;
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

    if (self.extraInformation == nil) {
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
    }
    NSNumber *dataVersion = @(1.0);
    self.extraInformation[MTDocumentInfoKeyVersion] = dataVersion;
    self.extraInformation[MTDocumentInfoKeyGenerator] = @"MAD Designer";
    return self.extraInformation;
}

- (BOOL)writeAdditionalContent: (id)content
                         toURL: (NSURL *)absoluteURL
           originalContentsURL: (NSURL *)absoluteOriginalContentsURL
                         error: (NSError **)error {
    BOOL writeAdditionalContent = [super writeAdditionalContent:content toURL:absoluteURL originalContentsURL:absoluteOriginalContentsURL error:error];
    
    
    if (content == [NSNull null] || self.documentStatus.isSuspended) {
        
        writeAdditionalContent  = NO;
        
    } else if (content != nil) {
        
        writeAdditionalContent  = YES;
        
        NSURL *metaUrl = [self urlMetaPlaylist];
        id version = content[MTDocumentInfoKeyVersion];
        id generator = content[MTDocumentInfoKeyGenerator];
        
        NSDictionary *additionalContent = @{MTDocumentInfoKeyVersion:version, MTDocumentInfoKeyGenerator:generator};
        [additionalContent writeToURL:metaUrl atomically:NO];
        
    } else {
        
        writeAdditionalContent = NO;
        
    }
    return writeAdditionalContent;
}

#pragma mark - UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController { }

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
    self.printingReportFormatter = nil;
}

#pragma mark - NSManagedObjectContext Notifications
#pragma mark NSManagedObjectContextObjectsDidChangeNotification

- (void)managedObjectContextDidChange:(NSNotification *)notification {
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
    
}

#pragma mark - MTDatabaseProtocol

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

#pragma mark - MTCacheProtocol

- (NSURL *)cachedFilesDirectory {
    return self.urlCachedFilesDirectory;
}

#pragma mark - MTDatabaseProtocol

- (MTDatabase *)database {
    return [self mainDatabase];
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
            completion(success, errorContainer);
        }];
    } else {
        completion(NO, nil);
    }
}

- (RptqDocument *)activeDocumentModel {
    if (self.document == nil) {

        RptqDocument *document = [RptqDocument documentForManagedObjectContext: self.managedObjectContext];
        if (document == nil) {
            document = [RptqDocument documentFactory:self.managedObjectContext];
        }
        self.document = document;
        
        if (self.mainDatabase == nil) {
            [self initalizeMainDatabase];
        }
        
        if (self.reportFormatter == nil) {
            [self initalizeMainQuery];
            [self initalizeReportFormatter];
        }

    }
    return self.document;
}

- (void)initalizeMainQuery {
    RptqDatabase *database = [self.document defaultDatabase];
    if (database) {
        RptqQuery *rquery = [database defaultQuery];
        
        NSDictionary *parameters = [MTQuery queryDefinitionFull:rquery];
        MTQuery *defaultQuery = [[MTQuery alloc] initWithQueryType:MTQueryTypeFull
                                                            object:parameters];
        defaultQuery.dataDelegate = self;
        
        [self.mainDataTable sortUsingDescriptors:[self sortDescriptors]];
        [self setMainQuery:defaultQuery];
    }
}

- (void)initalizeMainDataTable {
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypePhysical);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(self.fileName.hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    MTDataTable *datatable = [MTDataTable dataTableFactory:parameters];
    datatable.cacheDelegate = self;
    self.mainDataTable = datatable;
}

- (void)initalizeReportFormatter {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: self.mainQuery
                                                                              layout: self.document
                                                                             options: MTReportFormatterOptionsNone];
    reportFormatter.dataDelegate = self;
    reportFormatter.cachedDelegate = self;
    reportFormatter.datasource = self;
    self.reportFormatter = reportFormatter;
}

- (void)initalizeMainDatabase {
    RptqDatabase *database = [self.document defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    RptqUserCredentals *userCredentals = [[query inDatabase] ownedByUser];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
    MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
    db.delegate = self;
    self.mainDatabase = db;
}

- (void)prepareForQuery {
    [self.mainDataTable sortUsingDescriptors:[self sortDescriptors]];
}

- (NSEnumerator *)enumeratorForReportData {
    return [self.mainDataTable enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
    NSURL *url = [self.mainDataTable url];
    return [[NSFileManager defaultManager] fileExistsAtPath:url.path];
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cachedID {
    return  [self.mainDataTable dataForCacheId:cachedID];
}

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSDictionary *parameters = [sender userInfo];
    NSNumber *pageNumber = parameters[MTDatabaseNumberOfPagesFormattedKey];
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:pageNumber numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [self.statusLabel.status performSelectorOnMainThread: @selector(setText:)
                                              withObject: readRecords
                                           waitUntilDone: NO];
}

- (void)refresh:(void (^)(BOOL success, NSError *error))completion {
    
    MADocument *weakself = self;
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(bgQueue, ^{
        [weakself initalizeMainDataTable];
        [weakself initalizeMainQuery];
        [weakself initalizeReportFormatter];
        MTQuery *fullQuery = weakself.mainQuery;
        [fullQuery database].delegate = weakself;

        @autoreleasepool {
            [self.database executeQuery:fullQuery completion:^(BOOL success, NSError *error) {
                [weakself.mainDataTable cache];
                weakself.didRefresh = success;
                [NSThread completeOnMainThread:^(BOOL success, id error) {
                    completion(success, error);
                } withObject:error andSuccess:success];
            }];
        }
    });
    
}

- (NSURL *)cachedDataUrl {
    return [self.mainDataTable url];
}

- (NSString *)fileHandle {
    return self.urlThumbnail.path.lastPathComponent;
}

+ (NSURL *)thumbnail1024UrlForMadUrl:(NSURL *)madUrl {
    NSString *handle = madUrl.lastPathComponent.stringByDeletingPathExtension;
    NSString *fileName = [handle stringByAppendingString:@"1024"];
    fileName = [fileName stringByAppendingPathExtension:@"png"];
    
    NSString *fileNameId = [MACloudManager filenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
    
}

+ (NSURL *)thumbnailUrlForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
    NSString *extention = [UIDevice isRetnaDisplay] ? @"@2x.png": @".png";
    NSString *fileName = [handle stringByAppendingString:extention];
    
    NSString *fileNameId = [MACloudManager filenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl {
    return [MADocument thumbnailUrlForHandle: madUrl.lastPathComponent.stringByDeletingPathExtension
                            andRetinaDisplay: [UIDevice isRetnaDisplay]];
}

+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl {
    return [self thumbnailUrlForMadUrl:madUrl];
}

// FIXME: Only ever called when creating of report failes
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
    return [NSError errorWithDomain: @"MADocument"
                               code: 36732
                              title: title
                         andMessage: message];
}

+ (NSError *)errorFailedToOpenDocument {
    NSString *title = NSLocalizedString(@"Failed to open document.", @"Failed to open document.");
    NSString *message = NSLocalizedString(@"Document may be incomplete, missing, or corrupt.", @"Document may be incomplete, missing, or corrupt.");
    return [NSError errorWithDomain: @"MADocument"
                               code: 260
                              title: title
                         andMessage: message];
}

- (void)regenThumbnail {
    [[NSFileManager defaultManager] fileExistsAtPath: self.urlThumbnail.path];
    BOOL contentChanged = [self activeDocumentModel] != nil && (self.documentStatus.contextChagned == YES || [self didRefresh]) && [self.reportFormatter numberOfPages] > 0;
    if (contentChanged || [[NSFileManager defaultManager] fileExistsAtPath:self.urlThumbnail.path] == NO) {
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:self.reportFormatter
                                                                                                                  dataTable:self.mainDataTable];
        UIImage *thumbnail = [printPageRender thumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        [pngImage writeToURL:self.urlThumbnail atomically:YES];
    }
}

- (NSArray *)sortDescriptors {
    
    if (self.mainDatabase == nil) [self initalizeMainDatabase];
    RptqDatabase *database = [self.document defaultDatabase];
    RptqQuery *rquery = [database defaultQuery];
    return [rquery sortDescriptorsForDatabase:self.mainDatabase];
}

- (UIPrintPageRenderer *)printerPrintPageRender {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: self.mainQuery
                                                                              layout: [self activeDocumentModel]
                                                                             options: MTReportFormatterOptionsMargin];
    reportFormatter.cachedDelegate = self;
    reportFormatter.overrideIdentifier = @"madprinter";
    reportFormatter.datasource = self;
    
    MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: reportFormatter
                                                                                                              dataTable: self.mainDataTable];
    self.printingReportFormatter = reportFormatter;
    return printPageRender;
    
}

- (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl {
    BOOL isDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath: destinationUrl.path
                                    isDirectory: &isDirectory];
    if (exists) {
        NSError *deleteError = nil;
        if (isDirectory) {
            
            BOOL(^ErrorHandler)(NSURL *, NSError *) = ^BOOL(NSURL *url, NSError *error) {
                NSAssert(error != nil, @"%s : %@",__PRETTY_FUNCTION__, error);
                return YES;
            };
            NSArray *requestedKeys = @[NSURLIsDirectoryKey];
            NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL: destinationUrl
                                                  includingPropertiesForKeys: requestedKeys
                                                                     options: -1
                                                                errorHandler: ErrorHandler];
            for (NSURL *file in enumerator) {
                NSError *error = nil;
                
                [fileManager removeItemAtURL:file error:&error];
                if (error != nil) {
                    NSAssert(error != nil, @"%s : %@",__PRETTY_FUNCTION__, error);
                    [fileManager removeItemAtURL:file error:&error];
                }
                
            }
            
            [fileManager removeItemAtURL:destinationUrl error:&deleteError];
            if (deleteError != nil) {
                NSAssert(deleteError != nil, @"%s : %@",__PRETTY_FUNCTION__, deleteError);
                [fileManager removeItemAtURL:destinationUrl error:&deleteError];
            }
            
        } else {
            [fileManager removeItemAtURL:destinationUrl error:&deleteError];
            if (deleteError != nil) {
                NSAssert(deleteError != nil, @"%s : %@",__PRETTY_FUNCTION__, deleteError);
                [fileManager removeItemAtURL:destinationUrl error:&deleteError];
            }
        }
    }
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
    BOOL success = [persistentStoreCoordinator removePersistentStore: persistentStore
                                                               error: &error];
    if (success) {
        
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        //recreate the store like in the  appDelegate method
        
        NSDictionary *options = @{//NSPersistentStoreUbiquitousContentNameKey: @"MADCloudStore",
                                  NSMigratePersistentStoresAutomaticallyOption : @YES,
                                  NSInferMappingModelAutomaticallyOption : @YES};
        
        [persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
                                                 configuration: nil
                                                           URL: storeURL
                                                       options: options
                                                         error: &error];
    }
    [managedObjectContext unlock];
    
    
    [self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

- (void)removeGuts {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *propertyKeys = @[NSURLIsDirectoryKey];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL: self.urlGuts
                                          includingPropertiesForKeys: propertyKeys
                                                             options: -1
                                                        errorHandler: ^BOOL(NSURL *url, NSError *error) {
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

 - (NSURL *)archiveUrlForMadUrl:(NSURL *)madUrl {
    NSString *filename = [madUrl.lastPathComponent stringByDeletingPathExtension];
    NSString *destinationName = [filename stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocumentArchive];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *destinationDirectoryUrl = [fileManager localTemporaryDirectory];
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSAutosavedInformationDirectory, NSUserDomainMask, YES);
    [directories lastObject];
    return [destinationDirectoryUrl URLByAppendingPathComponent: destinationName
                                                    isDirectory: YES];
}

+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename {
    NSString *filenameId = [MACloudManager filenameId:[filename hash]];
    return [[NSFileManager defaultManager] localCacheDirectoryNamed:filenameId];
}

+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl {
    return [madUrl.lastPathComponent stringByDeletingPathExtension];
}

@end
