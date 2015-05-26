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

NSString * const MTICloudUbiquityToken                                  = @"com.everydayapps.mad.designer.cloud.ubiquityIdentityToken";
NSString * const MADPreferencesCloudOptionsSelected                     = @"com.everydayapps.mad.designer.cloud.options.selected";

NSString * const MADNotificationCloudStateUpdated                       = @"MADNotificationCloudStateUpdated";
NSString * const MADNotificationUbiquitousContainerFetchingWillBegin    = @"MADNotificationUbiquitousContainerFetchingWillBegin";
NSString * const MADNotificationUbiquitousContainerFetchingDidEnd       = @"MADNotificationUbiquitousContainerFetchingDidEnd";

@interface MACloudManager ()

@property (nonatomic, strong, readwrite) NSURL *ubiquitousDocumentsDirectory;
@property (nonatomic, strong, readwrite) NSURL *ubiquityContainer;
@property (nonatomic, strong, readwrite) NSURL *localDocumentDirectory;
@property (nonatomic, strong, readwrite) NSURL *localHomeDirectory;
@property (nonatomic, strong, readwrite) NSURL *localCachesDirectory;
@property (nonatomic, strong, readwrite) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

@property (nonatomic, strong, readwrite) MADMetadataQueryManager *fileLocationManager;

@property (atomic, assign) BOOL checkingCloudPreferencesLock;

@property (nonatomic, strong, readwrite) NSMutableArray       *documentCacheCloudMetaDataItems;
@property (nonatomic, strong, readwrite) NSMutableArray       *documentCacheLocalUrls;

@end

@implementation MACloudManager

static MACloudManager *sharedSingleton;

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [NSMutableString new];
    
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquitousDocumentsDirectory)), self.ubiquitousDocumentsDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityContainer)), self.ubiquityContainer.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localDocumentDirectory)), self.localDocumentDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localHomeDirectory)), self.localHomeDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(localCachesDirectory)), self.localCachesDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityIdentityToken)), self.ubiquityIdentityToken];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(fileLocationManager)), self.fileLocationManager];

    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(checkingCloudPreferencesLock)), self.checkingCloudPreferencesLock ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", @"isCloudAvailable", [MACloudManager isCloudAvailable] ? @"YES" : @"NO"];
    
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(documentCacheCloudMetaDataItems)), self.documentCacheCloudMetaDataItems];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(documentCacheLocalUrls)), self.documentCacheLocalUrls];
    
    return debuggingString;
}

- (id)init {
    if (self = [super init]) {
        
        NSMutableArray *documentCacheLocalUrls = [NSMutableArray new];
        self.documentCacheLocalUrls = documentCacheLocalUrls;
        
        NSMutableArray *documentCacheCloudMetaDataItems = [NSMutableArray new];
        self.documentCacheCloudMetaDataItems = documentCacheCloudMetaDataItems;
        
        self.searchString = @"";
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

/*#pragma mark - NSNotification Handlers

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    
    id <NSObject, NSCopying, NSCoding> token = [NSFileManager defaultManager].ubiquityIdentityToken;
    if (token != nil) {
        
        NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject:token];
        [[NSUserDefaults standardUserDefaults] setObject: newTokenData
                                                  forKey: MTICloudUbiquityToken];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudStateUpdated
                                                            object: nil];
        
    } else {
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MTICloudUbiquityToken];
        
    }
    
}*/

#pragma mark - Internal Methods

+ (void)handleLongRunningCloudUrlLookup:(NSTimer *)timer {
    if(timer.userInfo) {
        void (^block)() = (void (^)())timer.userInfo;
        block();
    }
}

+ (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                     groupIdentifier: (NSString *)groupIdentifier
                                               delay: (void (^)())handleLongRunningCall
                                          completion: (void (^)(BOOL cloudAvailable, NSURL *documents, NSURL *data))handleCompletion {
    
        if ([MACloudManager isCloudAvailable]) {
            void (^longRunningCallBlock)() = [handleLongRunningCall copy];
            [NSTimer timerWithTimeInterval: (NSTimeInterval)0.5000
                                    target: self
                                  selector: @selector(handleLongRunningCloudUrlLookup:)
                                  userInfo: longRunningCallBlock
                                   repeats: NO];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                //This call may be SLOW, so only do on BACKGROUND thread.
                //NSString *ubiquityIdentifier = [self.delegateApplication ubiquityIdentifier];
                
                NSURL *ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier: ubiquityIdentifier];
                
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                
                    NSURL *documentDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Documents"];
                    NSURL *dataDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Data"];
                    [fileManager coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
                    [fileManager coordinateCreateDirectoryIfDoesNotExist:dataDirectory];

                    if (handleCompletion) handleCompletion(YES, documentDirectory, dataDirectory);
                    
                });
            });
        } else {
            NSURL *documents = [[NSFileManager defaultManager] localDataDirectoryForGroupIdentifier:groupIdentifier];
            NSURL *data = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
            if (handleCompletion) handleCompletion(NO, documents, data);
        }
 
}

- (void)updateFileStorageContainerURL:(void (^)(void))completion {
    
    @synchronized (self) {
        
        if ([MACloudManager isCloudAvailable]) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationUbiquitousContainerFetchingWillBegin
                                                                object: nil];
            
            __weak MACloudManager *weakself = self;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                //This call may be SLOW, so only do on BACKGROUND thread.
                NSString *ubiquityIdentifier = [self.delegateApplication ubiquityIdentifier];
                
                NSURL *url = [fileManager URLForUbiquityContainerIdentifier: ubiquityIdentifier];
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

#pragma Cloud

+ (BOOL)isCloudAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

#pragma mark - MADFileLocationManagerDelegate

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error { }

- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error { }

#pragma mark Prompts

+ (UIAlertController *)alertControllerPromotCloudSignOut:(void (^)(UIAlertAction *action))handler {
    NSString *title = @"iCloud Sign-Out";
    NSString *message = @"You have signed out of the iCloud account previously used to store documents.  Sign back in to access those documents.";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    NSString *ok = @"Dismiss";
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: handler];
    [alertController addAction:actionKk];
    return alertController;
}

- (void)promptCloudSignOut:(void (^)(void))completion {

    UIAlertController *alertController = [MACloudManager alertControllerPromotCloudSignOut: ^(UIAlertAction *action) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:NO forKey:MADPreferencesCloudOptionsSelected];
        if (completion) completion();
    }];
    [((UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController).visibleViewController presentViewController: alertController
                                                                                                                                   animated: YES
                                                                                                                                 completion: nil];
}

#pragma mark File Helpers

- (void)createDirectoryIfDoesNotExist:(NSURL *)url {

    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path] == NO) {

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
                                         
                                         NSAssert(errorCreateNew == nil, @"%s %@", __PRETTY_FUNCTION__, errorCreateNew);
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
                                    options: NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL: uniqueUrl
                                    options: NSFileCoordinatorWritingForMoving
                                      error: &error
                                 byAccessor: ^(NSURL *source, NSURL *destinaion) {
                                     
                                     NSError *errorCopy = nil;
                                     [coordinator itemAtURL:source didMoveToURL:destinaion];
                                     
                                     success = [[NSFileManager defaultManager] copyItemAtURL: source
                                                                                       toURL: destinaion
                                                                                       error: &errorCopy];
                                     NSAssert(errorCopy == nil, @"%s %@", __PRETTY_FUNCTION__, errorCopy);
                                     
                                     if (success) {
                                         [coordinator itemAtURL:source didMoveToURL:destinaion];
                                     }
                                     completion(success, uniqueUrl, error);
                                 }];
    return success;
}

+ (BOOL)duplicateUrl:(NSURL *)urlToDupe {
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
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    [coordinator coordinateReadingItemAtURL: urlToDupe
                                    options: NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL: uniqueUrl
                                    options: NSFileCoordinatorWritingForMoving
                                      error: &error
                                 byAccessor: ^(NSURL *source, NSURL *destinaion) {
                                     
                                     NSError *errorCopy = nil;
                                     success = [[NSFileManager defaultManager] copyItemAtURL: source
                                                                                       toURL: destinaion
                                                                                       error: &errorCopy];
                                     
                                     NSAssert(errorCopy == nil, @"%s %@", __PRETTY_FUNCTION__, errorCopy);
                                     
                                     if (success) {
                                         [coordinator itemAtURL:source didMoveToURL:uniqueUrl];
                                     }
                                 }];
    return success;
}

+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}

- (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name
                          withExtension:(NSString *)extension
                            inContainer:(MACloudManagerSection)container {
    return [MACloudManager uniqueUrlInDirectory: container == MACloudManagerSectionCloud ? self.ubiquitousDocumentsDirectory : self.localDocumentDirectory
                              withDesiredHandle: name
                                   andExtension: extension];
}

+ (NSURL *)uniqueURLForURL:(NSURL *)url {
    return [MACloudManager uniqueUrlInDirectory: url.URLByDeletingLastPathComponent
                              withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
                                   andExtension: url.lastPathComponent.pathExtension];
}

+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory
              withDesiredHandle:(NSString *)desiredFileHandle
                   andExtension:(NSString *)extension {
    
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
    NSURL *fileUrl = extension.length > 0 ?
                        [baseUrl URLByAppendingPathExtension: extension] :
                        baseUrl;
    NSInteger ctr = 0;
    BOOL isDir1;
    while ([defaultFileManager fileExistsAtPath:fileUrl.path isDirectory:&isDir1] || [defaultFileManager isUbiquitousItemAtURL:fileUrl]) {
        
        NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
        NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
        fileUrl = [baseUrlFormatted URLByAppendingPathExtension: extension];
        ctr++;
    }
    return fileUrl;
    
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
                                     
                                     NSError *fileManagerError = nil;
                                     success = [[NSFileManager defaultManager] moveItemAtURL: newUrl1
                                                                                       toURL: newUrl2
                                                                                       error: &fileManagerError];
                                     if (success) {
                                         [coordinator itemAtURL:source didMoveToURL:destination];
                                     }
                                     
                                     completion(success, fileManagerError);
                                 }];
}

- (void)setDataAndDocumentUrlsWithBaseUrl:(NSURL *)url {
    self.ubiquityContainer = url;

    
    NSURL *documentDirectory = [url URLByAppendingPathComponent:@"Documents"];
    [self createDirectoryIfDoesNotExist:documentDirectory];
    self.ubiquitousDocumentsDirectory = documentDirectory;
    
    if ([MACloudManager isCloudAvailable]) {
        NSURL *dataDirectory = [url URLByAppendingPathComponent:@"Data"];
        [self createDirectoryIfDoesNotExist:dataDirectory];
    }

}

- (void)reloadCacheCloud:(NSString *)searchString {
    self.documentCacheCloudMetaDataItems.array = [self documentsFilteredBySearchString:searchString];
}

- (NSArray *)documentsFilteredBySearchString:(NSString *)searchString {
    NSArray *result;
    if (searchString.length > 0) {

        NSPredicate *predicateMetadata = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *metadataWrapper, NSDictionary *bindings) {
            MADMetaData *metadata = metadataWrapper[MADKeyMetadataShort];
            NSRange range = NSMakeRange(0, MIN(searchString.length, metadata.name.length));
            return [metadata.name compare: searchString
                                         options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                           range: range] == NSOrderedSame;
        }];
        result = [self.fileLocationManager.metadata filteredArrayUsingPredicate:predicateMetadata];
    } else {
        result = self.fileLocationManager.metadata;
    }
    return [NSArray arrayWithArray:result];
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
            metatdata = [[MADMetaData alloc] initWithURL:item];
            break;
        
        default:
            metatdata = nil;    //  This will crash...
            break;

    }
    return metatdata;
}

#pragma mark File Name

+ (NSString *)filenameId:(NSUInteger)tag {
    return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

@end
