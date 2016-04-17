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

@interface MADocument () {
    MTDatabase *_database;
    NSManagedObjectModel *_madObjectModel;
}

    @property (nonatomic, strong) MTReportFormatter *printingReportFormatter;   //Used only when printing

    @property (nonatomic, strong) NSMutableDictionary *extraInformation;        //Structure for extra info

    @property (nonatomic, copy, readwrite) NSURL *urlDataTableCache;
    @property (nonatomic, copy, readwrite) NSURL *urlGuts;
    @property (nonatomic, copy, readwrite) NSURL *urlMetaPlaylist;

    @property (nonatomic, assign) BOOL didRefresh;

@end

@implementation MADocument

+ (BOOL)isRetnaDisplay {
    return [[UIScreen mainScreen] scale] > 1.5;
}

+ (NSURL *)archiveUrlForMadUrl:(NSURL *)madUrl {
    NSString *destinationName = [madUrl.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:MADFileExtentionMobleApplicationDocumentArchive];
    NSURL *destinationDirectoryUrl = [NSFileManager localTemporaryDirectory];
    return [destinationDirectoryUrl URLByAppendingPathComponent: destinationName isDirectory: YES];
}

+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename {
    NSString *filenameId = [MADFilename newFilenameId:filename.hash];
    return [[NSFileManager defaultManager] localCacheDirectoryNamed:filenameId];
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl {
    
    return [self thumbnailUrlForHandle: madUrl.lastPathComponent.stringByDeletingPathExtension andRetinaDisplay: [self isRetnaDisplay]];
    
}

+ (NSURL *)thumbnailUrlForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
    NSString *name = [self isRetnaDisplay] ? [handle stringByAppendingString:@"@2x"] : handle;
    NSString *filename = [name stringByAppendingPathExtension:MTDocumentExtentionPoratableNetworkGraphic];
    NSString *fileNameId = [MADFilename newFilenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (NSURL *)thumbnailURL {
    return [MADocument thumbnailUrlForHandle: self.fileURL.lastPathComponent.stringByDeletingPathExtension andRetinaDisplay: [MADocument isRetnaDisplay]];
}

- (NSURL *)urlDataTableCache {
    NSString *filename = [self filename];
    return [self cacheUrlForFilename:filename];
}
- (NSURL *)cachedFilesDirectory {
    NSString *filename = [self filename];
    return [MADocument cacheFilesDirectoryForFilename:filename];
}

- (NSURL *)cacheUrlForFilename:(NSString *)filename {
    return [self.cachedFilesDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

#pragma mark - Property Overrides

- (MTDatabase *)database { return _database; }

- (void)setDatabase:(MTDatabase *)database {
    _database = database;
    _database.delegate = self;
}

#pragma mark - NSObject

- (void)dealloc {
    
    [_mainQuery database].delegate = nil;
    
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

- (NSDictionary *)layoutHeightsBySectionKey {
    __block NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [self.sectionLayoutManagers enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *key, MADSectionLayoutManager *sectionLayoutManager, BOOL *stop) {
        
        NSString *k = [key key];
        dictionary[k] = @(sectionLayoutManager.size.height);
        
    }];
    return dictionary;
}

- (instancetype)initWithFileURL:(NSURL *)url {
    if (self = [super initWithFileURL:url]) {
        
        NSNumber *migratePersistentStoresAutomaticallyOption =  [[NSNumber alloc] initWithBool:YES];
        NSNumber *inferMappingModelAutomaticallyOption = [[NSNumber alloc] initWithBool:YES];
        NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:inferMappingModelAutomaticallyOption, NSInferMappingModelAutomaticallyOption,
                                                                             migratePersistentStoresAutomaticallyOption, NSMigratePersistentStoresAutomaticallyOption, nil];
        
        self.persistentStoreOptions = options;
        
        NSURL *urlGuts = [MADocument archiveUrlForMadUrl:url];
        NSURL *urlMetaPlaylist = [urlGuts URLByAppendingPathComponent:MADFileNameMetaPlist];
        
        _urlMetaPlaylist = urlMetaPlaylist.copy;
        _urlGuts = urlGuts.copy;
        
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

- (NSString *)filename {
    return [MADocument fileNameForMadUrl:self.fileURL];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler {
    [self regenThumbnail];
    MADocument * __weak weakself = self;
    [super closeWithCompletionHandler:^(BOOL success) {
        if (success) {
            [weakself removeGuts];
            if (completionHandler != nil) {
                completionHandler(YES);
            }
        } else {
            if (completionHandler != nil) {
                completionHandler(NO);
            }
        }
    }];
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError **)outError {

    //Unpack files from binary NSData url to NSFileWrapper in tmp folder
    BOOL success = NO;
    if ([url.pathExtension isEqualToString:MADFileExtentionMobleApplicationDocument]) {
        
        [self deleteCoreDataFilesAtDirectory:self.urlGuts];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];

        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        success = [fileWrapper writeToURL: self.urlGuts
                        options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
            originalContentsURL: url
                          error: outError];
        if (!success) {
            success = [fileWrapper writeToURL: self.urlGuts
                                      options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
                          originalContentsURL: url
                                        error: outError];
        }
        NSAssert(success, @"Failed to write at %s.", __PRETTY_FUNCTION__);
    }
    if (success) {
        success = [super readFromURL:self.urlGuts error:outError];
    }
    return success;
}

- (BOOL)writeContents:(id)contents andAttributes:(NSDictionary *)additionalFileAttributes
          safelyToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation
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
        if (!success && errorWriting) {
            *outError = errorWriting;
        }
        
    } else {
        *outError = fileWrapperError;
    }
    
    return success;
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
    
    UIImage *thumbnail = [self fullyRenderedThumbnail];
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


- (NSString *)fileNameExtensionForType: (NSString *)typeName saveOperation: (UIDocumentSaveOperation)saveOperation {
    return MADFileExtentionMobleApplicationDocument;
}

#pragma mark UIManagedDocument

- (NSManagedObjectModel *)managedObjectModel {

    if (_madObjectModel == nil) {
    
        
        NSString *modelPath = [[NSBundle mainBundle] pathForResource: MADManagedObjectModelName
                                                              ofType: MADManagedObjectModelExtention];
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        _madObjectModel = mom;
        
    }
    return _madObjectModel;
}

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error {

    NSError *readError = nil;

    NSData *imageData = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath: self.thumbnailURL.path]) {
        imageData = [NSData dataWithContentsOfURL: self.thumbnailURL options:NSDataReadingUncached error:&readError];
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
    NSNumber *dataVersion = @(1.0);
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
    self.printingReportFormatter.didRefresh = YES;
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

- (void)removeGroup:(RptqQueryGroup *)group fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

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

            NSError * __autoreleasing * error = NULL;
            [private save:error];

        }
    };
    
    [private performBlockAndWait:removeRptqGroup];
    

}

- (void)initalizeMainQuery:(RptqDocument *)document {
    RptqDatabase *database = [document defaultDatabase];
    if (database) {
        RptqQuery *rquery = [database defaultQuery];
        
        NSDictionary *parameters = [MTQuery queryDefinitionFull:rquery];
        NSMutableDictionary *extraParameters = parameters.mutableCopy;
        NSNumber *queryLimit = @(self.limitResultsDesignMode ? 50 : NSNotFound);
        extraParameters[@"MADQueryLimit"] = queryLimit;
        MTQueryFull *defaultQuery = [[MTQueryFull alloc] initWithObject:extraParameters];
        defaultQuery.dataDelegate = self;
        
        NSArray *sortDescriptors = [self readCurrentSortDescriptors];
        [self.mainDataTable sortUsingDescriptors:sortDescriptors];
        [self setMainQuery:defaultQuery];
    }
}

- (void)initalizeMainDataTable {
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypePhysical);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSString *filename = self.filename;
    NSNumber *objectIdV =  @(filename.hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    MTDataTableFast *datatable = (MTDataTableFast *)[MTDataTable newDataTableWithDefinition:parameters];
    datatable.cacheDelegate = self;
    NSString *cacheName = [datatable filenameMDCache];
    NSURL *cacheUrl = [self cacheUrlForFilename:cacheName];
    self.urlDataTableCache = cacheUrl;
    [datatable loadFromCacheWithUrl:cacheUrl];
    self.mainDataTable = datatable;
}

- (void)initalizeReportFormatter {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: self.mainQuery
                                                                              layout: self
                                                                             options: MTReportFormatterOptionsNone];
    reportFormatter.dataDelegate = self;
    reportFormatter.cachedDelegate = self;
    reportFormatter.datasource = self;
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

- (NSEnumerator *)enumeratorForReportData {
    return [self.mainDataTable enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.urlDataTableCache.path];
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cachedID {
    return  [self.mainDataTable dataForCacheId:cachedID];
}

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

- (void)regenThumbnail {
    [[NSFileManager defaultManager] fileExistsAtPath: self.thumbnailURL.path];
    BOOL contentChanged = [self activeDocumentModel] != nil && (self.documentStatus.contextChagned) && [self.reportFormatter numberOfPages] > 0;
    if (contentChanged || [[NSFileManager defaultManager] fileExistsAtPath:self.thumbnailURL.path] == NO) {
        UIImage *thumbnail = [self fullyRenderedThumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        [pngImage writeToURL:self.thumbnailURL atomically:YES];
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

- (MTReportViewerPrintPageRenderer *)printerPrintPageRender {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery: self.mainQuery
                                                                              layout: self
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
                                                                     options: NSDirectoryEnumerationSkipsPackageDescendants
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
                                                                 options: NSDirectoryEnumerationSkipsHiddenFiles
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
            //recreate the store like in the  appDelegate method
            
            NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                                      NSInferMappingModelAutomaticallyOption : @YES};
            
            [persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
                                                     configuration: nil
                                                               URL: storeURL
                                                           options: options
                                                             error: &error];
        }
        
    }];

    
    [self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

- (UIImage *)fullyRenderedThumbnail {
    MTReportViewerPrintPageRenderer *printPageRender =
    [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: self.reportFormatter dataTable: self.mainDataTable];
    
    CGRect letterRect = [MTPaper rectLetter];
    UIImage *thumbnail = [printPageRender thumbnailWithRect: CGRectMake(CGPointZero.x, CGPointZero.y,
                                                                        (MADFloat_1024 * letterRect.size.width) / MADFloat_1024,
                                                                        (MADFloat_1024 * letterRect.size.height) / MADFloat_1024)
                                                       size: MADFloat_1024
                                                 edgeEffect: NO zoomEffect: NO squareEffect: YES
                                                 cornerSize: 0.0000f scale: 1.0000f];
    return thumbnail;
}

- (bool)wrapFileOverwrite:(BOOL)overwrite {
    NSError *fileWrapperError = nil;
    bool success = false;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: self.urlGuts
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    NSURL *resultUrl;
    
    if (fileWrapperError == nil) {
        if (overwrite) {
            NSData *data = [fileWrapper serializedRepresentation];
            NSError *errorWriting = nil;
            success = [data writeToURL:self.fileURL options:NSDataWritingAtomic error:&errorWriting] ? true : false;
        } else {
            resultUrl = [self.fileURL uniqueUrl];
            NSData *data = [fileWrapper serializedRepresentation];
            success = [data writeToURL:resultUrl atomically:YES] ? true : false;
        }
    }
    
    return success;
}

#pragma mark File Name

- (void)removeGuts {
    NSArray *propertyKeys = @[NSURLIsDirectoryKey];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: self.urlGuts includingPropertiesForKeys: propertyKeys options: NSNotFound errorHandler: ^BOOL(NSURL *url, NSError *error) {
        return YES;
    }];
    
    NSError *error;
    for (NSURL *url in enumerator) {
        error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    }
    
    error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.urlGuts error:&error];
    
}

+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl { return madUrl.lastPathComponent.stringByDeletingPathExtension; }

- (NSString *)mimetype { return MADMimeType; }

@end
