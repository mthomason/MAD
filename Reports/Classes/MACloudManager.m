//
//  CloudManager.m
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MACloudManager.h"
#import "MTApplicationInstance.h"
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "MADFileLocationManager.h"
#import "Constants.h"

NSString * const MTICloudUbiquityToken          = @"com.everydayapps.mad.icloud.ubiquityIdentityToken";
NSString * const MTICloudUserEnabled            = @"com.everydayapps.mad.icloud.userenabled";
NSString * const MTICloudUserPrefsSet           = @"com.everydayapps.mad.icloud.userprefsset";


NSString * const MADPreferencesCloudDesired                         = @"com.everydayapps.mad_designer.cloud.desired";
NSString * const MADPreferencesCloudOptionsSelected                 = @"com.everydayapps.mad_designer.cloud.options.selected";
NSString * const ICloudStateUpdatedNotification                     = @"ICloudStateUpdatedNotification";
NSString * const UbiquitousContainerFetchingWillBeginNotification   = @"UbiquitousContainerFetchingWillBeginNotification";
NSString * const UbiquitousContainerFetchingDidEndNotification      = @"UbiquitousContainerFetchingDidEndNotification";

NSString * const MADDesignerUbiquityIdentifier                      = @"iCloud.com.everydayapps.mad.designer";
NSString * const MADViewerUbiquityIdentifier                        = @"iCloud.com.everydayapps.mad.viewer";

@interface MACloudManager ()

@property (nonatomic, strong, readwrite) NSURL *ubiquityContainer;
@property (nonatomic, strong, readwrite) NSURL *dataDirectoryURL;
@property (nonatomic, strong, readwrite) NSURL *documentsDirectoryURL;

@property (nonatomic, strong, readwrite) NSURL *localDocumentDirectory;
@property (nonatomic, strong, readwrite) NSURL *localHomeDirectory;

@property (nonatomic, strong, readwrite) NSURL *localTemporaryDirectory;
@property (nonatomic, strong, readwrite) NSURL *cachesDirectory;
@property (nonatomic, strong, readwrite) NSURL *applicationSupport;

@property (nonatomic, strong, readwrite) NSString *ubiquityIdentifier;

@property (nonatomic, strong, readwrite) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

@property (nonatomic, strong) MADFileLocationManager *fileLocationManager;

@end

@implementation MACloudManager

static MACloudManager *sharedSingleton;

+ (void)initialize {
    if (self == [MACloudManager self]) {
        MACloudManager *cm = [[MACloudManager alloc] init];
        sharedSingleton = cm;
    }
}

+ (void)load { }

- (id)init {
    if (self = [super init]) {
        NSString *ubiquityIdentifier = [MTApplicationInstance isMadDesigner] ?
        MADDesignerUbiquityIdentifier : MADViewerUbiquityIdentifier;
        sharedSingleton.ubiquityIdentifier = ubiquityIdentifier;
        
        NSString *homeDirectory = NSHomeDirectory();
        NSString *pathTemporaryDirectory = NSTemporaryDirectory();
        
        NSURL *homeDirectoryUrl = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
        
        NSURL *urlTemporaryDirectory = [NSURL fileURLWithPath:pathTemporaryDirectory isDirectory:YES];
        
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSURL *cacheUrl = [NSURL fileURLWithPath:cachePaths.firstObject isDirectory:YES];
        
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSURL *docsUrl = [NSURL fileURLWithPath:docPaths.firstObject isDirectory:YES];
        
        MADFileLocationManager *fileManager = [[MADFileLocationManager alloc] initWithPathExtension:@"mad"];
        self.fileLocationManager = fileManager;
        self.localHomeDirectory = homeDirectoryUrl;
        self.localTemporaryDirectory = urlTemporaryDirectory;
        self.cachesDirectory = cacheUrl;
        self.localDocumentDirectory = docsUrl;
        
    }
    return self;
}

- (void)activate {
    [self updateFileStorageContainerURL:nil];
    [self.fileLocationManager startQuery];
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

- (void)setIsCloudEnabled:(BOOL)isCloudEnabled {
    
    // Asynchronously update our data directory URL and documents directory URL
    // If we're enabling cloud storage, we move any local documents into the cloud container after the URLs are updated.
    
    if (isCloudEnabled != _isCloudEnabled) {    //if changed
        _isCloudEnabled = isCloudEnabled;
        NSURL *oldDocumentsDirectoryURL = self.documentsDirectoryURL != nil ? self.documentsDirectoryURL : self.localDocumentDirectory;
        NSURL *oldDataDirectoryURL = self.dataDirectoryURL != nil ? self.dataDirectoryURL : self.localTemporaryDirectory;
        
        __weak MACloudManager *weakself = self;
        [self updateFileStorageContainerURL:^(void) {
            if (isCloudEnabled) {
                
                //Migrate files...
                
                NSDirectoryEnumerationOptions enumerationOptions = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                NSDirectoryEnumerationSkipsPackageDescendants |
                NSDirectoryEnumerationSkipsHiddenFiles;
                
                NSError *readDocumentsError = nil;
                NSFileManager *defaultFileManager = [NSFileManager defaultManager];
                NSArray *localDocuments = [defaultFileManager contentsOfDirectoryAtURL: oldDocumentsDirectoryURL
                                                            includingPropertiesForKeys: nil
                                                                               options: enumerationOptions
                                                                                 error: &readDocumentsError];
                NSError *readPreviewsError = nil;
                NSArray *localPreviews = [defaultFileManager contentsOfDirectoryAtURL: oldDataDirectoryURL
                                                           includingPropertiesForKeys: nil
                                                                              options: enumerationOptions
                                                                                error: &readPreviewsError];
                
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    
                    NSFileManager* fileManager = [NSFileManager defaultManager];
                    NSURL *newDataDirectoryURL = weakself.dataDirectoryURL;
                    NSURL *newDocumentsDirectoryURL = weakself.documentsDirectoryURL;
                    
                    for (NSURL *documentURL in localDocuments) {
                        if ([documentURL.pathExtension isEqualToString: MTDocumentExtentionMobleApplicationDocumentArchive]) {
                            NSURL *destinationURL = [newDocumentsDirectoryURL URLByAppendingPathComponent:documentURL.lastPathComponent];
                            [fileManager setUbiquitous: YES
                                             itemAtURL: documentURL
                                        destinationURL: destinationURL
                                                 error: nil];
                        }
                    }
                    
                    for (NSURL *previewURL in localPreviews) {
                        if ([previewURL.pathExtension isEqualToString: @"preview"]) {
                            NSURL* destinationURL = [newDataDirectoryURL URLByAppendingPathComponent:previewURL.lastPathComponent];
                            [fileManager setUbiquitous: YES
                                             itemAtURL: previewURL
                                        destinationURL: destinationURL
                                                 error: nil];
                        }
                    }
                    
                });
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName: ICloudStateUpdatedNotification
                                                            object: nil];
    }
}

- (void)updateFileStorageContainerURL:(void (^)(void))completionHandler {
    
    @synchronized (self) {
        
        self.dataDirectoryURL = nil;
        if (self.isCloudEnabled) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName: UbiquitousContainerFetchingWillBeginNotification
                                                                object: nil];
            
            __weak MACloudManager *weakself = self;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                
                NSURL *url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier: weakself.ubiquityIdentifier];   //This call may be SLOW, so only do on BACKGROUND thread.
                [weakself setDataAndDocumentUrlsWithBaseUrl:url];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName: UbiquitousContainerFetchingDidEndNotification
                                                                        object: nil];
                    
                    if (completionHandler) {
                        completionHandler();
                    }
                    
                });
            });
        } else {
            [self setDataAndDocumentUrlsWithBaseUrl:self.localHomeDirectory];
        }
    }
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

- (NSURL *)cachedDirectoryForFileUrl:(NSURL *)fileUrl {
    NSString *handle = [fileUrl filenameMinusExtention];
    NSString *fileNameId = [NSFileManager filenameId:[handle hash]];
    return [self cacheDirectoryNamed:fileNameId];
}

- (NSURL *)cacheDirectoryNamed:(NSString *)handle {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *cachedArrayDirectories = [self.cachesDirectory URLByAppendingPathComponent:handle isDirectory:YES];
    BOOL exist, isDirectory;
    exist = [fileManager fileExistsAtPath:[cachedArrayDirectories path] isDirectory:&isDirectory];
    if (exist == NO || isDirectory == NO) {
        NSError *error = nil;
        [fileManager createDirectoryAtURL: cachedArrayDirectories
              withIntermediateDirectories: YES
                               attributes: @{}
                                    error: &error];
        if (error) {
            error = nil;
            [fileManager createDirectoryAtURL: cachedArrayDirectories
                  withIntermediateDirectories: YES
                                   attributes: @{}
                                        error: &error];
        }
        NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
    }
    return cachedArrayDirectories;
}


- (void)createDirectoryIfDoesNotExist:(NSURL *)url {
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    if ([defaultFileManager fileExistsAtPath:url.path] == NO) {
        NSError *error = nil;
        [defaultFileManager createDirectoryAtPath: url.path
                      withIntermediateDirectories: YES
                                       attributes: nil
                                            error: &error];
    }
}

- (void)updateICloudEnabled:(NSNotification *)notification {
    
    if ([[NSFileManager defaultManager] ubiquityIdentityToken]) {
        if (self.isCloudEnabled) {
            [[NSNotificationCenter defaultCenter] postNotificationName: ICloudStateUpdatedNotification
                                                                object: nil];
        }
    }
    else {
        [self setIsCloudEnabled: NO];
    }
}

- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension {
    
    NSMutableSet *result = [[NSMutableSet alloc] init];
    if (self.isCloudEnabled) {
        [result addObjectsFromArray:self.fileLocationManager.documents];
    } else {
        NSError *error = nil;
        NSFileManager *fm = [NSFileManager defaultManager];
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

@end
