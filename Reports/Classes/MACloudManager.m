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
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "NSThread+Extras.h"

NSString * const MTDocumentExtentionMobleApplicationDocumentArchive = @"mada";
NSString * const MTDocumentExtentionMobleApplicationDocument        = @"mad";

NSString * const MTICloudUbiquityToken                              = @"com.everydayapps.mad.designer.cloud.ubiquityIdentityToken";
NSString * const MADPreferencesCloudDesired                         = @"com.everydayapps.mad.designer.cloud.desired";
NSString * const MADPreferencesCloudOptionsSelected                 = @"com.everydayapps.mad.designer.cloud.options.selected";

NSString * const MADNotificationFileManagerDidUpdateFileLocations   = @"MADNotificationFileManagerDidUpdateFileLocations";

NSString * const MADNotificationCloudStateUpdated                     = @"ICloudStateUpdatedNotification";
NSString * const MADNotificationUbiquitousContainerFetchingWillBegin  = @"UbiquitousContainerFetchingWillBeginNotification";
NSString * const MADNotificationUbiquitousContainerFetchingDidEnd     = @"UbiquitousContainerFetchingDidEndNotification";

#if MAD_DESIGNER == 1 || MAD_TEST == 1
NSString * const MADUbiquityIdentifier                              = @"iCloud.com.everydayapps.mad.designer";
#elif MAD_VIEWER == 1
NSString * const MADUbiquityIdentifier                              = @"iCloud.com.everydayapps.mad.viewer";
#endif

@interface MACloudManager ()
    <MADFileLocationManagerDelegate>

@property (nonatomic, strong, readwrite) NSURL *ubiquityContainer;
@property (nonatomic, strong, readwrite) NSURL *dataDirectoryURL;
@property (nonatomic, strong, readwrite) NSURL *documentsDirectoryURL;

@property (nonatomic, strong, readwrite) NSURL *localDocumentDirectory;
@property (nonatomic, strong, readwrite) NSURL *localHomeDirectory;

@property (nonatomic, strong, readwrite) NSURL *localTemporaryDirectory;
@property (nonatomic, strong, readwrite) NSURL *cachesDirectory;
@property (nonatomic, strong, readwrite) NSURL *applicationSupport;

@property (nonatomic, strong, readwrite) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

@property (nonatomic, strong, readwrite) MADFileLocationManager *fileLocationManager;

@property (atomic, assign) BOOL checkingCloudPreferencesLock;

@property (nonatomic, assign, readwrite) BOOL cloudDesired;
@property (nonatomic, assign, readwrite) BOOL cloudAvailble;
@property (nonatomic, assign, readwrite) BOOL cloudOptionsPresentedAndSelectedByUser;

@property (nonatomic, strong) NSMutableSet *madUrls;

@property (nonatomic, strong, readwrite) NSFileCoordinator *fileCoordinator;
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation MACloudManager

static MACloudManager *sharedSingleton;

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [NSMutableString new];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(isCloudEnabled)), self.isCloudEnabled ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(cloudDesired)), self.cloudDesired ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(cloudAvailble)), self.cloudAvailble ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(cloudOptionsPresentedAndSelectedByUser)), self.cloudOptionsPresentedAndSelectedByUser ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityContainer)), self.ubiquityContainer];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(madUrls)), self.madUrls];
    return debuggingString;
}

+ (void)initialize {
    if (self == [MACloudManager self]) {
        MACloudManager *cm = [[MACloudManager alloc] init];
        sharedSingleton = cm;
    }
}

+ (void)load { }

- (void)resetForDebugging {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADPreferencesCloudDesired];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MTICloudUbiquityToken];
}

- (id)init {
    if (self = [super init]) {
        
        //static dispatch_once_t onceToken;
        //dispatch_once(&onceToken, ^{
        //    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADPreferencesCloudOptionsSelected];
        //    [self resetForDebugging];
        //});
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];

        self.fileManager = fileManager;
        self.fileCoordinator = fileCoordinator;
        
        NSMutableSet *madUrls = [NSMutableSet new];
        self.madUrls = madUrls;
        
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
        self.cachesDirectory = cacheUrl;
        self.localDocumentDirectory = docsUrl;
        self.checkingCloudPreferencesLock = NO;
        self.fileLocationManager.delegate = self;

    }
    return self;
}

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
    
    if ([self.fileManager ubiquityIdentityToken]) {
        if (self.isCloudEnabled) {
            [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudStateUpdated
                                                                object: nil];
        }
    }
    else {
        [self setCloudEnabled: NO completion:nil];
    }
    
}

#pragma mark - Exposed Methods

- (void)activate {
    [self updateFileStorageContainerURL:nil];
    [self startQuery];
}

- (void)stopQuery {
    if (self.isCloudEnabled) {
        [self.fileLocationManager stopQuery];
    }
}

- (void)startQuery {
    if (self.isCloudEnabled) {
        
        __weak MACloudManager *weakself = self;
        [NSThread safeSwitchToMainThread:^{
            [weakself.fileLocationManager startQuery];
        }];
        
    }
}

- (void)checkUserICloudPreferenceAndSetupIfNecessary:(void (^)(void))completion {
    
    if (self.checkingCloudPreferencesLock == NO) {
        self.checkingCloudPreferencesLock = YES;    //Set to no on completion

        // Check to see whether the user has previously selected the iCloud storage option.
        // If so, check the iCloud storage state from previous launch.
        // If the user has previously chosen to use iCloud and we're still signed in, setup the CloudManager with cloud storage enabled.
        // If no user choice is recorded, use a UIAlert to fetch the user's preference.
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        id <NSObject, NSCopying, NSCoding> ubiquityIdentityTokenCurrent = [self.fileManager ubiquityIdentityToken];
        NSData *oldTokenData = [userDefaults objectForKey:MTICloudUbiquityToken];
        id <NSObject, NSCopying, NSCoding> ubiquityIdentityTokenLastLaunch = oldTokenData ? [NSKeyedUnarchiver unarchiveObjectWithData:oldTokenData] : nil;
        
        BOOL cloudOptionsDisplayed = [userDefaults boolForKey:MADPreferencesCloudOptionsSelected];
        BOOL cloudDesired = cloudOptionsDisplayed && [userDefaults boolForKey:MADPreferencesCloudDesired];
        BOOL cloudAvailble = ubiquityIdentityTokenCurrent != nil;
        BOOL cloudPreviousllyAccessedWithDifferentToken = ubiquityIdentityTokenLastLaunch != nil &&
                                                            ![ubiquityIdentityTokenLastLaunch isEqual:ubiquityIdentityTokenCurrent];
        
        __weak MACloudManager *weakself = self;

        // Step 1: Ask user if they would like to use iCloud
        if (cloudAvailble && cloudOptionsDisplayed == NO) {
            
            [self promptCloudDesired:^(BOOL desired) {
                [[MACloudManager sharedManager] setCloudEnabled:desired completion:^{
                    weakself.checkingCloudPreferencesLock = NO;
                    if (completion) completion();
                }];
            }];
            
            // Step 2: Detect switching to another account or deleting iCloud entirely
            
        } else if (cloudDesired && cloudPreviousllyAccessedWithDifferentToken) {
            
            [self promptCloudSignOut:^{
                [[MACloudManager sharedManager] setCloudEnabled:NO completion:^{
                    weakself.checkingCloudPreferencesLock = NO;
                    if (completion) completion();
                }];
            }];

        } else {
            
            // Step 3: Setup cloud manager based of desire and availability
            [self setCloudEnabled: cloudDesired && cloudAvailble completion:^{
                weakself.checkingCloudPreferencesLock = NO;
                if (completion) completion();
            }];
            
        }
        
        // Step 4: If logged out of iCloud, reset the promopt that ask them if they would like to use iCloud
        if (cloudAvailble == NO) {
            [self resetForDebugging];
        } else {
            NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject:ubiquityIdentityTokenCurrent];
            [userDefaults setObject: newTokenData
                             forKey: MTICloudUbiquityToken];
        }
    }
}

- (NSArray *)hasMadDocuments {
    NSSet *madFiles = [self contentsOfDocumentsDirectoryWithPathExtension: MTDocumentExtentionMobleApplicationDocument];
    SEL selectorPath = @selector(path);
    SEL selectorSort = @selector(localizedStandardCompare:);
    NSString *key = NSStringFromSelector(selectorPath);
    NSSortDescriptor *sortByFileName = [NSSortDescriptor sortDescriptorWithKey:key ascending:YES selector:selectorSort];
    NSArray *sortDescriptors = @[sortByFileName];
    return [madFiles sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension {
    [self.fileLocationManager startQuery];
    
    NSMutableSet *result = [[NSMutableSet alloc] init];
    if (self.isCloudEnabled) {
        [result addObjectsFromArray:self.madUrls.allObjects];
    } else {
        NSError *error = nil;
        NSFileManager *fm = self.fileManager;
        NSArray *directoryContents = [fm contentsOfDirectoryAtPath:self.documentsDirectoryURL.path error:&error];
        for (NSString *filename in directoryContents) {
            NSString *fullPath = [self.documentsDirectoryURL.path stringByAppendingPathComponent:filename];
            NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
            BOOL isDirectory;
            if ([fm fileExistsAtPath:fileURL.path isDirectory:&isDirectory]) {
                NSString *pathExtension = [fileURL pathExtension];
                if ([pathExtension isEqualToString:extension]) {
                    [result addObject:fileURL];
                }
            }
        }
    }
    
    return result;
}

#pragma mark - Internal Methods

- (void)updateFileStorageContainerURL:(void (^)(void))completion {
    
    @synchronized (self) {
        
        self.dataDirectoryURL = nil;
        if (self.isCloudEnabled) {
            
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
    
    if (isCloudEnabled != self.isCloudEnabled) {    //if changed
        
        if ((self.cloudDesired = isCloudEnabled)) {
            [[NSUserDefaults standardUserDefaults] setBool: YES
                                                    forKey: MADPreferencesCloudDesired];
            
            NSURL *oldDocumentsDirectoryURL = self.documentsDirectoryURL != nil ?
                                                self.documentsDirectoryURL : self.localDocumentDirectory;
            
            __weak MACloudManager *weakself = self;
            [self updateFileStorageContainerURL:^(void) {
                
                if (isCloudEnabled) {
                    
                    [weakself migrateFilesFromLocalDirectory: oldDocumentsDirectoryURL
                                           toRemoteDirectory: weakself.documentsDirectoryURL
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

- (BOOL)cloudDesired {
    return [[NSUserDefaults standardUserDefaults] boolForKey:MADPreferencesCloudDesired];
}

- (BOOL)cloudAvailble {
    return [self.fileManager ubiquityIdentityToken] != nil;
}

- (BOOL)isCloudEnabled {
    return self.cloudAvailble && self.cloudDesired;
}

- (BOOL)cloudOptionsPresentedAndSelectedByUser {
    return [[NSUserDefaults standardUserDefaults] boolForKey:MADPreferencesCloudOptionsSelected];
}

#pragma mark - MADFileLocationManagerDelegate

- (void)listCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs
                                             removedURLs:(NSArray *)removedURLs
                                             updatedURLs:(NSArray *)updatedURLs {
    // FIXME: Don't think this should run if cloud is not desired by the user, but it is, so short
    //          it, but we can do better!!!
    if (self.isCloudEnabled) {
        
        [self.madUrls addObjectsFromArray:insertedURLs];
        
        for (NSURL *url in removedURLs) {
            [self.madUrls removeObject:url];
        }

        if (insertedURLs.count > 0 || removedURLs.count > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationFileManagerDidUpdateFileLocations
                                                                object: nil];
        }
    }
}

- (void)listCoordinatorDidFailRemovingListAtURL:(NSURL *)URL withError:(NSError *)error {
    
}

- (void)listCoordinatorDidFailCreatingListAtURL:(NSURL *)URL withError:(NSError *)error {
    
}

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

- (void)promptCloudDesired:(void (^)(BOOL desired))completion {
    NSString *title = @"Choose Storage Option";
    NSString *message = @"Should documents be stored in iCloud or on just this device?";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    
    NSString *ok = @"iCloud";
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: ^(UIAlertAction *action) {
                                                         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                                         [userDefaults setBool:YES forKey:MADPreferencesCloudOptionsSelected];
                                                         completion(YES);
                                                     }];
    
    NSString *localOnly = @"Local only";
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: localOnly
                                                           style: UIAlertActionStyleCancel
                                                         handler: ^(UIAlertAction *action) {
                                                             NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                                             [userDefaults setBool:YES forKey:MADPreferencesCloudOptionsSelected];
                                                             completion(NO);
                                                         }];
    
    [alertController addAction:actionKk];
    [alertController addAction:actionCancel];
    
    [((UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController).visibleViewController  presentViewController: alertController
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

- (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension {
    return [NSURL uniqueUrlInDirectory: self.documentsDirectoryURL
                     withDesiredHandle: name
                          andExtension: extension];
}

- (void)moveDocument:(NSURL *)source
          toLocation:(NSURL *)destination {

    NSError *coordinatorError = nil;
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    __block BOOL success = NO;
    [coordinator coordinateWritingItemAtURL:source
                                    options:NSFileCoordinatorWritingForMoving
                           writingItemAtURL:destination
                                    options:NSFileCoordinatorWritingForReplacing
                                      error:&coordinatorError
                                 byAccessor:^(NSURL *coordinatedSource, NSURL *coordinatedDestination) {
                                     
                                     if ([[NSFileManager defaultManager] fileExistsAtPath: coordinatedDestination.path] == NO) {
                                         
                                         NSError *fileManagerError = nil;
                                         success = [[NSFileManager defaultManager] moveItemAtURL: coordinatedSource
                                                                                                toURL: coordinatedDestination
                                                                                                error: &fileManagerError];
                                         
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
    
    if (self.isCloudEnabled) {
        NSURL *dataDirectory = [url URLByAppendingPathComponent:@"Data"];
        [self createDirectoryIfDoesNotExist:dataDirectory];
        self.dataDirectoryURL = dataDirectory;
    } else {
        self.dataDirectoryURL = self.localTemporaryDirectory;
    }
    
    NSURL *documentDirectory = [url URLByAppendingPathComponent:@"Documents"];
    [self createDirectoryIfDoesNotExist:documentDirectory];
    self.documentsDirectoryURL = documentDirectory;
    
}

@end
