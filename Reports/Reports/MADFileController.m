//
//  MADFileController.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileController.h"
#import "MADMetaData.h"
#import "MADMetadataQueryManager.h"
#import "NSFileManager+Common.h"

@interface MADFileController()

@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSString *ubiquityToken;
@property (nonatomic, strong) NSString *fileExtention;

@property (nonatomic, strong) MADMetadataQueryManager *fileLocationManager;
@property (nonatomic, strong, readwrite) NSURL *localHomeDirectory;
@property (nonatomic, strong, readwrite) NSURL *localCachesDirectory;
@property (nonatomic, strong, readwrite) NSURL *localDocumentDirectory;
@property (nonatomic, strong, readwrite) NSURL *ubiquityContainer;
@property (nonatomic, strong, readwrite) NSURL *ubiquityDocuments;

@property (nonatomic, assign, readwrite) BOOL cloudAvailble;

@property (nonatomic, strong, readwrite) NSMutableArray       *documentCacheCloudMetaDataItems;
@property (nonatomic, strong, readwrite) NSMutableArray       *documentCacheLocalUrls;

@property (nonatomic, strong) NSArray       *documentCacheLocalIndexesSorted;
@property (nonatomic, strong) NSArray       *documentCacheCloudIndexesSorted;

@end

@implementation MADFileController

static MADFileController *sharedSingleton;

- (id)debugQuickLookObject {
    static NSString *format = @"%@:\t%@\n";

    NSMutableString *debuggingString = [NSMutableString new];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(cloudAvailble)), self.cloudAvailble ? @"YES" : @"NO"];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(ubiquityDocuments)), self.ubiquityDocuments.path];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(ubiquityContainer)), self.ubiquityContainer.path];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(localDocumentDirectory)), self.localDocumentDirectory.path];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(localHomeDirectory)), self.localHomeDirectory.path];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(localCachesDirectory)), self.localCachesDirectory.path];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(ubiquityToken)), self.ubiquityToken];
    
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(documentCacheCloudMetaDataItems)), self.documentCacheCloudMetaDataItems];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(documentCacheLocalUrls)), self.documentCacheLocalUrls];
    
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(documentCacheLocalIndexesSorted)), self.documentCacheLocalIndexesSorted];
    [debuggingString appendFormat:format, NSStringFromSelector(@selector(documentCacheCloudIndexesSorted)), self.documentCacheCloudIndexesSorted];
    
    return debuggingString;
}

+ (void)initialize {
    if (self == [MADFileController self]) {
        MADFileController *manager = [[MADFileController alloc] init];
        sharedSingleton = manager;
    }
}

+ (MADFileController *)sharedManager {
    return sharedSingleton;
}

- (id)init {
    if (self = [super init]) {
        
        self.searchQuery = @"";

    }
    return self;
}

- (void)activateWithGroupID:(NSString *)groupId
              ubiquityToken:(NSString *)ubiquityToken
              fileExtention:(NSString *)fileExtention {
    
    NSString *token = [NSString stringWithString:ubiquityToken];
    self.ubiquityToken = token;
    
    NSString *gid = [NSString stringWithString:groupId];
    self.groupId = gid;
    
    NSString *fileExt = [NSString stringWithString:fileExtention];
    self.fileExtention = fileExt;
    
    NSString *homeDirectory = NSHomeDirectory();
    NSURL *homeDirectoryUrl = [NSURL fileURLWithPath: homeDirectory
                                         isDirectory: YES];
    self.localHomeDirectory = homeDirectoryUrl;
    
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSURL *cacheUrl = [NSURL fileURLWithPath: cachePaths.firstObject
                                 isDirectory: YES];
    self.localCachesDirectory = cacheUrl;
    
    NSURL *documentDirectory = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:groupId];
    self.localDocumentDirectory = documentDirectory;
    
    self.groupId = groupId;
    
    if (self.fileLocationManager == nil) {
    
        MADMetadataQueryManager *fileLocationManager = [[MADMetadataQueryManager alloc] initWithPathExtension: self.fileExtention];
        self.fileLocationManager = fileLocationManager;
        
        self.fileLocationManager.delegate = self;
    }
    
    [self reloadCacheLocal];
    
    if (self.cloudAvailble) {
        
        [self reloadCacheCloud: self.searchQuery];
        
        [self updateFileStorageContainerURL:^(void) {
            
            [self.fileLocationManager.metadataQuery startQuery];
            
        }];
        
    }
    
    if (self.fileControllerDelegate) {
        [self.fileControllerDelegate didUpdateFileLocations];
    }
    
    //[[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationFileManagerDidUpdateFileLocations
    //                                                    object: nil];

    
}

- (void)updateFileStorageContainerURL:(void (^)(void))completion {
    
    @synchronized (self) {
        
        if (self.cloudAvailble) {
            
            //[[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationUbiquitousContainerFetchingWillBegin
             //                                                   object: nil];
            
            if (self.fileControllerDelegate != nil) {
                [self.fileControllerDelegate cloudLookupBegan];
            }
            
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                //This call may be SLOW, so only do on BACKGROUND thread.
                
                NSURL *url = [fileManager URLForUbiquityContainerIdentifier: self.ubiquityToken];
                self.ubiquityContainer = url;
                
                NSURL *documentDirectory = [url URLByAppendingPathComponent:@"Documents"];
                [NSFileManager coordinateCreateDirectoryIfDoesNotExist: documentDirectory];
                self.ubiquityDocuments = documentDirectory;
                
                dispatch_sync(dispatch_get_main_queue(), ^{
              
//                    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationUbiquitousContainerFetchingDidEnd
  //                                                                      object: nil];
                    
                    if (self.fileControllerDelegate != nil) {
                        [self.fileControllerDelegate cloudLookupEnded];
                    }
                    
                    if (completion) completion();
                    
                });
            });
        } else {
            self.ubiquityDocuments = nil;
            if (completion) completion();
        }
    }
}

#pragma mark - Internal

- (void)reloadCacheLocal {
    
    // Setup local cache
    NSArray *documentCacheLocalUrls = [[NSFileManager defaultManager] contentsOfDirectory:self.localDocumentDirectory
                                                                        withPathExtension:self.fileExtention];
    
    NSArray *filteredDocumentCacheLocalUrls;
    
    if (self.searchQuery.length > 0) {
        
        __weak MADFileController *weakself = self;
        NSPredicate *predicateUrlSearch = [NSPredicate predicateWithBlock:^BOOL(NSURL *url, NSDictionary *bindings) {
            
            return [url.lastPathComponent compare: weakself.searchQuery
                                          options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                            range: NSMakeRange(0, MIN(weakself.searchQuery.length, url.lastPathComponent.length))] == NSOrderedSame;
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

- (void)reloadCacheCloud:(NSString *)searchString {
    
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
    self.documentCacheCloudMetaDataItems.array = [NSArray arrayWithArray:result];
    
}

#pragma mark - Actions

- (void)duplicateItems:(NSArray *)items {   // Array of index paths.
    
}

- (void)deleteItems:(NSArray *)items {      // Array of index paths.
    
}

#pragma mark - Convence functions

- (NSUInteger)numberOfSections {
    return 2;
}

- (NSUInteger)numberOfObjectsInSection:(NSUInteger)section {
    
    switch (section) {
            
        case MADFileManagerSectionLocal:
            return self.documentCacheLocalIndexesSorted.count;
            break;
            
        case MADFileManagerSectionCloud:
            return self.documentCacheCloudIndexesSorted.count;
            break;
            
        default:
            return 0;
            break;
    }
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumber *index;
    switch (indexPath.section) {
            
        case MADFileManagerSectionLocal:
            index = self.documentCacheLocalIndexesSorted[indexPath.item];
            return self.documentCacheLocalUrls[index.integerValue];
            break;
            
        case MADFileManagerSectionCloud:
            index = self.documentCacheCloudIndexesSorted[indexPath.item];
            return self.documentCacheCloudMetaDataItems[index.integerValue];
            break;
            
        default:
            return nil;
            break;
    }
}

@end
