//
//  CloudManager.m
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MACloudManager.h"
#import <UIKit/UIKit.h>
#import "MADFileLocationManager.h"
#import "MADMetaData.h"
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "NSThread+Extras.h"

NSString * const MTDocumentExtentionMobleApplicationDocumentArchive     = @"mada";
NSString * const MTDocumentExtentionMobleApplicationDocument            = @"mad";

NSString * const MTICloudUbiquityToken                                  = @"com.everydayapps.mad.designer.cloud.ubiquityIdentityToken";
NSString * const MADPreferencesCloudOptionsSelected                     = @"com.everydayapps.mad.designer.cloud.options.selected";

NSString * const MADNotificationFileManagerDidUpdateFileLocations       = @"MADNotificationFileManagerDidUpdateFileLocations";

NSString * const MADNotificationCloudStateUpdated                       = @"ICloudStateUpdatedNotification";
NSString * const MADNotificationUbiquitousContainerFetchingWillBegin    = @"UbiquitousContainerFetchingWillBeginNotification";
NSString * const MADNotificationUbiquitousContainerFetchingDidEnd       = @"UbiquitousContainerFetchingDidEndNotification";

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

@property (nonatomic, strong, readwrite) MADFileLocationManager *fileLocationManager;

@property (atomic, assign) BOOL checkingCloudPreferencesLock;

@property (nonatomic, assign, readwrite) BOOL cloudAvailble;

@property (nonatomic, strong, readwrite) NSFileCoordinator *fileCoordinator;
@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, assign) NSUInteger    documentCacheCloudCount;
@property (nonatomic, assign) NSUInteger    documentCacheLocalCount;

@property (nonatomic, strong) NSArray       *documentCacheCloudMetaDataItems;
@property (nonatomic, strong) NSArray       *documentCacheLocalUrls;

@property (nonatomic, strong) NSArray       *fileNamesSortedLocal;
@property (nonatomic, strong) NSArray       *fileNamesSortedCloud;
@property (nonatomic, strong) NSArray       *fileNamesSortedCombined;

@end

@implementation MACloudManager

static MACloudManager *sharedSingleton;

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [NSMutableString new];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(cloudAvailble)), self.cloudAvailble ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityContainer)), self.ubiquityContainer];
    return debuggingString;
}

- (id)init {
    if (self = [super init]) {
        
        //static dispatch_once_t onceToken;
        //dispatch_once(&onceToken, ^{
        //    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADPreferencesCloudOptionsSelected];
        //    [self resetForDebugging];
        //});
        
        self.searchString = @"";
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        
        self.fileManager = fileManager;
        self.fileCoordinator = fileCoordinator;
        
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
        
        MADFileLocationManager *fileLocationManager = [[MADFileLocationManager alloc] initWithPathExtension: MTDocumentExtentionMobleApplicationDocument];
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

+ (MACloudManager*)sharedManager {
    return sharedSingleton;
}

#pragma mark - NSNotification Handlers

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    
    id <NSObject, NSCopying, NSCoding> token = self.fileManager.ubiquityIdentityToken;
    if (token != nil) {
        
        NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject:token];
        [[NSUserDefaults standardUserDefaults] setObject: newTokenData forKey: MTICloudUbiquityToken];
        
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

- (NSArray *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension {

    [self.fileLocationManager startQuery];
    NSArray *result;
    if (self.cloudAvailble) {
        NSArray *r = [self.fileLocationManager calculatedUrls];
        result = [NSArray arrayWithArray:r];
    } else {
        NSArray *r = [self contentOfLocalDocumentsDirectoryWithExtention:extension];
        result  = [NSArray arrayWithArray:r];
    }
    
    return result;
}

- (NSArray *)contentOfLocalDocumentsDirectoryWithExtention:(NSString *)extenstion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSError *error = nil;
    NSFileManager *fm = self.fileManager;
    NSArray *directoryContents = [fm contentsOfDirectoryAtPath:self.localDocumentDirectory.path error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [self.localDocumentDirectory.path stringByAppendingPathComponent:filename];
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
                
                //This call may be SLOW, so only do on BACKGROUND thread.
                NSURL *url = [self.fileManager URLForUbiquityContainerIdentifier: MADUbiquityIdentifier];
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

- (void)listCoordinatorDidUpdateContentsWithInsertedItems:(NSIndexSet *)insertedItems
                                             removedItems:(NSIndexSet *)removedItems
                                             updatedItems:(NSIndexSet *)updatedItems {

    [self reloadCacheCloud:self.searchString];
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationFileManagerDidUpdateFileLocations
                                                        object: nil];
        
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

#pragma mark File Name

+ (NSString *)filenameId:(NSUInteger)tag {
    return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention {
    return [[self filenameId:tag] stringByAppendingPathExtension:fileExtention];
}

#pragma mark File Helpers

- (void)createDirectoryIfDoesNotExist:(NSURL *)url {

    if ([self.fileManager fileExistsAtPath:url.path] == NO) {

        NSError *error = nil;
        [self.fileCoordinator coordinateWritingItemAtURL: url
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

- (NSURL *)duplicateUrl:(NSURL *)urlToDupe {
    // FIXME: Make to work for ubiquity urls
    NSURL *directory = [urlToDupe URLByDeletingLastPathComponent];
    NSString *lastPathComponent = [urlToDupe lastPathComponent];
    NSString *handle = [lastPathComponent stringByDeletingPathExtension];
    NSString *extention = [lastPathComponent pathExtension];
    NSURL *uniqueUrl = [NSURL uniqueUrlInDirectory:directory
                                 withDesiredHandle:handle
                                      andExtension:extention];
    NSError *error = nil;
    [self.fileCoordinator coordinateReadingItemAtURL: urlToDupe
                                             options: NSFileCoordinatorReadingForUploading
                                    writingItemAtURL: uniqueUrl
                                             options: NSFileCoordinatorWritingForMoving
                                               error: &error
                                          byAccessor: ^(NSURL *source, NSURL *destinaion) {
                                            
                                              NSError *errorCopy = nil;
                                              [[NSFileManager defaultManager] copyItemAtURL: source
                                                                                      toURL: destinaion
                                                                                      error: &errorCopy];
                                              NSAssert(errorCopy != nil, @"%s %@", __PRETTY_FUNCTION__, errorCopy);
                                          }];
    
    
    return uniqueUrl;
}

- (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name
                          withExtension:(NSString *)extension
                            inContainer:(MACloudManagerSection)container {
    
    return [NSURL uniqueUrlInDirectory: container == MACloudManagerSectionCloud ? self.ubiquitousDocumentsDirectory : self.localDocumentDirectory
                     withDesiredHandle: name
                          andExtension: extension];
    
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
                                 byAccessor: ^(NSURL *coordinatedSource, NSURL *coordinatedDestination) {
                                     
                                     if ([[NSFileManager defaultManager] fileExistsAtPath: coordinatedDestination.path] == NO) {
                                         
                                         NSError *fileManagerError = nil;
                                         success = [[NSFileManager defaultManager] moveItemAtURL: coordinatedSource
                                                                                           toURL: coordinatedDestination
                                                                                           error: &fileManagerError];
                                         completion(success, fileManagerError);
                                     } else {
                                         NSDictionary *userinfo = @{};
                                         NSError *error = [NSError errorWithDomain:@"MADCloudManager" code:43789 userInfo:userinfo];
                                         completion(NO, error);
                                     }

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
    NSDictionary *documentCacheCloudMetaData = [NSDictionary dictionaryWithDictionary: self.fileLocationManager.results];
    
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
    
    self.documentCacheCloudMetaDataItems = filteredDocumentCacheCloudMetaData;
    self.documentCacheCloudCount = filteredDocumentCacheCloudMetaData.count;
}

- (void)reloadCacheLocal:(NSString *)searchString {
    // Setup local cache
    NSArray *documentCacheLocalUrls = [self contentOfLocalDocumentsDirectoryWithExtention: MTDocumentExtentionMobleApplicationDocument];
    
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
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:lastPathComponent ascending:NO];
    NSArray *sorts = @[sort];
    self.documentCacheLocalUrls = [filteredDocumentCacheLocalUrls sortedArrayUsingDescriptors:sorts];
    self.documentCacheLocalCount = filteredDocumentCacheLocalUrls.count;

}

- (NSUInteger)numberOfDocuments:(MACloudManagerSection)section {

    switch (section) {

        case MACloudManagerSectionCloud:
            return self.documentCacheCloudCount;
            break;
        
        case MACloudManagerSectionLocal:
            return self.documentCacheLocalCount;
            break;
        
        default:
            return 0;
            break;
    }
    
}

- (MADMetaData *)metadataForItemAtLocation:(NSUInteger)location inSection:(MACloudManagerSection)section {

    MADMetaData *metatdata = nil;
    id item = nil;

    switch (section) {
    
        case MACloudManagerSectionCloud:
            metatdata = self.documentCacheCloudMetaDataItems[location];
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

@end
