//
//  CloudManager.m
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MACloudManager.h"
#import <UIKit/UIKit.h>
#import "MADMetadataQueryManager.h"
#import "MADMetaData.h"

#import "NSFileManager+Common.h"

NSString * const MTDocumentExtentionMobleApplicationDocumentArchive     = @"mada";
NSString * const MTDocumentExtentionMobleApplicationDocument            = @"mad";

NSString * const MTICloudUbiquityToken                                  = @"com.everydayapps.mad.designer.cloud.ubiquityIdentityToken";
NSString * const MADPreferencesCloudOptionsSelected                     = @"com.everydayapps.mad.designer.cloud.options.selected";

NSString * const MADNotificationFileManagerDidUpdateFileLocations       = @"MADNotificationFileManagerDidUpdateFileLocations";
NSString * const MADNotificationCloudStateUpdated                       = @"MADNotificationCloudStateUpdated";
NSString * const MADNotificationUbiquitousContainerFetchingWillBegin    = @"MADNotificationUbiquitousContainerFetchingWillBegin";
NSString * const MADNotificationUbiquitousContainerFetchingDidEnd       = @"MADNotificationUbiquitousContainerFetchingDidEnd";

NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyInserted    =   @"i";
NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyUpdated     =   @"u";
NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyRemoved     =   @"d";

#if MAD_DESIGNER == 1 || MAD_TEST == 1
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.designer";
#elif MAD_VIEWER == 1
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.viewer";
#endif

@interface MACloudManager ()
    <MADFileLocationManagerDelegate>

@property (nonatomic, strong, readwrite) NSURL *ubiquitousDocumentsDirectory;

@property (nonatomic, strong, readwrite) NSURL *ubiquityContainer;

@property (nonatomic, strong, readwrite) NSURL *localDataDirectory;
@property (nonatomic, strong, readwrite) NSURL *localDocumentDirectory;
@property (nonatomic, strong, readwrite) NSURL *localHomeDirectory;
@property (nonatomic, strong, readwrite) NSURL *localTemporaryDirectory;
@property (nonatomic, strong, readwrite) NSURL *localCachesDirectory;
@property (nonatomic, strong, readwrite) NSURL *localApplicationSupportDirectory;

@property (nonatomic, strong, readwrite) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

@property (nonatomic, strong, readwrite) MADMetadataQueryManager *fileLocationManager;

@property (atomic, assign) BOOL checkingCloudPreferencesLock;

@property (nonatomic, assign, readwrite) BOOL cloudAvailble;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong, readwrite) NSMutableArray       *documentCacheCloudMetaDataItems;
@property (nonatomic, strong, readwrite) NSMutableArray       *documentCacheLocalUrls;

@property (nonatomic, strong) NSArray       *fileNamesSortedLocal;
@property (nonatomic, strong) NSArray       *fileNamesSortedCloud;
@property (nonatomic, strong) NSArray       *fileNamesSortedCombined;

@end

@implementation MACloudManager

static MACloudManager *sharedSingleton;

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [NSMutableString new];
    
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquitousDocumentsDirectory)), self.ubiquitousDocumentsDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityContainer)), self.ubiquityContainer.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localDataDirectory)), self.localDataDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localDocumentDirectory)), self.localDocumentDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localHomeDirectory)), self.localHomeDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localTemporaryDirectory)), self.localTemporaryDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localCachesDirectory)), self.localCachesDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localApplicationSupportDirectory)), self.localApplicationSupportDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityIdentityToken)), self.ubiquityIdentityToken];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(fileLocationManager)), self.fileLocationManager];

    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(checkingCloudPreferencesLock)), self.checkingCloudPreferencesLock ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(cloudAvailble)), self.cloudAvailble ? @"YES" : @"NO"];
    
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(documentCacheCloudMetaDataItems)), self.documentCacheCloudMetaDataItems];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(documentCacheLocalUrls)), self.documentCacheLocalUrls];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(fileNamesSortedLocal)), self.fileNamesSortedLocal];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(fileNamesSortedCloud)), self.fileNamesSortedCloud];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(fileNamesSortedCombined)), self.fileNamesSortedCombined];
    
    
    return debuggingString;
}

- (id)init {
    if (self = [super init]) {
        
        NSMutableArray *documentCacheLocalUrls = [NSMutableArray new];
        self.documentCacheLocalUrls = documentCacheLocalUrls;
        
        NSMutableArray *documentCacheCloudMetaDataItems = [NSMutableArray new];
        self.documentCacheCloudMetaDataItems = documentCacheCloudMetaDataItems;
        
        //static dispatch_once_t onceToken;
        //dispatch_once(&onceToken, ^{
        //    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADPreferencesCloudOptionsSelected];
        //    [self resetForDebugging];
        //});
        
        self.searchString = @"";
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        
        self.fileManager = fileManager;
        
        NSString *homeDirectory = NSHomeDirectory();
        NSString *pathTemporaryDirectory = NSTemporaryDirectory();
        
        NSURL *homeDirectoryUrl = [NSURL fileURLWithPath: homeDirectory
                                             isDirectory: YES];
        
        NSURL *urlTemporaryDirectory = [NSURL fileURLWithPath: pathTemporaryDirectory
                                                  isDirectory: YES];
        
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        
        NSURL *cacheUrl = [NSURL fileURLWithPath: cachePaths.firstObject
                                     isDirectory: YES];
        
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSURL *docsUrl = [NSURL fileURLWithPath: docPaths.firstObject
                                    isDirectory: YES];
        
        MADMetadataQueryManager *fileLocationManager = [[MADMetadataQueryManager alloc] initWithPathExtension: MTDocumentExtentionMobleApplicationDocument];
        self.fileLocationManager = fileLocationManager;
        self.localHomeDirectory = homeDirectoryUrl;
        self.localTemporaryDirectory = urlTemporaryDirectory;
        self.localCachesDirectory = cacheUrl;
        self.localDocumentDirectory = docsUrl;
        self.checkingCloudPreferencesLock = NO;
        self.fileLocationManager.delegate = self;
        
    }
    return self;
}

+ (void)initialize {
    if (self == [MACloudManager self]) {
        MACloudManager *manager = [[MACloudManager alloc] init];
        sharedSingleton = manager;
    }
}

+ (void)load { }

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [super allocWithZone:zone];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (MACloudManager *)sharedManager {
    return sharedSingleton;
}

#pragma mark - NSNotification Handlers

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    
    id <NSObject, NSCopying, NSCoding> token = self.fileManager.ubiquityIdentityToken;
    if (token != nil) {
        
        NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject:token];
        [[NSUserDefaults standardUserDefaults] setObject: newTokenData
                                                  forKey: MTICloudUbiquityToken];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudStateUpdated
                                                            object: nil];
        
    } else {
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MTICloudUbiquityToken];
        
    }
    
}

#pragma mark - Exposed Methods

- (void)activate {
    
    [self reloadCacheLocal: @""];

    if (self.cloudAvailble) {
    
        [self reloadCacheCloud: @""];

        __weak MACloudManager *weakself = self;
        [self updateFileStorageContainerURL:^(void) {

            [weakself.fileLocationManager.metadataQuery startQuery];

        }];
        
    }

    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationFileManagerDidUpdateFileLocations
                                                        object: nil];
}

+ (NSArray *)madDocumentsLocal {
    return [self contentOfLocalDocumentsDirectoryWithExtention: MTDocumentExtentionMobleApplicationDocument];
}

+ (NSArray *)contentOfLocalDocumentsDirectoryWithExtention:(NSString *)extenstion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *directoryContents = [fm contentsOfDirectoryAtPath:docPaths.firstObject error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [docPaths.firstObject stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        if ([fm fileExistsAtPath:fileURL.path isDirectory:&isDirectory]) {
            NSString *pathExtension = [fileURL pathExtension];
            if ([pathExtension isEqualToString:extenstion]) {
                [result addObject:fileURL];
            }
        }
    }

    
    return result;
}

#pragma mark - Internal Methods

- (void)updateFileStorageContainerURL:(void (^)(void))completion {
    
    @synchronized (self) {
        
        self.localDataDirectory = nil;
        if (self.cloudAvailble) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationUbiquitousContainerFetchingWillBegin
                                                                object: nil];
            
            __weak MACloudManager *weakself = self;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                //This call may be SLOW, so only do on BACKGROUND thread.
                NSURL *url = [fileManager URLForUbiquityContainerIdentifier: MADUbiquityIdentifier];
                [weakself setDataAndDocumentUrlsWithBaseUrl:url];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationUbiquitousContainerFetchingDidEnd
                                                                        object: nil];
                    
                    if (completion) completion();
                    
                });
            });
        } else {
            [self setDataAndDocumentUrlsWithBaseUrl: self.localHomeDirectory];
            if (completion) completion();
        }
    }
}

- (void)setCloudEnabled: (BOOL)isCloudEnabled
             completion: (void (^)(void))completion {
    
    // Asynchronously update our data directory URL and documents directory URL
    // If we're enabling cloud storage, we move any local documents into the cloud container after the URLs are updated.
    
    if (isCloudEnabled != self.cloudAvailble) {    //if changed
        
        if (isCloudEnabled) {

            NSURL *oldDocumentsDirectoryURL = self.ubiquitousDocumentsDirectory != nil ?
                                                self.ubiquitousDocumentsDirectory : self.localDocumentDirectory;
            
            __weak MACloudManager *weakself = self;
            [self updateFileStorageContainerURL:^(void) {
                
                if (isCloudEnabled) {
                    
                    [weakself migrateFilesFromLocalDirectory: oldDocumentsDirectoryURL
                                           toRemoteDirectory: weakself.ubiquitousDocumentsDirectory
                                                  completion: ^{
                        if (completion) completion();
                    }];
                    
                } else {
                    if (completion) completion();
                }
            }];
            [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudStateUpdated
                                                                object: nil];
        } else {
            if (completion) completion();
        }
    } else {
        if (completion) completion();
    }
}

- (void)migrateFilesFromLocalDirectory: (NSURL *)localDirectory
                     toRemoteDirectory: (NSURL *)remoteDirectory
                            completion: (void (^)(void))completion {
    
    if (localDirectory && remoteDirectory) {

        NSDirectoryEnumerationOptions enumerationOptions = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                                                            NSDirectoryEnumerationSkipsPackageDescendants |
                                                            NSDirectoryEnumerationSkipsHiddenFiles;
        
        NSError *readDocumentsError = nil;
        
        NSArray *localDocuments = [self.fileManager contentsOfDirectoryAtURL: localDirectory
                                                    includingPropertiesForKeys: nil
                                                                       options: enumerationOptions
                                                                         error: &readDocumentsError];
        
        MACloudManager *weakself = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            for (NSURL *documentURL in localDocuments) {
                if ([documentURL.pathExtension isEqualToString: MTDocumentExtentionMobleApplicationDocument]) { // ???: MAD Files only
                    NSURL *destinationURL = [remoteDirectory URLByAppendingPathComponent:documentURL.lastPathComponent];
                    NSError *errorUpload = nil;
                    [weakself.fileManager setUbiquitous: YES
                                              itemAtURL: documentURL
                                         destinationURL: destinationURL
                                                  error: &errorUpload];
                    NSAssert(errorUpload != nil, @"%s %@", __PRETTY_FUNCTION__, errorUpload);
                }
            }
            if (completion) completion();
        });

    } else {
        if (completion) completion();
    }
}

#pragma Cloud

- (BOOL)cloudAvailble {
    return [self.fileManager ubiquityIdentityToken] != nil;
}

#pragma mark - MADFileLocationManagerDelegate

/* Only called on iCloud items. */

- (void)listCoordinatorDidUpdateContentsWithInsertedItems:(NSIndexSet *)insertedItems
                                             removedItems:(NSIndexSet *)removedItems
                                             updatedItems:(NSIndexSet *)updatedItems {
    
    [self reloadCacheCloud:self.searchString];
    NSDictionary *updates = @{
                              MADNotificationFileManagerDidUpdateFileLocationsKeyInserted : insertedItems,
                              MADNotificationFileManagerDidUpdateFileLocationsKeyUpdated : updatedItems,
                              MADNotificationFileManagerDidUpdateFileLocationsKeyRemoved : removedItems
                              };
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationFileManagerDidUpdateFileLocations
                                                        object: updates];
        
}

- (void)listCoordinatorDidFailRemovingListAtURL:(NSURL *)URL withError:(NSError *)error { }

- (void)listCoordinatorDidFailCreatingListAtURL:(NSURL *)URL withError:(NSError *)error { }

#pragma mark Prompts

- (void)promptCloudSignOut:(void (^)(void))completion {
    NSString *title = @"iCloud Sign-Out";
    NSString *message = @"You have signed out of the iCloud account previously used to store documents.  Sign back in to access those documents.";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    NSString *ok = @"Dismiss";
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: ^(UIAlertAction *action) {
                                                         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                                         [userDefaults setBool:NO forKey:MADPreferencesCloudOptionsSelected];
                                                         if (completion) completion();
                                                     }];
    [alertController addAction:actionKk];
    [((UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController).visibleViewController presentViewController: alertController
                                                                                                                                   animated: YES
                                                                                                                                 completion: nil];
}

#pragma mark File Helpers

- (void)createDirectoryIfDoesNotExist:(NSURL *)url {

    if ([self.fileManager fileExistsAtPath:url.path] == NO) {

        NSError *error = nil;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL: url
                                        options: 0
                                          error: &error
                                     byAccessor: ^(NSURL *newURL) {
                                         
                                         NSError *errorCreateNew = nil;
                                         [[NSFileManager defaultManager] createDirectoryAtPath: newURL.path
                                                                   withIntermediateDirectories: YES
                                                                                    attributes: nil
                                                                                         error: &errorCreateNew];
                                         
                                         NSAssert(errorCreateNew != nil, @"%s %@", __PRETTY_FUNCTION__, errorCreateNew);
                                     }];
        NSAssert(error != nil, @"%s %@", __PRETTY_FUNCTION__, error);
    }
}

- (BOOL)copyUrl: (NSURL *)urlToCopy
          toUrl: (NSURL *)uniqueUrl
     completion: (void (^)(BOOL, NSURL *, NSError *))completion {
    
    __block BOOL success = NO;
    NSError *error = nil;

    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    
    [coordinator coordinateReadingItemAtURL: urlToCopy
                                    options: NSFileCoordinatorReadingForUploading
                           writingItemAtURL: uniqueUrl
                                    options: NSFileCoordinatorWritingForMoving
                                      error: &error
                                 byAccessor: ^(NSURL *source, NSURL *destinaion) {
                                     
                                     NSError *errorCopy = nil;
                                     [coordinator itemAtURL:source didMoveToURL:destinaion];
                                     
                                     success = [[NSFileManager defaultManager] copyItemAtURL: source
                                                                                       toURL: destinaion
                                                                                       error: &errorCopy];
                                     NSAssert(errorCopy != nil, @"%s %@", __PRETTY_FUNCTION__, errorCopy);
                                     
                                     if (success) {
                                         [coordinator itemAtURL:source didMoveToURL:destinaion];
                                     }
                                     completion(success, uniqueUrl, error);
                                 }];
    return success;
}


- (BOOL)duplicateUrl: (NSURL *)urlToDupe
          completion: (void (^)(BOOL, NSURL *, NSError *))completion {

    __block BOOL success = NO;
    // FIXME: Make to work for ubiquity urls
    NSURL *directory = [urlToDupe URLByDeletingLastPathComponent];
    NSString *lastPathComponent = [urlToDupe lastPathComponent];
    NSString *handle = [lastPathComponent stringByDeletingPathExtension];
    NSString *extention = [lastPathComponent pathExtension];
    NSURL *uniqueUrl = [MACloudManager uniqueUrlInDirectory:directory
                                   withDesiredHandle:handle
                                        andExtension:extention];
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];

    NSError *error = nil;
    [coordinator coordinateReadingItemAtURL: urlToDupe
                                    options: NSFileCoordinatorReadingForUploading
                           writingItemAtURL: uniqueUrl
                                    options: NSFileCoordinatorWritingForMoving
                                      error: &error
                                 byAccessor: ^(NSURL *source, NSURL *destinaion) {
                                     
                                     NSError *errorCopy = nil;
                                     [coordinator itemAtURL:source didMoveToURL:uniqueUrl];
                                     
                                     success = [[NSFileManager defaultManager] copyItemAtURL: source
                                                                                            toURL: destinaion
                                                                                            error: &errorCopy];
                                     NSAssert(errorCopy != nil, @"%s %@", __PRETTY_FUNCTION__, errorCopy);
                                     
                                     if (success) {
                                         [coordinator itemAtURL:source didMoveToURL:uniqueUrl];
                                     }
                                     completion(success, uniqueUrl, error);
                                 }];
    return success;
 }

- (void)deleteDocument:(NSURL *)fileUrl completion:(void (^)(BOOL, NSError *))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL: fileUrl
                                            options: NSFileCoordinatorWritingForDeleting
                                              error: nil
                                         byAccessor: ^(NSURL* writingURL) {
            NSError *error = nil;
            NSFileManager* fileManager = [[NSFileManager alloc] init];
            if ([fileManager fileExistsAtPath:writingURL.path]) {
                [fileManager removeItemAtURL:writingURL error:&error];
                BOOL success = error ? NO : YES;
                if (completion) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        completion(success, error);
                    });
                }
            } else if (completion) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(YES, nil);
                });
            }
        }];
    });
}

- (BOOL)duplicateUrl:(NSURL *)urlToDupe {
    __block BOOL success = NO;
    
    // FIXME: Make to work for ubiquity urls
    NSURL *directory = [urlToDupe URLByDeletingLastPathComponent];
    NSString *lastPathComponent = [urlToDupe lastPathComponent];
    NSString *handle = [lastPathComponent stringByDeletingPathExtension];
    NSString *extention = [lastPathComponent pathExtension];
    NSURL *uniqueUrl = [MACloudManager uniqueUrlInDirectory:directory
                                 withDesiredHandle:handle
                                      andExtension:extention];
    
    NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL: urlToDupe
                                    options: NSFileCoordinatorReadingForUploading
                           writingItemAtURL: uniqueUrl
                                    options: NSFileCoordinatorWritingForMoving
                                      error: &error
                                 byAccessor: ^(NSURL *source, NSURL *destinaion) {
                                     
                                     NSError *errorCopy = nil;
                                     [coordinator itemAtURL:source didMoveToURL:uniqueUrl];
                                     
                                     success = [[NSFileManager defaultManager] copyItemAtURL: source
                                                                                       toURL: destinaion
                                                                                       error: &errorCopy];
                                     
                                     NSAssert(errorCopy != nil, @"%s %@", __PRETTY_FUNCTION__, errorCopy);
                                     
                                     if (success) {
                                         [coordinator itemAtURL:source didMoveToURL:uniqueUrl];
                                     }
                                 }];
    return success;
}


- (BOOL)deleteDocument:(NSURL *)fileUrl {
    __block BOOL success = NO;
    dispatch_semaphore_t semaphoreDelete = dispatch_semaphore_create(0);
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL: fileUrl
                                            options: NSFileCoordinatorWritingForDeleting
                                              error: nil
                                         byAccessor: ^(NSURL* writingURL) {
                                             NSError *error = nil;
                                             NSFileManager* fileManager = [NSFileManager defaultManager];
                                             if ([fileManager fileExistsAtPath:writingURL.path]) {
                                                 [fileManager removeItemAtURL:writingURL error:&error];
                                                 success = error ? NO : YES;
                                             }
                                             dispatch_semaphore_signal(semaphoreDelete);
                                         }];
    //});
    dispatch_semaphore_wait(semaphoreDelete, DISPATCH_TIME_FOREVER);
    return success;
}


- (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name
                          withExtension:(NSString *)extension
                            inContainer:(MACloudManagerSection)container {
    if (container == MACloudManagerSectionCloud) {
        return [MACloudManager uniqueUrlInDirectory: container == MACloudManagerSectionCloud ? self.ubiquitousDocumentsDirectory : self.localDocumentDirectory
                         withDesiredHandle: name
                              andExtension: extension];
    } else {
        return [MACloudManager uniqueUrlInDirectory: container == MACloudManagerSectionCloud ? self.ubiquitousDocumentsDirectory : self.localDocumentDirectory
                         withDesiredHandle: name
                              andExtension: extension];
    }
    
}

+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory withDesiredHandle:(NSString *)desiredFileHandle andExtension:(NSString *)extension {
    
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
    NSURL *applicationFileUrlWithExtention = [extension length] > 0 ?
    [baseUrl URLByAppendingPathExtension: extension] :
    baseUrl;
    NSInteger ctr = 0;
    BOOL isDir1;
    while ([defaultFileManager fileExistsAtPath:applicationFileUrlWithExtention.path isDirectory:&isDir1]) {
        
        NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
        NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
        applicationFileUrlWithExtention = [baseUrlFormatted URLByAppendingPathExtension: extension];
        ctr++;
    }
    return applicationFileUrlWithExtention;
    
}

- (void)moveDocument: (NSURL *)source
          toLocation: (NSURL *)destination
          completion: (void (^)(BOOL, NSError *))completion {

    NSError *coordinatorError = nil;
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    __block BOOL success = NO;
    [coordinator coordinateWritingItemAtURL: source
                                    options: NSFileCoordinatorWritingForMoving
                           writingItemAtURL: destination
                                    options: NSFileCoordinatorWritingForReplacing
                                      error: &coordinatorError
                                 byAccessor: ^(NSURL *newUrl1, NSURL *newUrl2) {
                                     
                                     [coordinator itemAtURL:source didMoveToURL:destination];
                                     
                                     NSError *fileManagerError = nil;
                                     success = [[NSFileManager defaultManager] moveItemAtURL: newUrl1
                                                                                       toURL: newUrl2
                                                                                       error: &fileManagerError];
                                     if (success) {
                                         [coordinator itemAtURL:source didMoveToURL:destination];
                                     } else {
                                         NSLog(@"%@", fileManagerError);
                                     }
                                     completion(success, fileManagerError);
                                 }];
}

- (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl {
    NSError *error = nil;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cachedDirectory = [defaultManager localCachedDirectoryForFileUrl:documentUrl];
    NSArray *contentsOfDirectoryAtUrlCachedDirectory = [defaultManager contentsOfDirectoryAtURL:cachedDirectory includingPropertiesForKeys:nil options:0 error:&error];
    for (NSURL *cachedFile in contentsOfDirectoryAtUrlCachedDirectory) {
        [defaultManager removeItemAtURL:cachedFile error:&error];
    }
    [defaultManager removeItemAtURL:cachedDirectory error:&error];
}

- (void)setDataAndDocumentUrlsWithBaseUrl:(NSURL *)url {
    self.ubiquityContainer = url;

    self.localDataDirectory = self.localTemporaryDirectory;
    
    NSURL *documentDirectory = [url URLByAppendingPathComponent:@"Documents"];
    [self createDirectoryIfDoesNotExist:documentDirectory];
    self.ubiquitousDocumentsDirectory = documentDirectory;
    
    if (self.cloudAvailble) {
        NSURL *dataDirectory = [url URLByAppendingPathComponent:@"Data"];
        [self createDirectoryIfDoesNotExist:dataDirectory];
    }

}

- (void)reloadDocumentCacheWithSearchString:(NSString *)searchString {

    [self reloadCacheCloud: searchString];
    [self reloadCacheLocal: searchString];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationFileManagerDidUpdateFileLocations
                                                        object: nil];
}

- (void)reloadCacheCloud:(NSString *)searchString {
/*    NSDictionary *documentCacheCloudMetaData = [NSDictionary dictionaryWithDictionary: self.fileLocationManager.results];
    
    NSArray *filteredDocumentCacheCloudMetaData;
    
    if (searchString.length > 0) {
        
        NSPredicate *predicateMetadata = [NSPredicate predicateWithBlock:^BOOL(MADMetaData *metadata, NSDictionary *bindings) {
            
            NSRange range = NSMakeRange(0, MIN(searchString.length, metadata.displayName.length));
            return [metadata.displayName compare: searchString
                                         options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                           range: range] == NSOrderedSame;
        }];
        
        filteredDocumentCacheCloudMetaData = [documentCacheCloudMetaData.allValues filteredArrayUsingPredicate:predicateMetadata];
        
    } else {
        
        filteredDocumentCacheCloudMetaData = documentCacheCloudMetaData.allValues;
    }

    NSString *displayName = NSStringFromSelector(@selector(displayName));
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey: displayName
                                                           ascending: YES
                                                            selector: @selector(localizedCaseInsensitiveCompare:)];
    NSArray *sorts = @[sort];
    
    NSArray *filteredDocumentCacheCloudMetaDataSorted = [filteredDocumentCacheCloudMetaData sortedArrayUsingDescriptors:sorts];*/
    self.documentCacheCloudMetaDataItems.array = [self documentsFilteredBySearchString:searchString];
}

- (NSArray *)documentsFilteredBySearchString:(NSString *)searchString {
    NSArray *result;
    if (searchString.length > 0) {

        NSPredicate *predicateMetadata = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *metadataWrapper, NSDictionary *bindings) {
            MADMetaData *metadata = metadataWrapper[MADKeyMetadataShort];
            NSRange range = NSMakeRange(0, MIN(searchString.length, metadata.displayName.length));
            return [metadata.displayName compare: searchString
                                         options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                           range: range] == NSOrderedSame;
        }];
        result = [self.fileLocationManager.metadata filteredArrayUsingPredicate:predicateMetadata];
    } else {
        result = self.fileLocationManager.metadata;
    }
    return [NSArray arrayWithArray:result];
}

- (void)reloadCacheLocal:(NSString *)searchString {
    // Setup local cache
    NSArray *documentCacheLocalUrls = [MACloudManager contentOfLocalDocumentsDirectoryWithExtention: MTDocumentExtentionMobleApplicationDocument];
    
    NSArray *filteredDocumentCacheLocalUrls;
    
    if (searchString.length > 0) {
        
        NSPredicate *predicateUrlSearch = [NSPredicate predicateWithBlock:^BOOL(NSURL *url, NSDictionary *bindings) {
            
            NSRange range = NSMakeRange(0, MIN(searchString.length, url.lastPathComponent.length));
            return [url.lastPathComponent compare: searchString
                                          options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                            range: range] == NSOrderedSame;
        }];
        
        filteredDocumentCacheLocalUrls = [documentCacheLocalUrls filteredArrayUsingPredicate:predicateUrlSearch];
        
    } else {
        
        filteredDocumentCacheLocalUrls = documentCacheLocalUrls;
    }
    

    NSString *lastPathComponent = NSStringFromSelector(@selector(lastPathComponent));
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey: lastPathComponent
                                                           ascending: YES
                                                            selector: @selector(localizedCaseInsensitiveCompare:)];
    NSArray *sorts = @[sort];
    self.documentCacheLocalUrls.array = [filteredDocumentCacheLocalUrls sortedArrayUsingDescriptors:sorts];

}

- (NSUInteger)numberOfDocuments:(MACloudManagerSection)section {

    switch (section) {

        case MACloudManagerSectionCloud:
            return self.documentCacheCloudMetaDataItems.count;
            break;
        
        case MACloudManagerSectionLocal:
            return self.documentCacheLocalUrls.count;
            break;
        
        default:
            return 0;
            break;
    }
    
}

- (MADMetaData *)metadataForItemAtLocation:(NSUInteger)location inSection:(MACloudManagerSection)section {
    NSDictionary *metadataDictionary;
    MADMetaData *metatdata = nil;
    id item = nil;

    switch (section) {
    
        case MACloudManagerSectionCloud:
            metadataDictionary = self.documentCacheCloudMetaDataItems[location];
            metatdata = metadataDictionary[MADKeyMetadataShort];
            break;
            
        case MACloudManagerSectionLocal:
            item = self.documentCacheLocalUrls[location];
            metatdata = [[MADMetaData alloc] initWithLocalUrl:item];
            break;
        
        default:
            metatdata = nil;
            break;

    }
    return metatdata;
}

#pragma mark File Name

+ (NSString *)filenameId:(NSUInteger)tag {
    return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention {
    return [[self filenameId:tag] stringByAppendingPathExtension:fileExtention];
}



@end
