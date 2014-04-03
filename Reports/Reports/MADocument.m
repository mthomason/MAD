//
//  MNSDocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

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

typedef void(^MTPerformAsynchronousFileAccessUsingBlock)(void);

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

@property (nonatomic, retain) NSFileWrapper *fileWrapper;
@property (nonatomic, retain) NSMutableDictionary *extraInformation;        //Structure for extra info
@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, assign) BOOL weMustSave;
@property (nonatomic, assign) BOOL quickSaveInProgress;

@end

@implementation MADocument

- (void)dealloc {
    [_extraInformation release];
    [_thumbnail release];
    [_fileWrapper release];
    [super dealloc];
}

- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {
        
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
        [extraInfo release];
                
    }
    return self;
}

/*
 {
    additionalContent =     {
        generator = "MAD Designer";
        "thumbnail.png" = "<UIImage: 0x1fea0b10>";
        version = 1;
    };
    fileType = "com.everydayapps.productivity.mad";
    parentContext = "<NSManagedObjectContext: 0x1f8bf550>";
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

/*- (BOOL)hasUnsavedChanges {
    BOOL result = NO;
    if ([self quickSaveInProgress] || [self isSuspended]) {
        result = NO;
    } else {
        if ([self weMustSave]) {
            result = YES;
        } else {
            result = [super hasUnsavedChanges];
        }
    }
    return result;
}*/

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    id result = [super contentsForType:typeName error:outError];
    [self setWeMustSave:NO];
    return result;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    [self setWeMustSave:NO];
    BOOL result = [super loadFromContents:contents ofType:typeName error:outError];
    return result;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    MTLog(@"UIManagedDocument error: %@", [error localizedDescription]);
    NSArray *errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if (errors != nil && errors.count > 0) {
        for (NSError *error in errors) {
            MTLog(@"  Error: %@", error.userInfo);
        }
    } else {
        MTLog(@"  %@", error.userInfo);
    }
}

- (NSString *)name {
    return [[[self fileURL] lastPathComponent] stringByDeletingPathExtension];
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
    return [[data retain] autorelease];
}

- (NSURL *)urlThumbnail {
    NSURL *fileurl = [self fileURL];
    NSURL *thumbnailUrl = [MAReportDocument thumbnailUrlForMadUrl:fileurl];
    return [[thumbnailUrl retain] autorelease];
}

- (NSURL *)urlMetaPlaylist {
    NSURL *fileurl = [self fileURL];
    NSURL *resultUrl = [fileurl URLByAppendingPathComponent:@"meta.plist"];
    return [[resultUrl retain] autorelease];
}

- (NSData *)thumbnailData {
    NSURL *thumbnailUrl = [self urlThumbnail];
    NSData *imageData = [MADocument dataForUrl:thumbnailUrl];
    return [[imageData retain] autorelease];
}

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error {
    
    NSData *imageData = [self thumbnailData];

    if (imageData != nil) {
        UIImage *image = [UIImage imageWithData: imageData];
        if (image != nil) {
            UIImage *extraImage = [[UIImage imageWithData:imageData] retain];
            NSString *key = [[MADocument thumbnailSaveName] retain];
            [[self extraInformation] setObject:extraImage
                                        forKey:key];
            [extraImage release];
        }
    }
    
    NSURL *metaUrl = [self urlMetaPlaylist];

    NSDictionary *dicionary = [NSDictionary dictionaryWithContentsOfURL:metaUrl];
    
    NSString *lastGenerator = [[dicionary objectForKey:MTDocumentInfoKeyGenerator] retain];
    if (lastGenerator == nil) {
        lastGenerator = [@"MAD Designer" retain];
    }
    
    [[self extraInformation] setObject:lastGenerator
                                forKey:MTDocumentInfoKeyGenerator];
    [lastGenerator release];

    NSNumber *lastVersion = [[dicionary objectForKey:MTDocumentInfoKeyGenerator] retain];
    if (lastVersion == nil) {
        lastVersion = [@(1.0) retain];
    }
    
    [[self extraInformation] setObject:lastVersion
                                forKey:MTDocumentInfoKeyVersion];
    [lastVersion release];

    return YES;
}

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError **)error {

    id result;

    if ([self isSuspended]) {
        result = [NSNull null];
    } else {
        if ([self extraInformation] == nil) {
            NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
            [self setExtraInformation:extraInfo];
            [extraInfo release];
        }
        NSNumber *dataVersion = @(1.0);
        [[self extraInformation] setObject:dataVersion forKey:MTDocumentInfoKeyVersion];
        [[self extraInformation] setObject:@"MAD Designer" forKey:MTDocumentInfoKeyGenerator];
        result = [[[self extraInformation] retain] autorelease];
    }

    return result;
}

- (BOOL)writeAdditionalContent:(id)content toURL:(NSURL *)absoluteURL originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error {

    BOOL writeAdditionalContent;
    
    if (content ==[NSNull null] || [self isSuspended]) {

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
    [self setWeMustSave:YES];
    if ([self managedObjectContext] != nil) {
        if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
            [[self managedObjectContext] save:nil]; //Try again!?!?!?!
        }
    }
}

- (void)quickSave {
    if ([self quickSaveInProgress] == NO) {
        [self setQuickSaveInProgress:YES];
        NSURL *url = [self fileURL];
        __block MADocument *blockSelf = self;
        [blockSelf saveToURL: url forSaveOperation: UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            
            [blockSelf setSuspended:YES];
            NSURL *url = [blockSelf fileURL];
            [NSFileManager wrapFile:url withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:YES completion:nil];
            [blockSelf setSuspended:NO];
            
            [blockSelf setQuickSaveInProgress:NO];
            
        }];
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
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&deleteError];
        if (deleteError != nil) {
            MTLog(@"%@", deleteError);
        }
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
    
    __block NSURL *blockFileUrl = fileUrl;
    MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
        NSError *deleteError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:blockFileUrl includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:-1 errorHandler:^BOOL(NSURL *url, NSError *error) {
            MTLog(@"Error %@", error);
            return YES;
        }];
        for (NSURL *blockFileUrl in enumerator) {
            NSError *error = nil;
            [fileManager removeItemAtURL:blockFileUrl error:&error];
            if (error != nil) {
                MTLog(@"Error %@", error);
            }
        }
        [fileManager removeItemAtURL:blockFileUrl error:&deleteError];
        if (deleteError != nil) {
            MTLog(@"%@", deleteError);
        }
        
        completion(YES);
    };
    
    MAReportDocument *documentReport = [[MAReportDocument alloc] initWithFileURL:fileUrl];
    BOOL properTypeToWrap = [[fileUrl pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive];
    if (properTypeToWrap) {
    
        if ([documentReport documentState] != UIDocumentStateClosed) {
            __block MAReportDocument *blockReport = documentReport;
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                [blockReport performAsynchronousFileAccessUsingBlock:asyncBlock];
            }];
        } else {
            [documentReport performAsynchronousFileAccessUsingBlock:asyncBlock];
        }
    }
    [documentReport release];
}

+ (void)deleteFromDiskQuick:(MAReportDocument *)documentReport completion:(void (^)(BOOL success))completion {
    
    NSURL *url = [documentReport fileURL];
    __block NSURL *blockFileUrl = url;
    
    MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
        NSError *deleteError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:blockFileUrl includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:-1 errorHandler:^BOOL(NSURL *url, NSError *error) {
            MTLog(@"Error %@", error);
            return YES;
        }];
        for (NSURL *blockFileUrl in enumerator) {
            NSError *error = nil;
            [fileManager removeItemAtURL:blockFileUrl error:&error];
            if (error != nil) {
                MTLog(@"Error %@", error);
            }
        }
        [[NSFileManager defaultManager] removeItemAtURL:blockFileUrl error:&deleteError];
        if (deleteError != nil) {
            MTLog(@"%@", deleteError);
        }
        
        completion(YES);
    };
    
    NSString *pathExtension = [url pathExtension];
    BOOL properTypeToWrap = [pathExtension isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive];
    if (properTypeToWrap) {
        
        if ([documentReport documentState] != UIDocumentStateClosed) {
            __block MAReportDocument *blockReport = documentReport;
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                [blockReport performAsynchronousFileAccessUsingBlock:asyncBlock];
            }];
        } else {
            [documentReport performAsynchronousFileAccessUsingBlock:asyncBlock];
        }
    }
}

@end
