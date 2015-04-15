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


extern NSString * const MADNotificationFileManagerDidUpdateFileLocations;
extern NSString * const MADNotificationCloudStateUpdated;

extern NSString * const MADNotificationUbiquitousContainerFetchingWillBegin;
extern NSString * const MADNotificationUbiquitousContainerFetchingDidEnd;

extern NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyInserted;
extern NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyUpdated;
extern NSString * const MADNotificationFileManagerDidUpdateFileLocationsKeyRemoved;

@protocol MADCloudManagerProtocolAppDetails <NSObject>
- (NSString *)ubiquityIdentifier;
@end

@protocol MADCloudManagerProtocolCallbacks <NSObject>

- (void)ubiquityIdentityDidChange;

@end

@class MADMetadataQueryManager, MADMetaData;

@interface MACloudManager : NSObject

@property (nonatomic, strong) NSString *fileExtention;

@property (nonatomic, weak) id <MADCloudManagerProtocolCallbacks> delegate;
@property (nonatomic, weak) id <MADCloudManagerProtocolAppDetails> delegateApplication;

@property (nonatomic, strong, readonly) NSURL *localCachesDirectory;

@property (nonatomic, strong, readonly) NSURL *localDocumentDirectory;

@property (nonatomic, strong, readonly) NSURL *ubiquitousDocumentsDirectory;
@property (nonatomic, strong, readonly) NSURL *ubiquityContainer;

@property (nonatomic, assign, readonly) BOOL cloudAvailble;

@property (nonatomic, strong) NSString *searchString;

@property (nonatomic, strong, readonly) MADMetadataQueryManager *fileLocationManager;

@property (nonatomic, strong, readonly) NSMutableArray       *documentCacheCloudMetaDataItems;
@property (nonatomic, strong, readonly) NSMutableArray       *documentCacheLocalUrls;

@property (nonatomic, strong, readonly) NSString *groupId;

+ (MACloudManager *)sharedManager;

- (void)activateWithGroupID:(NSString *)groupId;

// Notification hooks

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification;

// File operations

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

// Managing the cache
- (void)reloadDocumentCacheWithSearchString:(NSString *)searchString;
- (MADMetaData *)metadataForItemAtLocation:(NSUInteger)location
                                 inSection:(MACloudManagerSection)section;

- (void)reloadCacheCloud:(NSString *)searchString;
- (void)reloadCacheLocal:(NSString *)searchString;

@end

#endif
