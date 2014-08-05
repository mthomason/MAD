//
//  MNSDocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADocument.h"
#import <CoreData/CoreData.h>
#import "MAReportDocument.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTLog.h"
#import "MTPaper.h"

#import "UIManagedDocument+FileOperations.h"
#import "UIColor+EverydayApps.h"
#import "NSURL+Document.h"
#import "UIDevice+Hack.h"
#import "NSError+UserInterface.h"
#import "NSFileManager+Common.h"

#import "MADocumentState.h"

#import "NSThread+Extras.h"

#import "MACloudManager.h"

NSString * const MTDocumentInfoKeyThumbnail = @"thumbnail";
NSString * const MTDocumentInfoKeyThumbnailStandard = @"thumbnail.png";
NSString * const MTDocumentInfoKeyThumbnailRetna = @"thumbnail@2x.png";
NSString * const MTDocumentInfoKeyMeta = @"meta.plist";
NSString * const MTDocumentInfoKeyVersion = @"version";
NSString * const MTDocumentInfoKeyGenerator = @"generator";

NSString * const MTDocumentInfoKeyMetaEditor = @"editor";
NSString * const MTDocumentInfoKeyMetaFileVersion = @"fileversion";
NSString * const MTDocumentInfoKeyMetaDateCreated = @"datacreated";

@interface MADocument ()

@property (nonatomic, strong) NSFileWrapper *fileWrapper;
@property (nonatomic, strong) NSMutableDictionary *extraInformation;        //Structure for extra info
@property (nonatomic, strong) UIImage *thumbnail;

//@property (nonatomic, strong, readwrite) MADocumentState *documentStatus;

@end

@implementation MADocument

- (void)dealloc {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextObjectsDidChangeNotification
                           object: [self managedObjectContext]];
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextDidSaveNotification
                           object: [self managedObjectContext]];
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextWillSaveNotification
                           object: self];
    [defaultCenter removeObserver: self
                             name: UIDocumentStateChangedNotification
                           object: self];
}

- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {
        
        
        MADocumentState *documentState = [MADocumentState new];
        [documentState setSaveInProgress:NO];
        [documentState setNeedsSave:NO];
        [documentState setContextChagned:NO];
        [self setDocumentStatus:documentState];
        
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver: self
                          selector: @selector(managedObjectContextDidChange:)
                              name: NSManagedObjectContextObjectsDidChangeNotification
                            object: [self managedObjectContext]];
        
        [defaultCenter addObserver: self
                          selector: @selector(managedObjectContextDidSave:)
                              name: NSManagedObjectContextDidSaveNotification
                            object: [self managedObjectContext]];

        [defaultCenter addObserver: self
                          selector: @selector(managedObjectContextWillSave:)
                              name: NSManagedObjectContextWillSaveNotification
                            object: self];

        [defaultCenter addObserver: self
                          selector: @selector(documentStateChanged:)
                              name: UIDocumentStateChangedNotification
                            object: self];

        
    }
    return self;
}

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    [[self documentStatus] setNeedsSave:YES];
    [[self documentStatus] setContextChagned:YES];
}

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    [[self documentStatus] setSaveInProgress:NO];
    [[self documentStatus] setNeedsSave:NO];
}

- (void)managedObjectContextWillSave:(NSNotification *)notification {
    [[self documentStatus] setSaveInProgress:YES];
}

- (void)documentStateChanged:(NSNotification *)notification {

    switch (self.documentState) {
        case UIDocumentStateClosed:
            MTLog(@"Document state closed.");
            break;
        case UIDocumentStateEditingDisabled:
            MTLog(@"Document state editing disabled.");
            break;
        case UIDocumentStateInConflict:
            MTLog(@"Document state in conflict.");
            break;
        case UIDocumentStateNormal:
            MTLog(@"Document state normal.");
            break;
        case UIDocumentStateSavingError:
            MTLog(@"Document state saving error.");
            break;
        default:
            break;
    }
    
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

NSString * MTDocumentAdditionalContentKey       = @"additionalContent";
NSString * MTDocumentFileTypeKey                = @"fileType";
NSString * MTDocumentParentContextKey           = @"parentContext";

NSString * MTDocumentAdditionalContentFileName  = @"sup";
NSString * MTDocumentGeneratorFileName          = @"gen";
NSString * MTDocumentThumbnailFileName          = @"img";
NSString * MTDocumentVersionFileName            = @"ver";
NSString * MTDocumentTypenFileName              = @"typ";
NSString * MTDocumentParentContextName          = @"moc";

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    MTLog(@"Autosaving document");
    // FIXME: Use this as a chance to wrap a mad file up.
    id result = [super contentsForType:typeName error:outError];
    return result;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL result = [super loadFromContents:contents ofType:typeName error:outError];
    return result;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    MTLog(@"UIManagedDocument error: %@", [error localizedDescription]);
    
    if (false) {
        NSArray *errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
        if (errors != nil && errors.count > 0) {
            for (NSError *error in errors) {
                NSLog(@"  Error: %@", error.userInfo);
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

- (NSString *)name {
    NSString *lastPathComponent = [[self fileURL] lastPathComponent];
    return [lastPathComponent stringByDeletingPathExtension];
}

+ (NSString *)thumbnailSaveName {
    return [UIDevice isRetnaDisplay] ? MTDocumentInfoKeyThumbnailRetna : MTDocumentInfoKeyThumbnailStandard;
}

#pragma mark - UIManagedDocument

+ (NSData *)dataForUrl:(NSURL *)url {
    NSError *readError = nil;
    NSData *data = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        data = [NSData dataWithContentsOfURL: url options:NSDataReadingUncached error:&readError];
    }
    return data;
}

- (NSURL *)urlThumbnail {
    NSURL *fileurl = [self fileURL];
    return [MAReportDocument thumbnailUrlForMadUrl:fileurl];
}

- (NSURL *)urlMetaPlaylist {
    NSURL *fileurl = [self fileURL];
    return [fileurl URLByAppendingPathComponent:@"meta.plist"];
}

- (NSData *)thumbnailData {
    return [[NSFileManager defaultManager] dataForUrl:[self urlThumbnail]];
}

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error {
    
    NSData *imageData = [self thumbnailData];

    if (imageData != nil) {
        UIImage *image = [UIImage imageWithData: imageData];
        if (image != nil) {
            UIImage *extraImage = [UIImage imageWithData:imageData];
            NSString *key = [MADocument thumbnailSaveName];
            [[self extraInformation] setObject:extraImage
                                        forKey:key];
        }
    }
    
    NSURL *metaUrl = [self urlMetaPlaylist];

    NSDictionary *dicionary = [NSDictionary dictionaryWithContentsOfURL:metaUrl];
    NSString *lastGenerator = [dicionary objectForKey:MTDocumentInfoKeyGenerator];
    NSNumber *lastVersion = [dicionary objectForKey:MTDocumentInfoKeyGenerator];

    if (lastGenerator == nil) lastGenerator = @"MAD Designer";
    if (lastVersion == nil) lastVersion = @(1.0);
    
    [[self extraInformation] setObject:lastGenerator
                                forKey:MTDocumentInfoKeyGenerator];
    
    [[self extraInformation] setObject:lastVersion
                                forKey:MTDocumentInfoKeyVersion];
 
    return YES;
}

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError **)error {

    id result;

    if ([[self documentStatus] isSuspended]) {
        result = [NSNull null];
    } else {
        if ([self extraInformation] == nil) {
            NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
            [self setExtraInformation:extraInfo];
        }
        NSNumber *dataVersion = @(1.0);
        [[self extraInformation] setObject:dataVersion forKey:MTDocumentInfoKeyVersion];
        [[self extraInformation] setObject:@"MAD Designer" forKey:MTDocumentInfoKeyGenerator];
        result = [self extraInformation];
    }

    return result;
}

- (BOOL)writeAdditionalContent:(id)content toURL:(NSURL *)absoluteURL originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error {

    BOOL writeAdditionalContent;
    
    if (content ==[NSNull null] || [[self documentStatus] isSuspended]) {

        writeAdditionalContent  = NO;
   
    } else if (content != nil) {
    
        writeAdditionalContent  = YES;

        NSError *filePresenterError = nil;
        
        NSURL *metaUrl = [self urlMetaPlaylist];
        id version = [content objectForKey:MTDocumentInfoKeyVersion];
        id generator = [content objectForKey:MTDocumentInfoKeyGenerator];
        [(NSDictionary *)@{MTDocumentInfoKeyVersion:version, MTDocumentInfoKeyGenerator:generator} writeToURL:metaUrl atomically:NO];
        
        if (filePresenterError != nil) {
            [filePresenterError presentErrorToUser];
        }
 
    } else {
        writeAdditionalContent = NO;
    }
    return writeAdditionalContent;
}

- (NSString *)fileName {
    return [MADocument fileNameForMadUrl:[self fileURL]];
}

+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl {
    if ([[madUrl pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive]) {

    } else {
        
    }
    return [[madUrl lastPathComponent] stringByDeletingPathExtension];
}

- (void)saveContext {
    NSError *error;
    if ([self managedObjectContext] != nil) {
        if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
            [[self managedObjectContext] save:nil]; //Try again!?!?!?!
        }
    }
}

- (void)quickSave {
    if ([[self documentStatus] saveInProgressLock] == NO) {
        [[self documentStatus] setSaveInProgressLock:YES];
        NSURL *url = [self fileURL];
        __block MADocument *blockSelf = self;
        [blockSelf saveToURL: url forSaveOperation: UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            
            [[blockSelf documentStatus] setSuspended:YES];
            [self wrapFileOverwrite:YES completion:nil];
            [[blockSelf documentStatus] setSuspended:NO];
            
            [[blockSelf documentStatus] setSaveInProgressLock:NO];
            blockSelf = nil;
        }];
    }
}

- (void)wrapFileOverwrite:(BOOL)overwrite completion:(void (^)(BOOL success, NSURL *resultUrl))completion {
    NSError *fileWrapperError = nil;
    BOOL success = NO;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: [self fileURL]
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    if (fileWrapperError == nil) {
        NSString *fileName = [[[self fileURL] lastPathComponent] stringByDeletingPathExtension];
        if (overwrite) {
            fileName = [fileName stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocument];
            NSURL *resultUrl = [[[MACloudManager sharedManager] documentsDirectoryURL] URLByAppendingPathComponent:fileName isDirectory:NO];
            NSData *data = [fileWrapper serializedRepresentation];
            NSError *errorWriting = nil;
            success = [data writeToURL:resultUrl options:NSDataWritingAtomic error:&errorWriting];
            if (completion != NULL) {
                completion(success, resultUrl);
            }
        } else {
            NSURL *resultUrl = [NSURL uniqueUrlForDocumentWithName:fileName
                                                     withExtension:MTDocumentExtentionMobleApplicationDocument];
            NSData *data = [fileWrapper serializedRepresentation];
            success = [data writeToURL:resultUrl atomically:YES];
            if (completion != NULL) {
                completion(success, resultUrl);
            }
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
        NSURL *fileURL = [self fileURL];
        NSError *deleteError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL: fileURL
                                              includingPropertiesForKeys: @[NSURLIsDirectoryKey]
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
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
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

+ (void)deleteFromDisk:(NSURL *)fileUrl completion:(void (^)(BOOL success))completion {
    
    __weak NSURL *blockFileUrl = fileUrl;
    MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
        NSError *deleteError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:blockFileUrl
                                              includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                                 options:-1
                                                            errorHandler:^BOOL(NSURL *url, NSError *error) {
            return YES;
        }];
        for (NSURL *blockFileUrl in enumerator) {
            NSError *error = nil;
            [fileManager removeItemAtURL:blockFileUrl error:&error];
        }
        [fileManager removeItemAtURL:blockFileUrl error:&deleteError];
        completion(YES);
    };
    
    MAReportDocument *documentReport = [[MAReportDocument alloc] initWithFileURL:fileUrl];
    BOOL properTypeToWrap = [[fileUrl pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive];
    if (properTypeToWrap) {
    
        if ([documentReport documentState] != UIDocumentStateClosed) {
            __weak MAReportDocument *blockReport = documentReport;
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                [blockReport performAsynchronousFileAccessUsingBlock:asyncBlock];
            }];
        } else {
            [documentReport performAsynchronousFileAccessUsingBlock:asyncBlock];
        }
    }
}

- (NSURL *)cachedFilesDirectory {
    return [MAReportDocument cacheFilesDirectoryForFilename:[self fileName]];
}

+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename {
    NSString *filenameId = [NSFileManager filenameId:[filename hash]];
    return [[NSFileManager defaultManager] cacheDirectoryNamed:filenameId];
}

@end
