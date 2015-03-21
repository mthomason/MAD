//
//  CloudManager.h
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MACloudManager_h
#define MAD_MACloudManager_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MACloudManagerSection) {
    MACloudManagerSectionLocal = 0,
    MACloudManagerSectionCloud = 1,
};

extern NSString * const MTDocumentExtentionMobleApplicationDocument;
extern NSString * const MTDocumentExtentionMobleApplicationDocumentArchive;

extern NSString * const MADNotificationFileManagerDidUpdateFileLocations;
extern NSString * const MADNotificationCloudStateUpdated;

extern NSString * const MADNotificationUbiquitousContainerFetchingWillBegin;
extern NSString * const MADNotificationUbiquitousContainerFetchingDidEnd;

extern NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyInserted;
extern NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyUpdated;
extern NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyRemoved;

@protocol MADCloudManagerProtocol <NSObject>

- (void)ubiquityIdentityDidChange;

@end

@class MADFileLocationManager, MADMetaData;

@interface MACloudManager : NSObject

@property (nonatomic, weak) id <MADCloudManagerProtocol> delegate;

@property (nonatomic, strong, readonly) NSURL *localTemporaryDirectory;
@property (nonatomic, strong, readonly) NSURL *localCachesDirectory;
@property (nonatomic, strong, readonly) NSURL *localApplicationSupportDirectory;

@property (nonatomic, strong, readonly) NSURL *localDataDirectory;
@property (nonatomic, strong, readonly) NSURL *localDocumentDirectory;

@property (nonatomic, strong, readonly) NSURL *ubiquitousDocumentsDirectory;
@property (nonatomic, strong, readonly) NSURL *ubiquityContainer;

@property (nonatomic, assign, readonly) BOOL cloudAvailble;

@property (nonatomic, strong) NSString *searchString;

@property (nonatomic, strong, readonly) MADFileLocationManager *fileLocationManager;

@property (nonatomic, strong, readonly) NSMutableArray       *documentCacheCloudMetaDataItems;
@property (nonatomic, strong, readonly) NSMutableArray       *documentCacheLocalUrls;


+ (MACloudManager *)sharedManager;

- (void)activate;

// Notification hooks

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification;

// File operations

- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;

- (void)moveDocument: (NSURL *)source
          toLocation: (NSURL *)destination
          completion: (void (^)(BOOL, NSError *))completion;

- (BOOL)duplicateUrl:(NSURL *)urlToDupe;
- (BOOL)deleteDocument:(NSURL *)fileUrl;

- (BOOL)duplicateUrl: (NSURL *)urlToDupe
          completion: (void (^)(BOOL, NSURL *, NSError *))completion;

- (void)deleteDocument: (NSURL *)fileUrl
            completion: (void (^)(BOOL, NSError *))completion;

- (BOOL)copyUrl: (NSURL *)urlToCopy
          toUrl: (NSURL *)uniqueUrl
     completion: (void (^)(BOOL, NSURL *, NSError *))completion;

- (NSURL *)uniqueUrlForDocumentWithName: (NSString *)name
                          withExtension: (NSString *)extension
                            inContainer: (MACloudManagerSection)container;

// File name helpers

+ (NSString *)filenameId:(NSUInteger)tag;
+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention;

// Managing the cache
- (void)reloadDocumentCacheWithSearchString:(NSString *)searchString;
- (NSUInteger)numberOfDocuments:(MACloudManagerSection)section;
- (MADMetaData *)metadataForItemAtLocation:(NSUInteger)location
                                 inSection:(MACloudManagerSection)section;

- (void)reloadCacheCloud:(NSString *)searchString;
- (void)reloadCacheLocal:(NSString *)searchString;

@end

#endif
